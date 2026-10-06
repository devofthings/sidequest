import XCTest

@MainActor
final class DailyStreakFlowTests: XCTestCase {
  func testOnlySettledPhysicalSwipeQualifiesAndRelaunchKeepsCount() {
    continueAfterFailure = false
    let app = launch()
    XCTAssertEqual(indicator(app).value as? String, "0 days")
    app.nextFeedCard()
    XCTAssertEqual(indicator(app).value as? String, "0 days")
    app.previousFeedCard()
    let pager = app.scrollViews["feed.pager"]
    let middle = pager.coordinate(withNormalizedOffset: CGVector(dx: 0.55, dy: 0.5))
    let short = pager.coordinate(withNormalizedOffset: CGVector(dx: 0.55, dy: 0.44))
    middle.press(
      forDuration: 0.01, thenDragTo: short, withVelocity: .slow, thenHoldForDuration: 0.2)
    XCTAssertEqual(app.selectedFeedCardID, "sample-game-sudoku")
    XCTAssertEqual(indicator(app).value as? String, "0 days")
    let before = app.staticTexts["foundation.title"].frame
    let bottom = pager.coordinate(withNormalizedOffset: CGVector(dx: 0.55, dy: 0.85))
    let top = pager.coordinate(withNormalizedOffset: CGVector(dx: 0.55, dy: 0.15))
    bottom.press(forDuration: 0.01, thenDragTo: top, withVelocity: .slow, thenHoldForDuration: 0.3)
    app.waitForFeedCard("sample-news-garden")
    XCTAssertEqual(indicator(app).value as? String, "1 day")
    XCTAssertEqual(app.staticTexts["foundation.title"].frame.height, before.height, accuracy: 1)
    app.terminate()
    app.launchArguments.removeAll { $0 == "-sidequest-streak-reset" }
    app.launch()
    XCTAssertTrue(indicator(app).waitForExistence(timeout: 10))
    XCTAssertEqual(indicator(app).value as? String, "1 day")
  }

  func testSuccessfulSolveQualifiesWithoutSwipeAndRevisitStaysQuiet() {
    continueAfterFailure = false
    let app = launch()
    XCTAssertEqual(indicator(app).value as? String, "0 days")
    for (cell, value) in [(2, 3), (4, 3), (7, 2), (8, 2), (11, 3), (13, 3), (14, 2)] {
      app.buttons["sudoku.cell.\(cell)"].tap()
      app.buttons["sudoku.number.\(value)"].tap()
    }
    XCTAssertEqual(app.staticTexts["sudoku.status"].label, "Sudoku solved!")
    XCTAssertEqual(indicator(app).value as? String, "1 day")
    app.nextFeedCard()
    app.previousFeedCard()
    XCTAssertEqual(indicator(app).value as? String, "1 day")
  }

  func testLargestTextKeepsStreakTitleAndMenuReachable() {
    continueAfterFailure = false
    let app = launch(largeText: true)
    XCTAssertTrue(indicator(app).isHittable)
    XCTAssertTrue(app.staticTexts["foundation.title"].isHittable)
    XCTAssertTrue(app.buttons["feed.navigation"].isHittable)
    XCTAssertLessThanOrEqual(indicator(app).frame.width, 73)
    XCTAssertGreaterThanOrEqual(app.staticTexts["foundation.title"].frame.width, 180)
    let screenshot = XCTAttachment(screenshot: app.screenshot())
    screenshot.name = "daily-streak-largest-text-compact-header"
    screenshot.lifetime = .keepAlways
    add(screenshot)
    XCTAssertEqual(indicator(app).value as? String, "0 days")
    app.nextFeedCard()
    XCTAssertTrue(indicator(app).isHittable)
    XCTAssertEqual(indicator(app).value as? String, "0 days")
  }

  private func launch(largeText: Bool = false) -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments = [
      "-sidequest-sudoku-test", "-sidequest-streak-fixtures", "-sidequest-streak-reset",
    ]
    if largeText { app.launchArguments.append("-sidequest-large-text") }
    app.launch()
    XCTAssertTrue(app.buttons["sudoku.cell.2"].waitForExistence(timeout: 10))
    XCTAssertTrue(indicator(app).waitForExistence(timeout: 5))
    return app
  }

  private func indicator(_ app: XCUIApplication) -> XCUIElement {
    app.otherElements["streak.daily"]
  }
}
