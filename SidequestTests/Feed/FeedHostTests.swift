import Foundation
import SwiftUI
import UIKit
import XCTest

@testable import Sidequest

final class FeedHostTests: XCTestCase {
  @MainActor
  func testPrependPreservesPlayingIdentityAndDefersWhilePagerHoldsIndices() throws {
    let ids = try [CardID("above"), CardID("current")]
    let runtime = GameRuntime()
    runtime.installEffectHandler { _ in }
    let current = FeedCard.game(GameCard(id: ids[1], kind: .memory))
    let above = FeedCard.game(GameCard(id: ids[0], kind: .chess))
    let feed = FeedController(cards: [current], runtimes: [ids[1]: runtime], isEndless: true)
    feed.setSceneActive(true)
    runtime.start()
    let phase = runtime.phase
    feed.setPagingBusy(true)
    XCTAssertFalse(feed.prepend([above]))
    XCTAssertEqual(feed.selectedIndex, 0)
    feed.setPagingBusy(false)
    XCTAssertTrue(feed.prepend([above]))
    XCTAssertEqual(feed.selectedIndex, 1)
    XCTAssertEqual(feed.selectedCard?.id, ids[1])
    XCTAssertEqual(runtime.phase, phase)
    XCTAssertTrue(runtime.isVisible)
    XCTAssertTrue(feed.canGoBack)
    feed.retire()
    XCTAssertFalse(feed.prepend([above]))
  }

  @MainActor
  func testNativePrependRetainsTheSelectedHostingRootAndContentOffset() throws {
    let ids = try (0..<12).map { try CardID("stable-\($0)") }
    let cards = ids.map { FeedCard.game(GameCard(id: $0, kind: .memory)) }
    let feed = FeedController(
      cards: Array(cards.suffix(3)), runtimes: [:], isEndless: true, initialIndex: 1)
    feed.setSceneActive(true)
    let render: (FeedCard) -> AnyView = { _ in AnyView(Color.clear.frame(height: 1600)) }
    let pager = FeedPagerController(controller: feed, content: render)
    pager.loadViewIfNeeded()
    pager.view.frame = CGRect(x: 0, y: 0, width: 390, height: 600)
    pager.view.setNeedsLayout()
    pager.view.layoutIfNeeded()
    pager.update(content: render, request: nil, reduceMotion: true)
    let root = try XCTUnwrap(pager.children.first { $0.view.frame.minY == 600 })
    let scroller = try XCTUnwrap(root.view.subviews.compactMap { $0 as? UIScrollView }.first)
    scroller.contentSize = CGSize(width: 390, height: 1600)
    scroller.setContentOffset(CGPoint(x: 0, y: 240), animated: false)
    let selectedID = feed.selectedCard?.id
    XCTAssertTrue(feed.prepend(Array(cards.prefix(9))))
    pager.update(content: render, request: nil, reduceMotion: true)
    pager.view.layoutIfNeeded()
    XCTAssertEqual(feed.selectedCard?.id, selectedID)
    XCTAssertTrue(pager.children.contains { $0 === root })
    XCTAssertEqual(scroller.contentOffset.y, 240)
    XCTAssertEqual(pager.children.count, 3)
    pager.stop()
    feed.retire()
  }

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
  func testSettledPageRejectsCanceledAndNonAdjacentChanges() throws {
    let ids = try [CardID("current"), CardID("neighbor"), CardID("distant")]
    let probes = [RuntimeProbe(), RuntimeProbe(), RuntimeProbe()]
    let feed = FeedController(
      cards: ids.map { .game(GameCard(id: $0, kind: .memory)) },
      runtimes: Dictionary(uniqueKeysWithValues: zip(ids, probes.map(\.runtime))))
    feed.setSceneActive(true)
    probes[0].runtime.start()
    guard case .playing(let attempt) = probes[0].runtime.phase else {
      return XCTFail("Start failed")
    }
    probes[0].move(from: attempt)
    for index in [0, -1, 2, Int.max] { feed.commitPage(at: index) }
    XCTAssertEqual(feed.selectedIndex, 0)
    XCTAssertEqual(probes[0].moves, 1)
    XCTAssertEqual(probes[0].resetCount, 0)
    probes[1].runtime.start()
    XCTAssertTrue(probes[1].effects.isEmpty)
    feed.commitPage(at: 1)
    XCTAssertEqual(probes[0].resetCount, 1)
    XCTAssertTrue(probes[0].wasIneligibleDuringReset)
    XCTAssertTrue(probes[1].runtime.isVisible)
    XCTAssertFalse(probes[2].runtime.isVisible)
    feed.commitPage(at: 1)
    XCTAssertEqual(probes[0].resetCount, 1)
  }

