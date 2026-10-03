import Foundation
import XCTest

@testable import Sidequest

final class FeedHostTests: XCTestCase {
  func testEmptyAndSingleSelectionHaveBoundedNavigation() throws {
    var empty = FeedSelection(cards: [])
    XCTAssertNil(empty.card)
    XCTAssertFalse(empty.move(by: 1))
    XCTAssertFalse(empty.move(by: -1))
    let card = FeedCard.game(GameCard(id: try CardID("one"), kind: .memory))
    var single = FeedSelection(cards: [card])
    XCTAssertEqual(single.card, card)
    XCTAssertFalse(single.canGoBack)
    XCTAssertFalse(single.canGoForward)
    XCTAssertFalse(single.move(by: 1))
    XCTAssertEqual(single.card, card)
  }

  @MainActor
  func testSelectionResetsOnceBeforeNewCardBecomesEligible() throws {
    let first = RuntimeProbe()
    let second = RuntimeProbe()
    let ids = try [CardID("first"), CardID("second")]
    let feed = FeedController(
      cards: [
        .game(GameCard(id: ids[0], kind: .sudoku)),
        .game(GameCard(id: ids[1], kind: .memory)),
      ], runtimes: [ids[0]: first.runtime, ids[1]: second.runtime])
    feed.setSceneActive(true)
    XCTAssertEqual(first.runtime.phase, .preview)
    second.runtime.start()
    XCTAssertTrue(second.effects.isEmpty)
    first.runtime.start()
    first.runtime.start()
    XCTAssertEqual(first.effects.count, 1)
    guard case .playing(let old) = first.runtime.phase else { return XCTFail("Start failed") }
    first.move(from: old)
    XCTAssertEqual(first.moves, 1)
    feed.next()
    XCTAssertEqual(first.runtime.phase, .preview)
    XCTAssertEqual(first.moves, 0)
    XCTAssertEqual(first.resetCount, 1)
    XCTAssertTrue(first.wasIneligibleDuringReset)
    XCTAssertTrue(second.runtime.isVisible)
    feed.next()
    XCTAssertEqual(first.resetCount, 1)
    feed.previous()
    XCTAssertEqual(first.runtime.phase, .preview)
    first.runtime.start()
    guard case .playing(let current) = first.runtime.phase else { return XCTFail("Restart failed") }
    XCTAssertNotEqual(old, current)
    first.move(from: old)
    first.runtime.complete(attempt: old)
    XCTAssertEqual(first.moves, 0)
    XCTAssertEqual(first.runtime.phase, .playing(current))
  }

  @MainActor
  func testCompletionKeepsRuleStateAcrossRevisits() throws {
    let id = try CardID("completed")
    let other = try CardID("other")
    let completed = RuntimeProbe()
    let second = RuntimeProbe()
    let feed = FeedController(
      cards: [
        .game(GameCard(id: id, kind: .chess)),
        .game(GameCard(id: other, kind: .memory)),
      ], runtimes: [id: completed.runtime, other: second.runtime])
    feed.setSceneActive(true)
    completed.runtime.start()
    guard case .playing(let attempt) = completed.runtime.phase else {
      return XCTFail("Start failed")
    }
    completed.move(from: attempt)
    completed.runtime.complete(attempt: attempt)
    XCTAssertEqual(completed.stops, 1)
    feed.next()
    feed.previous()
    completed.runtime.start()
    XCTAssertEqual(completed.runtime.phase, .completed(attempt))
    XCTAssertEqual(completed.moves, 1)
    XCTAssertEqual(completed.resetCount, 0)
    XCTAssertEqual(completed.stops, 1)
    XCTAssertFalse(completed.runtime.acceptsInput(from: attempt))
  }

  @MainActor
  func testBackgroundResetsPlayingOnceAndReturningRequiresExplicitStart() throws {
    let id = try CardID("background")
    let game = RuntimeProbe()
    let feed = FeedController(
      cards: [.game(GameCard(id: id, kind: .sudoku))], runtimes: [id: game.runtime])
    feed.setSceneActive(true)
    game.runtime.start()
    guard case .playing(let attempt) = game.runtime.phase else { return XCTFail("Start failed") }
    feed.setSceneActive(false)
    feed.setSceneActive(false)
    XCTAssertEqual(game.resetCount, 1)
    game.move(from: attempt)
    XCTAssertEqual(game.moves, 0)
    feed.setSceneActive(true)
    XCTAssertEqual(game.runtime.phase, .preview)
    XCTAssertTrue(game.runtime.isVisible)
    XCTAssertEqual(feed.selectedCard?.id, id)
  }

  @MainActor
  func testPlaceholderControllerRetainsCompletedPresentationAndClearsSkippedInput() {
    let runtime = GameRuntime()
    let game = PlaceholderGameController(runtime: runtime)
    game.interact()
    XCTAssertEqual(game.interactions, 0)
    runtime.setVisible(true)
    runtime.start()
    XCTAssertEqual(game.interactions, 0)
    game.interact()
    runtime.setVisible(false)
    XCTAssertEqual(game.interactions, 0)
    runtime.setVisible(true)
    runtime.start()
    game.interact()
    game.complete()
    runtime.setVisible(false)
    runtime.setVisible(true)
    game.interact()
    XCTAssertEqual(game.interactions, 1)
    guard case .completed = runtime.phase else { return XCTFail("Completion was lost") }
  }
}

@MainActor
private final class RuntimeProbe {
  let runtime: GameRuntime
  var effects: [GameLifecycleEffect] = []
  var moves = 0
  var resetCount = 0
  var stops = 0
  var wasIneligibleDuringReset = false

  init() {
    var attemptNumber: UInt8 = 0
    runtime = GameRuntime(makeAttemptID: {
      attemptNumber += 1
      return GameAttemptID(UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, attemptNumber)))
    })
    runtime.installEffectHandler { [weak self] effect in
      guard let self else { return }
      effects.append(effect)
      switch effect {
      case .start: moves = 0
      case .reset(let old):
        wasIneligibleDuringReset = !runtime.acceptsInput(from: old)
        // Actual game adapters cancel owned tasks here, before resetting rules.
        resetCount += 1
        moves = 0
      case .stop: stops += 1
      }
    }
  }

  func move(from attempt: GameAttemptID) {
    guard runtime.acceptsInput(from: attempt) else { return }
    moves += 1
  }
}
