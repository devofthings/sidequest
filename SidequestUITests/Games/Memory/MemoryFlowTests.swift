import XCTest

@MainActor
final class MemoryFlowTests: XCTestCase {
  func testFirstFlipStartsAndMatchingAllPairsRetainsCompletion() {
    let app = launch(successFeedback: true)
    XCTAssertFalse(app.buttons["game.start"].exists)
    XCTAssertTrue(app.buttons["memory.tile.0"].exists)
    XCTAssertTrue(app.buttons["memory.tile.0"].isEnabled)
    capture(app, name: "normal-started-board")
    XCTAssertEqual(app.buttons["memory.tile.0"].label, "Hidden card 1")
    XCTAssertEqual(app.staticTexts["memory.progress"].label, "0 of 6 pairs matched")
    app.buttons["memory.tile.0"].tap()
    XCTAssertEqual(app.buttons["memory.tile.0"].label, "Revealed star, card 1")
    app.buttons["memory.tile.0"].tap()
    app.buttons["memory.tile.1"].tap()
    XCTAssertEqual(app.buttons["memory.tile.0"].label, "Matched star, card 1")
    XCTAssertFalse(app.buttons["memory.tile.0"].isEnabled)
    for index in 2..<12 { tapTile(index, app: app) }
    XCTAssertTrue(app.staticTexts["game.successCelebration"].waitForExistence(timeout: 5))
    capture(app, name: "memory-success-celebration")
    XCTAssertTrue(app.staticTexts["memory.completed"].waitForExistence(timeout: 5))
    app.nextFeedCard()
    app.previousFeedCard()
    XCTAssertTrue(app.staticTexts["memory.completed"].exists)
    XCTAssertFalse(app.staticTexts["game.successCelebration"].exists)
    XCTAssertFalse(app.buttons["game.start"].exists)
    XCTAssertEqual(app.staticTexts["memory.progress"].label, "6 of 6 pairs matched")
  }

  func testSuccessWithSystemReduceMotionDoesNotRepeatAfterBackground() {
    continueAfterFailure = false
    SystemAccessibilitySupport.withReduceMotion {
      let app = launch(successFeedback: true)
      for index in 0..<12 { tapTile(index, app: app) }
      let badge = app.staticTexts["game.successCelebration"]
      XCTAssertTrue(badge.waitForExistence(timeout: 5))
      let appFrame = app.frame
      let badgeFrame = badge.frame
      let newsFrame = app.buttons["feed.news"].frame
      let navigationFrame = app.buttons["feed.navigation"].frame
      let scrollFrame = app.scrollViews["feed.cardScroll"].frame
      let frames = XCTAttachment(
        string:
          "app: \(appFrame)\nbadge: \(badgeFrame)\nnews: \(newsFrame)\nnavigation: \(navigationFrame)\ncardScroll: \(scrollFrame)"
      )
      frames.name = "memory-reduced-motion-header-viewport-frames"
      frames.lifetime = .keepAlways
      add(frames)
      let screen = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
      screen.name = "memory-success-system-reduce-motion-whole-screen"
      screen.lifetime = .keepAlways
      add(screen)
      capture(app, name: "memory-success-system-reduce-motion-app-element")
      for (name, frame) in [
        ("badge", badgeFrame), ("news", newsFrame), ("navigation", navigationFrame),
      ] {
        XCTAssertFalse(frame.isEmpty, "\(name) needs a real visible footprint.")
        XCTAssertTrue(
          appFrame.contains(frame), "The entire \(name) must remain in the app viewport.")
        XCTAssertLessThanOrEqual(
          frame.maxY, scrollFrame.minY + 1,
          "\(name) remains in the fixed header above the card scroller.")
      }
      XCTAssertTrue(app.buttons["feed.news"].isHittable)
      XCTAssertTrue(app.buttons["feed.navigation"].isHittable)
      XCUIDevice.shared.press(.home)
      app.activate()
      XCTAssertTrue(app.staticTexts["memory.completed"].waitForExistence(timeout: 5))
      XCTAssertFalse(app.staticTexts["game.successCelebration"].exists)
      XCTAssertFalse(app.buttons["game.start"].exists)
      app.terminate()
    }
  }

