import XCTest

@MainActor
final class PagerFlowTests: XCTestCase {
  func testDirectCardDragTracksAndCommitsThenReverseReturnsToPreview() {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["-sidequest-feed-test"]
    app.launch()
    XCTAssertTrue(app.buttons["game.start"].waitForExistence(timeout: 10))
    app.buttons["game.start"].tap()
    app.buttons["game.interact"].tap()
    let pager = app.scrollViews["feed.pager"]
    XCTAssertTrue(pager.exists)
    let middle = pager.coordinate(withNormalizedOffset: CGVector(dx: 0.55, dy: 0.5))
    let short = pager.coordinate(withNormalizedOffset: CGVector(dx: 0.55, dy: 0.44))
    middle.press(
      forDuration: 0.01, thenDragTo: short, withVelocity: .slow, thenHoldForDuration: 0.2)
    XCTAssertEqual(app.staticTexts["feed.position"].label, "Card 1 of 6")
    XCTAssertEqual(app.staticTexts["game.interactions"].label, "Interactions: 1")
    let bottom = pager.coordinate(withNormalizedOffset: CGVector(dx: 0.55, dy: 0.85))
    let top = pager.coordinate(withNormalizedOffset: CGVector(dx: 0.55, dy: 0.15))
    bottom.press(forDuration: 0.01, thenDragTo: top, withVelocity: .slow, thenHoldForDuration: 0.3)
    waitForPosition("Card 2 of 6", in: app)
    XCTAssertTrue(app.buttons["game.start"].exists)
    top.press(forDuration: 0.01, thenDragTo: bottom, withVelocity: .slow, thenHoldForDuration: 0.3)
    waitForPosition("Card 1 of 6", in: app)
    XCTAssertTrue(app.buttons["game.start"].exists)
  }

  func testFastFlickAndFirstLastBounds() {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["-sidequest-feed-games-only"]
    app.launch()
    XCTAssertTrue(app.buttons["game.start"].waitForExistence(timeout: 5))
    let pager = app.scrollViews["feed.pager"]
    pager.swipeDown(velocity: .fast)
    XCTAssertEqual(app.staticTexts["feed.position"].label, "Card 1 of 4")
    pager.swipeUp(velocity: .fast)
    waitForPosition("Card 2 of 4", in: app)
    pager.swipeUp(velocity: .fast)
    waitForPosition("Card 3 of 4", in: app)
    pager.swipeUp(velocity: .fast)
    waitForPosition("End of feed • Card 4 of 4", in: app)
    pager.swipeUp(velocity: .fast)
    XCTAssertEqual(app.staticTexts["feed.position"].label, "End of feed • Card 4 of 4")
    pager.swipeDown(velocity: .fast)
    waitForPosition("Card 3 of 4", in: app)
  }

  func testHorizontalGameDragAndTapDoNotPage() {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["-sidequest-feed-test"]
    app.launch()
    XCTAssertTrue(app.buttons["game.start"].waitForExistence(timeout: 5))
    app.buttons["game.start"].tap()
    let control = app.buttons["game.interact"]
    let pager = app.scrollViews["feed.pager"]
    let right = pager.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.5))
    let left = pager.coordinate(withNormalizedOffset: CGVector(dx: 0.15, dy: 0.5))
    right.press(forDuration: 0.01, thenDragTo: left, withVelocity: .slow, thenHoldForDuration: 0.1)
    XCTAssertEqual(app.staticTexts["feed.position"].label, "Card 1 of 6")
    XCTAssertEqual(app.staticTexts["game.interactions"].label, "Interactions: 0")
    control.tap()
    XCTAssertEqual(app.staticTexts["game.interactions"].label, "Interactions: 1")
    XCTAssertEqual(app.staticTexts["feed.position"].label, "Card 1 of 6")
  }

  func testLargestTextScrollsContentBeforeOutwardEdgePages() {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["-sidequest-sudoku-test", "-sidequest-large-text"]
    app.launch()
    XCTAssertTrue(app.buttons["game.start"].waitForExistence(timeout: 5))
    app.buttons["game.start"].tap()
    let content = app.scrollViews["feed.cardScroll"]
    let start = content.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.85))
    let end = content.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.15))
    let originalBottom = app.buttons["sudoku.clear"].frame.minY
    start.press(forDuration: 0.01, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.1)
    XCTAssertLessThan(app.buttons["sudoku.clear"].frame.minY, originalBottom)
    XCTAssertEqual(app.staticTexts["feed.position"].label, "Card 1 of 2")
    XCTAssertTrue(app.buttons["sudoku.clear"].exists)
    for _ in 0..<6 {
      if app.staticTexts["feed.position"].label != "Card 1 of 2" { break }
      start.press(forDuration: 0.01, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.1)
    }
    waitForPosition("End of feed • Card 2 of 2", in: app)
    app.previousFeedCard()
    XCTAssertTrue(app.buttons["game.start"].exists)
  }

  func testSystemReduceMotionKeepsMenuAndFingerPagingUsable() {
    continueAfterFailure = false
    SystemAccessibilitySupport.withReduceMotion {
      let app = XCUIApplication()
      app.launchArguments = ["-sidequest-feed-test"]
      app.launch()
      XCTAssertTrue(app.buttons["game.start"].waitForExistence(timeout: 5))
      XCTAssertEqual(app.buttons.matching(identifier: "game.start").count, 1)
      app.nextFeedCard()
      waitForPosition("Card 2 of 6", in: app)
      XCTAssertEqual(app.buttons.matching(identifier: "game.start").count, 1)
      app.scrollViews["feed.pager"].swipeDown(velocity: .slow)
      waitForPosition("Card 1 of 6", in: app)
      app.buttons["game.start"].tap()
      XCTAssertEqual(app.staticTexts["game.interactions"].label, "Interactions: 0")
      app.terminate()
    }
  }

  func testOriginalLinkOpensWithoutAdvancingTheNewsCard() {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["-sidequest-feed-test"]
    app.launch()
    XCTAssertTrue(app.buttons["game.start"].waitForExistence(timeout: 5))
    for _ in 0..<4 { app.nextFeedCard() }
    waitForPosition("Card 5 of 6", in: app)
    let original = app.links["news.source"]
    XCTAssertTrue(original.exists)
    original.tap()
    let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
    XCTAssertTrue(safari.wait(for: .runningForeground, timeout: 5))
    app.activate()
    XCTAssertTrue(app.links["news.source"].waitForExistence(timeout: 5))
    XCTAssertEqual(app.staticTexts["feed.position"].label, "Card 5 of 6")
  }

  private func waitForPosition(_ position: String, in app: XCUIApplication) {
    let target = app.staticTexts["feed.position"]
    let expected = expectation(
      for: NSPredicate(format: "label == %@", position), evaluatedWith: target)
    wait(for: [expected], timeout: 5)
  }
}
