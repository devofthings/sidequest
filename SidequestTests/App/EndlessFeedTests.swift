import Foundation
import SwiftUI
import UIKit
import XCTest

@testable import Sidequest

@MainActor
final class EndlessFeedTests: XCTestCase {
  func testSeededGeneratorsProduceDiverseValidFrozenChallenges() throws {
    var sudoku = Set<[Int]>()
    var memory = Set<[String]>()
    var bubble = Set<String>()
    for seed in 0..<300 {
      var random = ChallengeRandom(seed: UInt64(seed))
      let puzzle = try SudokuGenerator.generate(using: &random)
      XCTAssertEqual(SudokuGrid.solutions(for: puzzle.givens), [puzzle.solution])
      XCTAssertGreaterThan(puzzle.givens.filter { $0 == 0 }.count, 5)
      sudoku.insert(puzzle.givens)
      let board = MemoryRules(using: &random)
      XCTAssertEqual(board.symbols.count, 12)
      for symbol in MemorySymbol.allCases {
        XCTAssertEqual(board.symbols.filter { $0 == symbol }.count, 2)
      }
      memory.insert(board.symbols.map(\.rawValue))
      let challenge = try BubbleChallengeGenerator.generate(using: &random)
      var game = challenge.game
      XCTAssertFalse(game.board.isEmpty)
      XCTAssertLessThanOrEqual(challenge.winningAngles.count, BubbleShooterGame.shotLimit)
      for angle in challenge.winningAngles { _ = try game.fire(angleRadians: angle * .pi / 180) }
      XCTAssertEqual(game.outcome, .won)
      game.reset()
      XCTAssertEqual(game.board, challenge.game.board)
      XCTAssertEqual(game.nextColor, challenge.game.nextColor)
      bubble.insert(
        BubbleGeometry.slots.map { slot in
          "\(slot.row),\(slot.column):\(String(describing: challenge.game.board[slot]))"
        }.joined(separator: ";"))
      var repeatRandom = ChallengeRandom(seed: UInt64(seed))
      XCTAssertEqual(try SudokuGenerator.generate(using: &repeatRandom), puzzle)
      XCTAssertEqual(MemoryRules(using: &repeatRandom), board)
      XCTAssertEqual(try BubbleChallengeGenerator.generate(using: &repeatRandom), challenge)
    }
    XCTAssertGreaterThan(sudoku.count, 100)
    XCTAssertGreaterThan(memory.count, 250)
    XCTAssertGreaterThan(bubble.count, 50)
  }

  func testBoundedBubbleFallbackVariesAndAlwaysReplaysItsWitness() throws {
    var distinct: [BubbleChallenge] = []
    for seed in 0..<64 {
      var random = ChallengeRandom(seed: UInt64(seed))
      let challenge = try BubbleChallengeGenerator.fallback(using: &random)
      var game = challenge.game
      for angle in challenge.winningAngles { _ = try game.fire(angleRadians: angle * .pi / 180) }
      XCTAssertEqual(game.outcome, .won)
      XCTAssertLessThanOrEqual(game.shotsFired, BubbleShooterGame.shotLimit)
      if !distinct.contains(challenge) { distinct.append(challenge) }
    }
    XCTAssertGreaterThan(distinct.count, 10)
    XCTAssertEqual(BubbleChallengeGenerator.attemptLimit, 16)
    XCTAssertEqual(BubbleChallengeGenerator.anglesPerAttempt, 121)
  }

  func testThousandsOfAdvancesKeepStableHistoryAndAtMostThreeAdapters() async throws {
    let composition = try await make()
    let feed = try XCTUnwrap(composition.controller)
    feed.setSceneActive(true)
    let firstBatch = feed.cards
    var lastCount = feed.count
    for index in 0..<2000 {
      if !feed.canGoForward { try await wait { feed.canGoForward } }
      feed.next()
      XCTAssertEqual(feed.selectedIndex, index + 1)
      XCTAssertLessThanOrEqual(composition.cachedAdapterCount, 3)
      XCTAssertLessThanOrEqual(feed.runtimes.count, 3)
      if feed.count != lastCount {
        XCTAssertEqual(Array(feed.cards.prefix(firstBatch.count)), firstBatch)
        XCTAssertEqual(Set(feed.cards.map(\.id)).count, feed.count)
        lastCount = feed.count
      }
      if index.isMultiple(of: 4) { await Task.yield() }
    }
    let allCards = feed.cards
    for _ in 0..<2000 { feed.previous() }
    XCTAssertEqual(feed.selectedIndex, 0)
    XCTAssertEqual(feed.cards, allCards)
    XCTAssertEqual(Array(feed.cards.prefix(8)), firstBatch)
    feed.retire()
  }

