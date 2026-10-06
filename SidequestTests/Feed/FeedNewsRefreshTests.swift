import Foundation
import XCTest

@testable import Sidequest

@MainActor
final class FeedNewsRefreshTests: XCTestCase {
  func testRefreshPreservesActiveOwnerAttemptGameValuesAndSelection() async throws {
    let old = try story("old")
    let fresh = try story("fresh")
    let composition = try FeedComposition(
      news: [old], chessPuzzles: await ChessPuzzleLoader.bundled(), shuffle: { $0 })
    let feed = try XCTUnwrap(composition.controller)
    feed.setSceneActive(true)
    feed.next()
    let gameID = try XCTUnwrap(feed.selectedCard).id
    guard case .sudoku(let sudoku)? = composition.games[gameID] else {
      return XCTFail("Expected real Sudoku owner")
    }
    sudoku.runtime.start()
    let editable = try XCTUnwrap(sudoku.puzzle.givens.firstIndex(of: 0))
    sudoku.selectCell(editable)
    sudoku.enter(sudoku.puzzle.solution[editable])
    let board = sudoku.board
    let phase = sudoku.runtime.phase
    let visibility = sudoku.runtime.visibilityIdentity
    let before = feed.cards
    let owners = feed.runtimes
    var windows = 0
    feed.windowDidChange = { _ in
      windows += 1
      return .success(owners)
    }
    XCTAssertTrue(composition.refreshNews([fresh]))
    XCTAssertEqual(feed.selectedIndex, 1)
    XCTAssertEqual(feed.cards.map(\.id), before.map(\.id))
    XCTAssertEqual(Array(feed.cards.dropFirst()), Array(before.dropFirst()))
    XCTAssertEqual(feed.cards.first, .news(FeedNewsCard(snapshot: fresh, id: old.id)))
    XCTAssertTrue(feed.runtimes[gameID] === sudoku.runtime)
    XCTAssertEqual(sudoku.runtime.phase, phase)
    XCTAssertEqual(sudoku.runtime.visibilityIdentity, visibility)
    XCTAssertEqual(sudoku.board, board)
    XCTAssertEqual(windows, 0)
    XCTAssertFalse(composition.refreshNews([]))
    XCTAssertEqual(sudoku.runtime.phase, phase)
    feed.retire()
    let retired = feed.cards
    XCTAssertFalse(composition.refreshNews([old]))
    XCTAssertEqual(feed.cards, retired)
  }

  func testNewsSelectionAndAppearanceOrderSurviveShorterReplacementPool() throws {
    let old = try [story("old-a"), story("old-b"), story("old-c")]
    let fresh = try [story("new-a"), story("new-b")]
    let cards = old.map(FeedCard.news)
    let feed = FeedController(cards: cards, runtimes: [:])
    feed.setSceneActive(true)
    feed.next()
    XCTAssertTrue(feed.refreshNews(fresh))
    XCTAssertEqual(feed.selectedIndex, 1)
    XCTAssertEqual(feed.cards.map(\.id), cards.map(\.id))
    XCTAssertEqual(
      feed.cards,
      [
        .news(FeedNewsCard(snapshot: fresh[0], id: old[0].id)),
        .news(FeedNewsCard(snapshot: fresh[1], id: old[1].id)),
        .news(FeedNewsCard(snapshot: fresh[0], id: old[2].id)),
      ])
    feed.retire()
  }

  func testCadenceRetainsPartialGameCountAndAppearanceOrdinal() throws {
    let sessionID = UUID()
    let old = try [story("old-a"), story("old-b")]
    let fresh = try story("fresh")
    let games = try (0..<8).map { GameCard(id: try CardID("game-\($0)"), kind: .memory) }
    var cadence = try FeedNewsCadence(pool: old, sessionID: sessionID).preparing(games).next
    XCTAssertEqual(cadence.gameCount, 3)
    XCTAssertEqual(cadence.newsCursor, 1)
    cadence.refreshNews([fresh])
    XCTAssertEqual(cadence.gameCount, 3)
    XCTAssertEqual(cadence.appearanceOrdinal, 1)
    XCTAssertEqual(cadence.newsCursor, 0)
    let nextGames = try (8..<10).map { GameCard(id: try CardID("game-\($0)"), kind: .memory) }
    let prepared = try cadence.preparing(nextGames)
    XCTAssertEqual(
      prepared.cards.last,
      .news(
        FeedNewsCard(
          snapshot: fresh, id: try CardID("news-\(sessionID.uuidString.lowercased())-1"))))
    XCTAssertEqual(prepared.next.appearanceOrdinal, 2)
    let unchanged = cadence
    cadence.refreshNews([])
    XCTAssertEqual(cadence, unchanged)
  }