  @MainActor
  func testUnavailableHostAndInactiveSceneRejectLatePageCommit() throws {
    let ids = try [CardID("first"), CardID("second")]
    let first = RuntimeProbe()
    let second = RuntimeProbe()
    let feed = FeedController(
      cards: ids.map { .game(GameCard(id: $0, kind: .memory)) },
      runtimes: [ids[0]: first.runtime, ids[1]: second.runtime])
    feed.setSceneActive(true)
    first.runtime.start()
    feed.setHostAvailable(false)
    XCTAssertEqual(first.resetCount, 1)
    feed.commitPage(at: 1)
    feed.setSceneActive(true)
    XCTAssertFalse(feed.canNavigate)
    XCTAssertFalse(first.runtime.isVisible)
    feed.setSceneActive(false)
    feed.setHostAvailable(true)
    XCTAssertFalse(feed.canNavigate)
    feed.commitPage(at: 1)
    XCTAssertEqual(feed.selectedIndex, 0)
    feed.setSceneActive(true)
    XCTAssertTrue(first.runtime.isVisible)
    XCTAssertEqual(first.runtime.phase, .preview)
  }

  @MainActor
  func testRetiredSessionCannotBeReactivatedByOldSceneOrHostCallbacks() throws {
    let id = try CardID("retired")
    let game = RuntimeProbe()
    let feed = FeedController(
      cards: [.game(GameCard(id: id, kind: .memory))], runtimes: [id: game.runtime])
    feed.setSceneActive(true)
    game.runtime.start()
    guard case .playing(let old) = game.runtime.phase else { return XCTFail("Start failed") }
    feed.retire()
    feed.setHostAvailable(true)
    feed.setSceneActive(true)
    feed.retire()
    game.move(from: old)
    game.runtime.start()
    XCTAssertFalse(feed.canNavigate)
    XCTAssertFalse(game.runtime.isVisible)
    XCTAssertEqual(game.moves, 0)
    XCTAssertEqual(game.resetCount, 1)
  }

  @MainActor
  func testReplacementPagerRejectsOldRequestsAndStoppedCallbacks() throws {
    let ids = try [CardID("first"), CardID("second")]
    let cards = ids.map { FeedCard.game(GameCard(id: $0, kind: .memory)) }
    let old = FeedController(
      cards: cards, runtimes: Dictionary(uniqueKeysWithValues: ids.map { ($0, GameRuntime()) }))
    let obsolete = FeedPageRequest(controller: old, step: 1)
    old.retire()
    let first = RuntimeProbe()
    let second = RuntimeProbe()
    let replacement = FeedController(
      cards: cards, runtimes: [ids[0]: first.runtime, ids[1]: second.runtime])
    replacement.setSceneActive(true)
    first.runtime.start()
    let render: (FeedCard) -> AnyView = { _ in AnyView(Text("Fixture card")) }
    let pager = FeedPagerController(controller: replacement, content: render)
    pager.loadViewIfNeeded()
    pager.view.frame = CGRect(x: 0, y: 0, width: 390, height: 600)
    pager.view.setNeedsLayout()
    pager.view.layoutIfNeeded()
    pager.update(content: render, request: obsolete, reduceMotion: true)
    XCTAssertEqual(replacement.selectedIndex, 0)
    XCTAssertEqual(first.resetCount, 0)
    pager.update(
      content: render, request: FeedPageRequest(controller: replacement, step: 1),
      reduceMotion: true)
    XCTAssertEqual(replacement.selectedIndex, 1)
    XCTAssertEqual(first.resetCount, 1)
    pager.stop()
    pager.update(
      content: render, request: FeedPageRequest(controller: replacement, step: -1),
      reduceMotion: true)
    pager.scrollViewDidEndScrollingAnimation(UIScrollView())
    XCTAssertEqual(replacement.selectedIndex, 1)
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