  func testFrozenSkipResetAndCompletedRevisitsAfterEvictionForEveryGame() async throws {
    let composition = try await make()
    let feed = try XCTUnwrap(composition.controller)
    feed.setSceneActive(true)
    var completedIDs: [CardID] = []
    var obsolete: [GameRuntime] = []
    for _ in 0..<4 {
      let card = try XCTUnwrap(feed.selectedCard)
      let composed = try XCTUnwrap(composition.games[card.id])
      let runtime = composed.runtime
      runtime.start()
      switch composed {
      case .sudoku(let game):
        let givens = game.puzzle.givens
        if let index = givens.firstIndex(of: 0) {
          game.selectCell(index)
          game.enter(game.puzzle.solution[index])
        }
        feed.next()
        feed.previous()
        XCTAssertEqual(runtime.phase, .preview)
        runtime.start()
        XCTAssertEqual(game.board?.cells, givens)
        for index in givens.indices where givens[index] == 0 {
          game.selectCell(index)
          game.enter(game.puzzle.solution[index])
        }
      case .memory(let game):
        let symbols = try XCTUnwrap(game.rules).symbols
        game.flip(0)
        feed.next()
        feed.previous()
        runtime.start()
        XCTAssertEqual(game.rules?.symbols, symbols)
        for symbol in MemorySymbol.allCases {
          for index in symbols.indices where symbols[index] == symbol { game.flip(index) }
        }
      case .chess(let game):
        let move = try XCTUnwrap(game.puzzle.acceptedMoves.first)
        game.tap(move.origin)
        game.tap(move.destination)
      case .bubbleShooter(let game):
        guard case .bubble(let challenge)? = composition.generatedDescriptors[card.id]?.challenge
        else {
          return XCTFail("Missing frozen Bubble configuration")
        }
        for angle in challenge.winningAngles {
          game.aim(degrees: angle)
          XCTAssertTrue(game.fire())
          try await wait { game.flight == nil }
        }
        XCTAssertEqual(game.game.outcome, .won)
      #if DEBUG
        case .placeholder: return XCTFail("No demos in endless composition")
      #endif
      }
      guard case .completed = runtime.phase else { return XCTFail("Expected completion") }
      completedIDs.append(card.id)
      obsolete.append(runtime)
      feed.next()
    }
    for _ in 0..<12 {
      if !feed.canGoForward { try await wait { feed.canGoForward } }
      feed.next()
    }
    XCTAssertTrue(completedIDs.allSatisfy { composition.games[$0] == nil })
    for _ in 0..<16 { feed.previous() }
    for id in completedIDs {
      XCTAssertEqual(feed.selectedCard?.id, id)
      let restored = try XCTUnwrap(composition.games[id])
      guard case .completed = restored.runtime.phase else {
        return XCTFail("Completion lost after eviction")
      }
      switch restored {
      case .sudoku(let game):
        XCTAssertTrue(game.board?.isComplete ?? false)
        XCTAssertNotNil(game.selectedCell)
      case .memory(let game): XCTAssertTrue(game.rules?.isCompleted ?? false)
      case .chess(let game): XCTAssertTrue(game.attempt?.isSolved ?? false)
      case .bubbleShooter(let game):
        XCTAssertEqual(game.game.outcome, .won)
        XCTAssertEqual(game.feedback, "Board cleared!")
      #if DEBUG
        case .placeholder: XCTFail("No placeholder")
      #endif
      }
      feed.next()
    }
    for runtime in obsolete {
      runtime.setVisible(true)
      XCTAssertFalse(runtime.isVisible)
      XCTAssertFalse(runtime.replay())
    }
    feed.retire()
  }

