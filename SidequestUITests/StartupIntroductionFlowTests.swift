import XCTest

@MainActor
final class StartupIntroductionFlowTests: XCTestCase {
  func testColdLaunchAndForegroundKeepRealGameInactiveAndFeedPosition() {
    let app = XCUIApplication()
    app.launchArguments = ["-sidequest-sudoku-test"]
    app.launch()
    XCTAssertTrue(app.buttons["game.start"].waitForExistence(timeout: 10))
    XCTAssertTrue(app.buttons["game.start"].isHittable)
    XCTAssertEqual(app.buttons["sudoku.cell.2"].value as? String, "Empty")
    XCTAssertFalse(app.buttons["sudoku.cell.2"].isEnabled)
    XCTAssertFalse(app.buttons["sudoku.cell.2"].isSelected)
    let selected = app.selectedFeedCardID
    XCUIDevice.shared.press(.home)
    app.activate()
    XCTAssertTrue(app.buttons["game.start"].waitForExistence(timeout: 5))
    XCTAssertEqual(app.selectedFeedCardID, selected)
    XCTAssertFalse(app.buttons["sudoku.cell.2"].isEnabled)
    app.buttons["game.start"].tap()
    app.buttons["sudoku.cell.2"].tap()
    XCTAssertTrue(app.buttons["sudoku.cell.2"].isSelected)
    app.buttons["sudoku.number.3"].tap()
    XCTAssertEqual(app.buttons["sudoku.cell.2"].value as? String, "3")
    XCTAssertEqual(app.selectedFeedCardID, selected)
  }
}
