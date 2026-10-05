import Foundation
import XCTest

@testable import Sidequest

@MainActor
final class MixedDifficultyTests: XCTestCase {
  func testThreeAppearancesCoverEveryCertifiedTierAndPreserveShuffleIdentity() async throws {
    let historical = try await ChessPuzzleLoader.bundled()
    let catalog = try await ChessPuzzleLoader.bundledCatalog()
    let puzzles = historical + catalog
    let id = UUID()
    for seed: UInt64 in [0, 1, 201] {
      var seen: [GameKind: Set<GameDifficulty>] = [:]
      for sequence in stride(from: 0, to: 24, by: 8) {
        let batch = try await GeneratedGameBatch.prepare(
          sessionID: id, sequence: sequence, seed: seed, chessPuzzles: puzzles,
          ordered: true, mixedDifficulties: true)
        let repeatBatch = try await GeneratedGameBatch.prepare(
          sessionID: id, sequence: sequence, seed: seed, chessPuzzles: puzzles,
          ordered: true, mixedDifficulties: true)
        XCTAssertEqual(batch.descriptors.map(\.card), repeatBatch.descriptors.map(\.card))
        for descriptor in batch.descriptors {
          try PreparedGameReconstruction.validate(descriptor, completed: nil)
          let tier = try XCTUnwrap(descriptor.card.difficulty)
          seen[descriptor.card.kind, default: []].insert(tier)
          let composed = try ComposedGame.generated(descriptor, completed: nil)
          switch composed {
          case .sudoku(let game): XCTAssertEqual(game.challenge?.difficulty, tier)
          case .memory(let game): XCTAssertEqual(game.challenge?.difficulty, tier)
          case .chess(let game): XCTAssertEqual(game.puzzle.challenge?.difficulty, tier)
          case .bubbleShooter(let game): XCTAssertEqual(game.game.difficulty, tier)
          default: XCTFail("A real classified card cannot be a placeholder")
          }
          composed.runtime.retire()
        }
        let shuffledLegacy = try await GeneratedGameBatch.prepare(
          sessionID: id, sequence: sequence, seed: seed, chessPuzzles: puzzles)
        let shuffledMixed = try await GeneratedGameBatch.prepare(
          sessionID: id, sequence: sequence, seed: seed, chessPuzzles: puzzles,
          mixedDifficulties: true)
        XCTAssertEqual(
          shuffledLegacy.descriptors.map { $0.card.id },
          shuffledMixed.descriptors.map { $0.card.id })
      }
      for kind in GameKind.allCases { XCTAssertEqual(seen[kind], [.easy, .medium, .hard]) }
    }
  }