  func testRetiredEvictedControllerIsReleasedAndCannotReactivate() async throws {
    let composition = try await make()
    let feed = try XCTUnwrap(composition.controller)
    feed.setSceneActive(true)
    weak var old: SudokuController?
    var runtime: GameRuntime?
    if case .sudoku(let game)? = composition.games[try XCTUnwrap(feed.selectedCard).id] {
      old = game
      runtime = game.runtime
    }
    XCTAssertNotNil(old)
    runtime?.start()
    feed.next()
    feed.next()
    feed.next()
    XCTAssertNil(old)
    runtime?.setVisible(true)
    runtime?.start()
    XCTAssertEqual(runtime?.phase, .preview)
    XCTAssertFalse(runtime?.isVisible ?? true)
    feed.retire()
  }

  func testExactCollisionRejectedButNewsPrefixesAreNotReserved() async throws {
    let puzzles = try await ChessPuzzleLoader.bundled()
    let id = UUID(uuidString: "00000000-0000-0000-0000-000000000104") ?? UUID()
    let story = try snapshot("game-\(id.uuidString.lowercased())-0")
    do {
      _ = try await FeedComposition.endless(news: [story], chessPuzzles: puzzles, sessionID: id)
      XCTFail("Exact collision must reject")
    } catch DeckConstructionError.duplicateCardID(let duplicate) {
      XCTAssertEqual(duplicate, story.id)
    }
    let permitted = try snapshot("sample-game-memory")
    let composition = try await FeedComposition.endless(
      news: [permitted], chessPuzzles: puzzles, ordered: true)
    let feed = try XCTUnwrap(composition.controller)
    feed.setSceneActive(true)
    for _ in 0..<25 {
      if !feed.canGoForward { try await wait { feed.canGoForward } }
      feed.next()
      await Task.yield()
    }
    XCTAssertEqual(feed.cards.filter { $0.id == permitted.id }, [.news(permitted)])
    feed.retire()
  }

  func testFutureNewsCollisionSkipsSequenceWithoutRepeatingOrLosingStory() async throws {
    let id = UUID(uuidString: "00000000-0000-0000-0000-000000000104") ?? UUID()
    let story = try snapshot("game-\(id.uuidString.lowercased())-8")
    let puzzles = try await ChessPuzzleLoader.bundled()
    let composition = try await FeedComposition.endless(
      news: [story], chessPuzzles: puzzles,
      sessionID: id, seed: 104, ordered: true)
    let feed = try XCTUnwrap(composition.controller)
    feed.setSceneActive(true)
    for _ in 0..<30 {
      if !feed.canGoForward { try await wait { feed.canGoForward } }
      feed.next()
    }
    XCTAssertEqual(feed.cards.filter { $0.id == story.id }, [.news(story)])
    XCTAssertEqual(Set(feed.cards.map(\.id)).count, feed.count)
    XCTAssertNil(feed.replenishmentMessage)
    feed.retire()
  }