  func testMismatchTurnsOverAndSkippingReturnsToUnflippedPreview() {
    let app = launch()
    app.buttons["memory.tile.0"].tap()
    app.buttons["memory.tile.2"].tap()
    let first = app.buttons["memory.tile.0"]
    let third = app.buttons["memory.tile.2"]
    let concealed = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "label == %@", "Hidden card 1"), object: first)
    XCTAssertEqual(XCTWaiter.wait(for: [concealed], timeout: 5), .completed)
    XCTAssertEqual(third.label, "Hidden card 3")
    first.tap()
    third.tap()
    app.nextFeedCard()
    app.previousFeedCard()
    XCTAssertFalse(app.buttons["game.start"].exists)
    XCTAssertTrue(app.buttons["memory.tile.0"].exists)
    XCTAssertTrue(app.buttons["memory.tile.0"].isEnabled)
    XCTAssertEqual(app.buttons["memory.tile.0"].label, "Hidden card 1")
    XCTAssertEqual(app.buttons["memory.tile.2"].label, "Hidden card 3")
    XCTAssertEqual(app.staticTexts["memory.progress"].label, "0 of 6 pairs matched")
  }

  func testLargestTextKeepsEveryTileAndNavigationReachable() {
    let app = launch(largeText: true, successFeedback: true)
    XCTAssertTrue(app.buttons["memory.tile.0"].isHittable)
    for index in 0..<11 { tapTile(index, app: app) }
    let lastTile = app.buttons["memory.tile.11"]
    reveal(lastTile, app: app)
    let tileFrame = lastTile.frame
    let viewport = app.scrollViews["feed.cardScroll"].frame
    tapTile(11, app: app)
    let badge = app.staticTexts["game.successCelebration"]
    XCTAssertTrue(badge.waitForExistence(timeout: 5))
    XCTAssertTrue(
      app.frame.contains(badge.frame), "Largest-text celebration must be fully visible.")
    XCTAssertLessThanOrEqual(badge.frame.maxY, viewport.minY + 1)
    XCTAssertEqual(app.scrollViews["feed.cardScroll"].frame, viewport)
    XCTAssertEqual(lastTile.frame, tileFrame)
    capture(app, name: "largest-memory-viewport-success")
    XCTAssertTrue(app.staticTexts["memory.completed"].waitForExistence(timeout: 5))
    reveal(app.staticTexts["memory.completed"], app: app)
    capture(app, name: "largest-text-completed-board")
    XCTAssertTrue(app.buttons["feed.navigation"].isHittable)
    app.nextFeedCard()
    XCTAssertTrue(app.buttons["feed.navigation"].isHittable)
    app.previousFeedCard()
    XCTAssertEqual(app.staticTexts["memory.progress"].label, "6 of 6 pairs matched")
  }

  private func tapTile(_ index: Int, app: XCUIApplication) {
    let tile = app.buttons["memory.tile.\(index)"]
    reveal(tile, app: app)
    XCTAssertTrue(tile.isHittable, "Card \(index + 1) must be reachable.")
    tile.tap()
  }

  private func reveal(_ element: XCUIElement, app: XCUIApplication) {
    let scroll = app.scrollViews["feed.cardScroll"]
    for _ in 0..<18 {
      if element.exists && element.isHittable && scroll.frame.contains(element.frame) { return }
      let start = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.65))
      let end = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4))
      start.press(forDuration: 0.1, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.1)
    }
    XCTAssertTrue(
      scroll.frame.contains(element.frame), "The control must be fully visible before interacting.")
  }

  private func capture(_ app: XCUIApplication, name: String) {
    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }

  private func launch(largeText: Bool = false, successFeedback: Bool = false) -> XCUIApplication {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments =
      ["-sidequest-memory-fixtures"]
      + (largeText ? ["-sidequest-large-text"] : [])
      + (successFeedback ? ["-sidequest-success-feedback-test"] : [])
    app.launch()
    XCTAssertTrue(app.buttons["memory.tile.0"].waitForExistence(timeout: 5))
    return app
  }
}
