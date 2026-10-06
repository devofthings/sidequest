import XCTest

@MainActor
final class AutoContinueFlowTests: XCTestCase {
  func testBidirectionalStartupReplenishesAboveAndReturnsToTheOriginalCard() {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = [
      "-sidequest-integration-fixtures", "-sidequest-endless-fixtures",
      "-sidequest-integration-reset", "-sidequest-bidirectional-test",
    ]
    app.launchWithManualFeed()
    XCTAssertTrue(app.scrollViews["feed.pager"].waitForExistence(timeout: 10))
    let original = app.selectedFeedCardID
    for _ in 0..<14 { app.previousFeedCard() }
    XCTAssertNotEqual(app.selectedFeedCardID, original)
    for _ in 0..<14 { app.nextFeedCard() }
    XCTAssertEqual(app.selectedFeedCardID, original)
    app.buttons["feed.navigation"].tap()
    XCTAssertFalse(app.buttons["feed.previous"].exists)
    XCTAssertFalse(app.buttons["feed.next"].exists)
  }

  func testWinAdvancesOnceAndTimerTapDisablesUntilReenabled() {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["-sidequest-chess-white-fixture"]
    app.launch()
    XCTAssertTrue(app.buttons["chess.square.g6"].waitForExistence(timeout: 10))
    app.buttons["chess.square.g6"].tap()
    app.buttons["chess.square.g7"].tap()
    let timer = app.buttons["feed.autoContinue"]
    XCTAssertTrue(timer.waitForExistence(timeout: 2))
    timer.tap()
    XCTAssertFalse(timer.exists)
    XCTAssertEqual(app.selectedFeedCardID, "sample-game-chess-white")
    app.buttons["feed.navigation"].tap()
    let toggle = app.buttons["feed.autoContinueToggle"]
    XCTAssertTrue(toggle.waitForExistence(timeout: 3))
    toggle.tap()
    app.nextFeedCard()
    app.previousFeedCard()
    XCTAssertFalse(timer.exists, "A completed revisit must not start a new countdown")
    app.terminate()
    app.launch()
    XCTAssertTrue(app.buttons["chess.square.g6"].waitForExistence(timeout: 10))
    app.buttons["chess.square.g6"].tap()
    app.buttons["chess.square.g7"].tap()
    app.waitForFeedCard("sample-news-garden")
    XCTAssertFalse(timer.exists)
    XCTAssertFalse(app.buttons["feed.previous"].exists)
    XCTAssertFalse(app.buttons["feed.next"].exists)
  }
}