  func testNativeHostedWindowReleasesEvictedGameAndRefreshesAtUnchangedSelection() async throws {
    let composition = try await make()
    let feed = try XCTUnwrap(composition.controller)
    feed.setSceneActive(true)
    weak var old: SudokuController?
    if case .sudoku(let game)? = composition.games[try XCTUnwrap(feed.selectedCard).id] {
      old = game
      game.runtime.start()
    }
    let content: (FeedCard) -> AnyView = { card in
      if case .game(let game) = card, let runtime = feed.runtimes[game.id] {
        return composition.gameContent(game, runtime: runtime)
      }
      return AnyView(Text("Preview"))
    }
    let pager = FeedPagerController(controller: feed, content: content)
    pager.loadViewIfNeeded()
    pager.view.frame = CGRect(x: 0, y: 0, width: 393, height: 600)
    pager.view.setNeedsLayout()
    pager.view.layoutIfNeeded()
    for _ in 0..<3 {
      feed.next()
      pager.update(content: content, request: nil, reduceMotion: true)
      pager.view.layoutIfNeeded()
    }
    try await wait { old == nil }
    XCTAssertEqual(pager.children.count, 3)
    pager.stop()
    feed.retire()

    let cards = try (0..<3).map { index in
      FeedCard.game(GameCard(id: try CardID("pager-\(index)"), kind: .sudoku))
    }
    let owners = cards.map { _ in PlaceholderGameController(runtime: GameRuntime()) }
    let finite = FeedController(
      cards: Array(cards.prefix(2)),
      runtimes: Dictionary(uniqueKeysWithValues: zip(cards.map(\.id), owners.map(\.runtime))))
    finite.setSceneActive(true)
    finite.next()
    let native = FeedPagerController(controller: finite) { _ in AnyView(Text("Card")) }
    native.loadViewIfNeeded()
    native.view.frame = CGRect(x: 0, y: 0, width: 393, height: 600)
    native.view.setNeedsLayout()
    native.view.layoutIfNeeded()
    XCTAssertEqual(native.children.count, 2)
    finite.append([cards[2]])
    native.update(content: { _ in AnyView(Text("Card")) }, request: nil, reduceMotion: true)
    XCTAssertEqual(finite.selectedIndex, 1)
    XCTAssertEqual(native.children.count, 3)
    let scroll = try XCTUnwrap(native.view.subviews.first as? UIScrollView)
    XCTAssertEqual(scroll.contentSize.height, 1800, accuracy: 0.01)
    XCTAssertEqual(scroll.contentOffset.y, 600, accuracy: 0.01)
    native.stop()
    finite.retire()
  }

  func testCompletedBubbleLossSurvivesEvictionAndReplayKeepsFrozenChallenge() async throws {
    let composition = try await make()
    let feed = try XCTUnwrap(composition.controller)
    feed.setSceneActive(true)
    feed.next()
    feed.next()
    feed.next()
    let id = try XCTUnwrap(feed.selectedCard).id
    guard case .bubbleShooter(let bubble)? = composition.games[id] else {
      return XCTFail("Expected Bubble")
    }
    bubble.runtime.start()
    let initial = bubble.game.board
    // Seed104's -56° path loses after six actual physics/rule commits.
    for _ in 0..<8 where bubble.game.outcome == .playing {
      bubble.aim(degrees: -56)
      XCTAssertTrue(bubble.fire())
      try await wait { bubble.flight == nil }
    }
    guard case .lost = bubble.game.outcome else {
      return XCTFail("The non-winning path should lose")
    }
    let loss = bubble.game.outcome
    for _ in 0..<4 { feed.next() }
    XCTAssertNil(composition.games[id])
    for _ in 0..<4 { feed.previous() }
    guard case .bubbleShooter(let restored)? = composition.games[id] else {
      return XCTFail("Expected restored Bubble")
    }
    XCTAssertEqual(restored.game.outcome, loss)
    XCTAssertEqual(restored.feedback, "Challenge ended. Try again.")
    XCTAssertTrue(restored.replay())
    XCTAssertEqual(restored.game.board, initial)
    XCTAssertEqual(restored.game.shotsFired, 0)
    feed.retire()
  }

  private func make() async throws -> FeedComposition {
    try await FeedComposition.endless(
      news: [], chessPuzzles: ChessPuzzleLoader.bundled(), seed: 104, ordered: true)
  }

  private func wait(_ condition: () -> Bool) async throws {
    let deadline = ContinuousClock.now + .seconds(10)
    while !condition() {
      guard ContinuousClock.now < deadline else {
        XCTFail("Timed out waiting for owned work")
        throw CancellationError()
      }
      try await Task.sleep(for: .milliseconds(5))
    }
  }

  private func snapshot(_ id: String) throws -> NewsSnapshot {
    try NewsSnapshot(
      id: CardID(id), headline: "Original fictional test", excerpt: "Offline only.",
      publisher: "Sidequest fixture",
      sourceURL: XCTUnwrap(URL(string: "https://example.com/endless")),
      capturedAt: Date(timeIntervalSince1970: 1_700_000_000), isSample: true)
  }
}
