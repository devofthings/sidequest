import XCTest

@MainActor
final class VariedCelebrationFlowTests: XCTestCase {
  func testFourStylesAfterRealChessWinsKeepTheBoardStable() {
    verifyStyles(largeText: false)
  }

  func testLargestTextStylesWithActualReduceMotion() {
    SystemAccessibilitySupport.withReduceMotion { verifyStyles(largeText: true) }
  }

  private func revealBoard(queen: XCUIElement, destination: XCUIElement, in app: XCUIApplication) {
    let scroll = app.scrollViews["feed.cardScroll"]
    for _ in 0..<12 {
      if scroll.frame.contains(queen.frame) && scroll.frame.contains(destination.frame)
        && queen.isHittable && destination.isHittable
      {
        return
      }
      let upwards = queen.frame.maxY > scroll.frame.maxY
      let start = scroll.coordinate(
        withNormalizedOffset: CGVector(dx: 0.01, dy: upwards ? 0.85 : 0.2))
      let end = scroll.coordinate(
        withNormalizedOffset: CGVector(dx: 0.01, dy: upwards ? 0.25 : 0.8))
      start.press(forDuration: 0.01, thenDragTo: end)
    }
    XCTFail("Both real move targets must be fully contained before measuring stable geometry")
  }

  private func verifyStyles(largeText: Bool) {
    continueAfterFailure = false
    for (index, message) in ["Nice!", "Brilliant!", "Nailed it!", "Well played!"].enumerated() {
      let app = XCUIApplication()
      app.launchArguments = [
        "-sidequest-chess-white-fixture", "-sidequest-success-feedback-test",
        "-sidequest-celebration-style", String(index),
      ]
      if largeText { app.launchArguments.append("-sidequest-large-text") }
      app.launchWithManualFeed()
      let queen = app.buttons["chess.square.g6"]
      let destination = app.buttons["chess.square.g7"]
      XCTAssertTrue(queen.waitForExistence(timeout: 10))
      revealBoard(queen: queen, destination: destination, in: app)
      let anchor = app.buttons["chess.square.e8"].frame
      let viewport = app.scrollViews["feed.cardScroll"].frame
      let header = app.buttons["feed.navigation"].frame
      queen.tap()
      destination.tap()
      let badge = app.staticTexts["game.successCelebration"]
      XCTAssertTrue(badge.waitForExistence(timeout: 5))
      XCTAssertEqual(badge.label, "Chess completed. \(message)")
      let centered = XCTNSPredicateExpectation(
        predicate: NSPredicate { _, _ in
          let frame = badge.frame
          return badge.exists && viewport.contains(frame)
            && abs(frame.midX - viewport.midX) <= 3 && abs(frame.midY - viewport.midY) <= 2
        }, object: badge)
      XCTAssertEqual(
        XCTWaiter.wait(for: [centered], timeout: 5), .completed,
        "Measured badge \(badge.frame) in viewport \(viewport)")
      XCTAssertEqual(app.buttons["chess.square.e8"].frame, anchor)
      XCTAssertEqual(app.scrollViews["feed.cardScroll"].frame, viewport)
      XCTAssertEqual(app.buttons["feed.navigation"].frame, header)
      let capture = XCTAttachment(screenshot: app.screenshot())
      capture.name = "celebration-\(index)-\(largeText ? "largest-reduced-motion" : "normal")"
      capture.lifetime = .keepAlways
      add(capture)
      app.nextFeedCard()
      XCTAssertFalse(badge.exists)
      app.previousFeedCard()
      XCTAssertTrue(app.staticTexts["chess.completed"].exists)
      XCTAssertFalse(badge.exists, "Completed revisits must stay quiet")
      app.terminate()
    }
  }
}