  func testCompletedArchiveSurvivesRefreshAfterGameOwnerEviction() async throws {
    let composition = try await FeedComposition.endless(
      news: [story("old")], chessPuzzles: ChessPuzzleLoader.bundled(), seed: 104, ordered: true)
    let feed = try XCTUnwrap(composition.controller)
    feed.setSceneActive(true)
    let id = try XCTUnwrap(feed.selectedCard).id
    guard case .sudoku(let sudoku)? = composition.games[id] else {
      return XCTFail("Expected Sudoku")
    }
    sudoku.runtime.start()
    for index in sudoku.puzzle.givens.indices where sudoku.puzzle.givens[index] == 0 {
      sudoku.selectCell(index)
      sudoku.enter(sudoku.puzzle.solution[index])
    }
    let phase = sudoku.runtime.phase
    guard case .completed = phase else { return XCTFail("Expected completed game") }
    for _ in 0..<3 { feed.next() }
    XCTAssertNil(composition.games[id])
    let descriptors = composition.generatedDescriptors.mapValues(\.card)
    let cardIDs = feed.cards.map(\.id)
    XCTAssertTrue(composition.refreshNews([story("new")]))
    XCTAssertEqual(feed.cards.map(\.id), cardIDs)
    XCTAssertEqual(composition.generatedDescriptors.mapValues(\.card), descriptors)
    for _ in 0..<3 { feed.previous() }
    guard case .sudoku(let restored)? = composition.games[id] else {
      return XCTFail("Expected reconstructed Sudoku")
    }
    XCTAssertEqual(restored.runtime.phase, phase)
    XCTAssertTrue(restored.board?.isComplete ?? false)
    feed.retire()
  }

  func testSuspendedReplenishmentUsesLatestPoolWithoutReusingAppearanceIDs() async throws {
    let gate = NewsRefreshBatchGate()
    let composition = try await FeedComposition.endless(
      news: [story("old")], chessPuzzles: ChessPuzzleLoader.bundled(), seed: 104, ordered: true,
      prepareBatch: { id, sequence, seed, puzzles, ordered in
        if sequence > 0 { await gate.pause() }
        return try await GeneratedGameBatch.prepare(
          sessionID: id, sequence: sequence, seed: seed, chessPuzzles: puzzles, ordered: ordered)
      })
    let feed = try XCTUnwrap(composition.controller)
    feed.setSceneActive(true)
    for _ in 0..<4 { feed.next() }
    await gate.waitUntilPaused()
    let originalCount = feed.count
    let fresh = try story("fresh")
    XCTAssertTrue(composition.refreshNews([fresh]))
    await gate.finish()
    let deadline = ContinuousClock.now + .seconds(5)
    while feed.count == originalCount {
      guard ContinuousClock.now < deadline else {
        feed.retire()
        return XCTFail("Replenishment timed out")
      }
      try await Task.sleep(for: .milliseconds(5))
    }
    XCTAssertEqual(Set(feed.cards.map(\.id)).count, feed.count)
    let stories = feed.cards.compactMap { card -> NewsSnapshot? in
      if case .news(let appearance) = card { return appearance.snapshot }
      return nil
    }
    XCTAssertEqual(stories.count, 3)
    XCTAssertTrue(stories.allSatisfy { $0 == fresh })
    feed.retire()
  }

  private func story(_ name: String) throws -> NewsSnapshot {
    try NewsSnapshot(
      id: CardID(name), headline: "Fictional \(name)", excerpt: "Offline fixture only.",
      publisher: "Sidequest fixture",
      sourceURL: XCTUnwrap(URL(string: "https://example.com/\(name)")),
      capturedAt: Date(timeIntervalSince1970: 1_700_000_000), isSample: true)
  }
}

private actor NewsRefreshBatchGate {
  private var continuation: CheckedContinuation<Void, Never>?
  private var waiter: CheckedContinuation<Void, Never>?
  func pause() async {
    await withCheckedContinuation {
      continuation = $0
      waiter?.resume()
      waiter = nil
    }
  }
  func waitUntilPaused() async {
    if continuation != nil { return }
    await withCheckedContinuation { waiter = $0 }
  }
  func finish() {
    continuation?.resume()
    continuation = nil
  }
}
