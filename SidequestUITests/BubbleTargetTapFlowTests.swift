import XCTest

@MainActor
final class BubbleTargetTapFlowTests: XCTestCase {
  func testUpperAndLowerTargetsShootOnceWhileDragAndUpperSwipeRemainUsable() {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["-sidequest-bubble-fixtures"]
    app.launchWithManualFeed()
    let aim = app.bubbleAim
    XCTAssertTrue(aim.waitForExistence(timeout: 5))
    let board = app.otherElements["bubble.board"]
    let initial = board.frame
    board.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.3)).tap()
    waitForShots(1, app: app)
    XCTAssertEqual(aim.value as? String, "Aim: -22 degrees")
    XCTAssertEqual(board.frame, initial)
    aim.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.2)).tap()
    waitForShots(2, app: app)
    XCTAssertEqual(aim.value as? String, "Aim: -45 degrees")
    XCTAssertEqual(board.frame, initial)
    app.shootBubble(at: 0.65)
    waitForShots(3, app: app)
    XCTAssertEqual(aim.value as? String, "Aim: 18 degrees")
    XCTAssertEqual(board.frame, initial)
    let selected = app.selectedFeedCardID
    let start = board.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
    let end = board.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
    start.press(
      forDuration: 0.01, thenDragTo: end, withVelocity: .fast,
      thenHoldForDuration: 0.1)
    XCTAssertNotEqual(app.selectedFeedCardID, selected)
    app.previousFeedCard()
    XCTAssertEqual(app.selectedFeedCardID, selected)
    XCTAssertEqual(app.staticTexts["bubble.shots"].label, "Shots: 0 of 8")
    XCTAssertEqual(aim.value as? String, "Aim: 0 degrees")
    // A stationary launcher/downward touch must not start an attempt or consume a shot.
    aim.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.95)).tap()
    XCTAssertEqual(app.staticTexts["bubble.shots"].label, "Shots: 0 of 8")
    XCTAssertEqual(aim.value as? String, "Aim: 0 degrees")
    XCTAssertFalse(app.buttons["game.start"].exists)
    let screenshot = XCTAttachment(screenshot: app.screenshot())
    screenshot.name = "bubble-target-taps-and-reset"
    screenshot.lifetime = .keepAlways
    add(screenshot)
    app.terminate()
  }

  private func waitForShots(_ count: Int, app: XCUIApplication) {
    let committed = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "label == %@", "Shots: \(count) of 8"),
      object: app.staticTexts["bubble.shots"])
    XCTAssertEqual(XCTWaiter.wait(for: [committed], timeout: 10), .completed)
  }
}
