import Foundation
import XCTest

@testable import Sidequest

final class GameLifecycleTests: XCTestCase {
  func testPreviewRejectsInputAndStartRequiresVisibility() {
    var lifecycle = GameLifecycle()
    let attempt = GameAttemptID()
    XCTAssertEqual(lifecycle.phase, .preview)
    XCTAssertFalse(lifecycle.acceptsInput(from: attempt))
    XCTAssertNil(lifecycle.start { attempt })
    XCTAssertNil(lifecycle.setVisible(true))
    XCTAssertEqual(lifecycle.phase, .preview)
    XCTAssertFalse(lifecycle.acceptsInput(from: attempt))
    XCTAssertNil(lifecycle.complete(attempt: attempt))
  }

  func testStartIsIdempotentAndAcceptsOnlyCurrentAttempt() {
    var lifecycle = GameLifecycle()
    XCTAssertNil(lifecycle.setVisible(true))
    var minted = 0
    let attempt = GameAttemptID()
    let make = {
      minted += 1
      return attempt
    }
    XCTAssertEqual(lifecycle.start(makeAttemptID: make), .start(attempt))
    XCTAssertNil(lifecycle.start(makeAttemptID: make))
    XCTAssertEqual(minted, 1)
    XCTAssertEqual(lifecycle.phase, .playing(attempt))
    XCTAssertTrue(lifecycle.acceptsInput(from: attempt))
    XCTAssertFalse(lifecycle.acceptsInput(from: GameAttemptID()))
    XCTAssertNil(lifecycle.complete(attempt: GameAttemptID()))
  }

  func testSkippingInvalidatesAttemptBeforeResetAndRequiresNewStart() {
    var lifecycle = GameLifecycle()
    let old = GameAttemptID()
    let next = GameAttemptID()
    XCTAssertNil(lifecycle.setVisible(true))
    XCTAssertEqual(lifecycle.start { old }, .start(old))
    XCTAssertEqual(lifecycle.setVisible(false), .reset(old))
    XCTAssertEqual(lifecycle.phase, .preview)
    XCTAssertFalse(lifecycle.acceptsInput(from: old))
    XCTAssertNil(lifecycle.setVisible(false))
    XCTAssertNil(lifecycle.setVisible(true))
    XCTAssertNil(lifecycle.complete(attempt: old))
    XCTAssertFalse(lifecycle.acceptsInput(from: old))
    XCTAssertEqual(lifecycle.start { next }, .start(next))
    XCTAssertNil(lifecycle.complete(attempt: old))
    XCTAssertEqual(lifecycle.phase, .playing(next))
    XCTAssertTrue(lifecycle.acceptsInput(from: next))
  }

  func testCompletedStateSurvivesRevisitAndRejectsFurtherEvents() {
    var lifecycle = GameLifecycle()
    let attempt = GameAttemptID()
    XCTAssertNil(lifecycle.setVisible(true))
    XCTAssertEqual(lifecycle.start { attempt }, .start(attempt))
    XCTAssertEqual(lifecycle.complete(attempt: attempt), .stop(attempt))
    XCTAssertFalse(lifecycle.acceptsInput(from: attempt))
    XCTAssertNil(lifecycle.complete(attempt: attempt))
    XCTAssertNil(lifecycle.setVisible(false))
    XCTAssertEqual(lifecycle.phase, .completed(attempt))
    XCTAssertNil(lifecycle.setVisible(true))
    XCTAssertNil(lifecycle.start())
    XCTAssertEqual(lifecycle.phase, .completed(attempt))
  }
}