  func testAllGameCompletionsKeepTierAfterEvictionAndBubbleReplay() async throws {
    let historical = try await ChessPuzzleLoader.bundled()
    let catalog = try await ChessPuzzleLoader.bundledCatalog()
    let composition = try await FeedComposition.endless(
      news: DemoNewsLoader.bundled(), chessPuzzles: historical + catalog,
      seed: 201, ordered: true,
      prepareBatch: { id, sequence, seed, puzzles, ordered in
        try await GeneratedGameBatch.prepare(
          sessionID: id, sequence: sequence, seed: seed,
          chessPuzzles: puzzles, ordered: ordered, mixedDifficulties: true)
      })
    let feed = try XCTUnwrap(composition.controller)
    feed.setSceneActive(true)
    var identities: [(CardID, GameDifficulty)] = []
    for _ in 0..<4 {
      let card = try XCTUnwrap(feed.selectedCard)
      let descriptor = try XCTUnwrap(composition.generatedDescriptors[card.id])
      identities.append((card.id, try XCTUnwrap(descriptor.card.difficulty)))
      let composed = try XCTUnwrap(composition.games[card.id])
      switch composed {
      case .sudoku(let game):
        for index in game.puzzle.givens.indices where game.puzzle.givens[index] == 0 {
          game.selectCell(index)
          game.enter(game.puzzle.solution[index])
        }
      case .memory(let game):
        let symbols = game.displayedRules.symbols
        for symbol in Set(symbols) {
          for index in symbols.indices where symbols[index] == symbol { game.flip(index) }
        }
      case .chess(let game):
        let move = try XCTUnwrap(game.puzzle.acceptedMoves.first)
        game.tap(move.origin)
        game.tap(move.destination)
      case .bubbleShooter(let game):
        guard case .bubble(let challenge) = descriptor.challenge else {
          return XCTFail("Missing Bubble")
        }
        for angle in challenge.winningAngles {
          game.aim(degrees: angle)
          XCTAssertTrue(game.fire())
          let deadline = ContinuousClock.now + .seconds(5)
          while game.flight != nil, ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(10))
          }
          XCTAssertNil(game.flight)
        }
      default: return XCTFail("No placeholder")
      }
      guard case .completed = composed.runtime.phase else {
        return XCTFail("Expected actual completion")
      }
      feed.next()
    }
    for _ in 0..<8 {
      let deadline = ContinuousClock.now + .seconds(5)
      while !feed.canGoForward, ContinuousClock.now < deadline {
        try await Task.sleep(for: .milliseconds(10))
      }
      feed.next()
    }
    XCTAssertTrue(identities.allSatisfy { composition.games[$0.0] == nil })
    for _ in 0..<12 { feed.previous() }
    for (id, tier) in identities {
      XCTAssertEqual(feed.selectedCard?.id, id)
      XCTAssertEqual(composition.generatedDescriptors[id]?.card.difficulty, tier)
      let restored = try XCTUnwrap(composition.games[id])
      guard case .completed = restored.runtime.phase else {
        return XCTFail("Archive lost completion")
      }
      if case .bubbleShooter(let bubble) = restored {
        XCTAssertTrue(bubble.replay())
        XCTAssertEqual(bubble.game.difficulty, tier)
        XCTAssertEqual(bubble.game.shotsFired, 0)
        XCTAssertEqual(bubble.game.outcome, .playing)
      }
      feed.next()
    }
    feed.retire()
  }

  func testInvalidDescriptorAndWrongCompletedLayoutAreRejectedWithoutFallback() throws {
    let challenge = MemoryChallenge(difficulty: .easy, seed: 201)
    let id = try CardID("classified-memory")
    let wrongTier = GeneratedGameDescriptor(
      card: GameCard(id: id, kind: .memory, difficulty: .hard),
      challenge: .certifiedMemory(challenge))
    XCTAssertThrowsError(try ComposedGame.generated(wrongTier, completed: nil))
    let valid = GeneratedGameDescriptor(
      card: GameCard(id: id, kind: .memory, difficulty: .easy),
      challenge: .certifiedMemory(challenge))
    let incomplete = CompletedGameState(attempt: GameAttemptID(), result: .memory(challenge.rules))
    XCTAssertThrowsError(try ComposedGame.generated(valid, completed: incomplete))
    var other = MemoryChallenge(difficulty: .medium, seed: 201).rules
    for symbol in Set(other.symbols) {
      let indices = other.symbols.indices.filter { other.symbols[$0] == symbol }
      for index in indices { _ = other.flip(index) }
    }
    let incompatible = CompletedGameState(attempt: GameAttemptID(), result: .memory(other))
    XCTAssertThrowsError(try ComposedGame.generated(valid, completed: incompatible))
    var solved = challenge.rules
    for symbol in Set(solved.symbols) {
      for index in solved.symbols.indices where solved.symbols[index] == symbol {
        _ = solved.flip(index)
      }
    }
    let completed = CompletedGameState(attempt: GameAttemptID(), result: .memory(solved))
    let restored = try ComposedGame.generated(valid, completed: completed)
    guard case .memory(let memory) = restored else { return XCTFail("Expected typed Memory") }
    XCTAssertEqual(memory.challenge, challenge)
    XCTAssertEqual(memory.rules, solved)
    XCTAssertEqual(memory.runtime.phase, .completed(completed.attempt))
    XCTAssertFalse(memory.runtime.isVisible)
    restored.runtime.retire()
  }

  func testRejectedWindowKeepsSelectionOwnersAndAllowsSameNavigationRetry() throws {
    let cards = try (0..<4).map { index in
      FeedCard.game(GameCard(id: CardID("transaction-\(index)"), kind: .memory))
    }
    let first = GameRuntime(activationPolicy: .firstInteraction)
    let feed = FeedController(cards: cards, runtimes: [cards[0].id: first], isEndless: true)
    feed.setSceneActive(true)
    var reject = true
    feed.windowDidChange = { _ in
      reject ? .failure(.preparationFailed) : .success([cards[0].id: first])
    }
    first.start()
    let phase = first.phase
    feed.next()
    XCTAssertEqual(feed.selectedIndex, 0)
    XCTAssertTrue(feed.runtimes[cards[0].id] === first)
    XCTAssertEqual(first.phase, phase)
    XCTAssertTrue(first.isVisible)
    XCTAssertNotNil(feed.replenishmentMessage)
    reject = false
    feed.next()
    XCTAssertEqual(feed.selectedIndex, 1)
    XCTAssertFalse(first.isVisible)
    XCTAssertEqual(first.phase, .preview)
    feed.retire()
  }
}
