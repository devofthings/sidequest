import XCTest

@MainActor
final class PagerFlowTests: XCTestCase {
  func testDirectCardDragTracksAndCommitsThenReverseReturnsToPreview() {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["-sidequest-sudoku-test"]
    app.launch()
    XCTAssertTrue(app.buttons["sudoku.cell.2"].waitForExistence(timeout: 10))
    XCTAssertFalse(app.buttons["game.start"].exists)
    app.buttons["sudoku.cell.2"].tap()
    app.buttons["sudoku.number.3"].tap()
    let pager = app.scrollViews["feed.pager"]
    XCTAssertTrue(pager.exists)
    let middle = pager.coordinate(withNormalizedOffset: CGVector(dx: 0.55, dy: 0.5))
    let short = pager.coordinate(withNormalizedOffset: CGVector(dx: 0.55, dy: 0.44))
    middle.press(
      forDuration: 0.01, thenDragTo: short, withVelocity: .slow, thenHoldForDuration: 0.2)
    XCTAssertEqual(app.selectedFeedCardID, "sample-game-sudoku")
    XCTAssertEqual(app.buttons["sudoku.cell.2"].value as? String, "3")
    let bottom = pager.coordinate(withNormalizedOffset: CGVector(dx: 0.55, dy: 0.85))
    let top = pager.coordinate(withNormalizedOffset: CGVector(dx: 0.55, dy: 0.15))
    bottom.press(forDuration: 0.01, thenDragTo: top, withVelocity: .slow, thenHoldForDuration: 0.3)
    waitForPosition("sample-news-garden", in: app)
    XCTAssertFalse(app.buttons["game.start"].exists)
    top.press(forDuration: 0.01, thenDragTo: bottom, withVelocity: .slow, thenHoldForDuration: 0.3)
    waitForPosition("sample-game-sudoku", in: app)
    XCTAssertFalse(app.buttons["game.start"].exists)
    XCTAssertEqual(app.buttons["sudoku.cell.2"].value as? String, "Empty")
    XCTAssertFalse(app.buttons["sudoku.number.3"].isEnabled)
  }

  func testFastFlickAndFirstLastBounds() {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["-sidequest-feed-games-only"]
    app.launch()
    XCTAssertTrue(app.buttons["game.start"].waitForExistence(timeout: 5))
    let pager = app.scrollViews["feed.pager"]
    let first = app.selectedFeedCardID
    pager.swipeDown(velocity: .fast)
    XCTAssertEqual(app.selectedFeedCardID, first)
    var visited = [first]
    for _ in 0..<3 {
      let old = app.selectedFeedCard.identifier
      pager.swipeUp(velocity: .fast)
      let changed = expectation(
        for: NSPredicate(format: "identifier != %@", old), evaluatedWith: app.selectedFeedCard)
      wait(for: [changed], timeout: 5)
      visited.append(app.selectedFeedCardID)
    }
    XCTAssertEqual(Set(visited).count, 4)
    pager.swipeUp(velocity: .fast)
    XCTAssertEqual(app.selectedFeedCardID, visited[3])
    app.buttons["feed.navigation"].tap()
    XCTAssertFalse(app.buttons["feed.next"].exists)
    app.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.1)).tap()
    pager.swipeDown(velocity: .fast)
    app.waitForFeedCard(visited[2])
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
    XCTAssertEqual(app.selectedFeedCardID, "sample-game-bubbleShooter")
    XCTAssertEqual(app.staticTexts["game.interactions"].label, "Interactions: 0")
    control.tap()
    XCTAssertEqual(app.staticTexts["game.interactions"].label, "Interactions: 1")
    XCTAssertEqual(app.selectedFeedCardID, "sample-game-bubbleShooter")
  }

  func testLargestTextScrollsContentBeforeOutwardEdgePages() {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["-sidequest-sudoku-test", "-sidequest-large-text"]
    app.launch()
    XCTAssertTrue(app.buttons["sudoku.cell.2"].waitForExistence(timeout: 5))
    app.buttons["sudoku.cell.2"].tap()
    let content = app.scrollViews["feed.cardScroll"]
    let start = content.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.85))
    let end = content.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.15))
    let originalBottom = app.buttons["sudoku.clear"].frame.minY
    start.press(forDuration: 0.01, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.1)
    XCTAssertLessThan(app.buttons["sudoku.clear"].frame.minY, originalBottom)
    XCTAssertEqual(app.selectedFeedCardID, "sample-game-sudoku")
    XCTAssertTrue(app.buttons["sudoku.clear"].exists)
    for _ in 0..<6 {
      if app.selectedFeedCardID != "sample-game-sudoku" { break }
      start.press(forDuration: 0.01, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.1)
    }
    waitForPosition("sample-news-garden", in: app)
    app.previousFeedCard()
    XCTAssertFalse(app.buttons["game.start"].exists)
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
      waitForPosition("sample-game-chess", in: app)
      XCTAssertEqual(app.buttons.matching(identifier: "game.start").count, 1)
      app.scrollViews["feed.pager"].swipeDown(velocity: .slow)
      waitForPosition("sample-game-bubbleShooter", in: app)
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
    waitForPosition("sample-news-garden", in: app)
    let original = app.links["news.source"]
    XCTAssertTrue(original.exists)
    original.tap()
    let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
    XCTAssertTrue(safari.wait(for: .runningForeground, timeout: 5))
    app.activate()
    XCTAssertTrue(app.links["news.source"].waitForExistence(timeout: 5))
    XCTAssertEqual(app.selectedFeedCardID, "sample-news-garden")
  }

  func testReplacingSessionInSameViewRejectsOldRequestAndActivatesNewPreview() {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["-sidequest-feed-replacement-test"]
    app.launch()
    XCTAssertTrue(app.buttons["game.start"].waitForExistence(timeout: 5))
    app.nextFeedCard()
    waitForPosition("sample-game-chess", in: app)
    app.buttons["game.start"].tap()
    app.buttons["game.interact"].tap()
    app.buttons["feed.replaceFixture"].tap()
    waitForPosition("sample-game-bubbleShooter", in: app)
    XCTAssertTrue(app.buttons["game.start"].isEnabled)
    app.buttons["game.start"].tap()
    XCTAssertEqual(app.staticTexts["game.interactions"].label, "Interactions: 0")
    app.buttons["game.interact"].tap()
    XCTAssertEqual(app.staticTexts["game.interactions"].label, "Interactions: 1")
    XCTAssertEqual(app.selectedFeedCardID, "sample-game-bubbleShooter")
  }

  private func waitForPosition(_ position: String, in app: XCUIApplication) {
    app.waitForFeedCard(position)
  }
}
