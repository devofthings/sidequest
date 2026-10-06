import XCTest

@MainActor
final class VariedCelebrationFlowTests: XCTestCase {
  func testFourStylesAfterRealChessWinsKeepTheBoardStable() {
    verifyStyles(largeText: false)
  }

  func testLargestTextStylesWithActualReduceMotion() {
    SystemAccessibilitySupport.withReduceMotion { verifyStyles(largeText: true) }
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
      XCTAssertEqual(XCTWaiter.wait(for: [centered], timeout: 5), .completed)
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
