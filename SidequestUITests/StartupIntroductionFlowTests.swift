import XCTest

@MainActor
final class StartupIntroductionFlowTests: XCTestCase {
  func testColdLaunchAndForegroundKeepRealGameInactiveAndFeedPosition() {
    assertColdLaunchAndForegroundKeepRealGameInactiveAndFeedPosition()
  }

  func testSystemReduceMotionKeepsColdLaunchAndForegroundUsable() {
    SystemAccessibilitySupport.withReduceMotion {
      assertColdLaunchAndForegroundKeepRealGameInactiveAndFeedPosition()
    }
  }

  private func assertColdLaunchAndForegroundKeepRealGameInactiveAndFeedPosition() {
    let app = XCUIApplication()
    app.launchArguments = ["-sidequest-sudoku-test"]
    app.launch()
    XCTAssertTrue(app.buttons["sudoku.cell.2"].waitForExistence(timeout: 10))
    XCTAssertTrue(app.buttons["sudoku.cell.2"].isHittable)
    XCTAssertEqual(app.buttons["sudoku.cell.2"].value as? String, "Empty")
    XCTAssertTrue(app.buttons["sudoku.cell.2"].isEnabled)
    XCTAssertFalse(app.buttons["sudoku.cell.2"].isSelected)
    let selected = app.selectedFeedCardID
    XCUIDevice.shared.press(.home)
    app.activate()
    XCTAssertTrue(app.buttons["sudoku.cell.2"].waitForExistence(timeout: 5))
    XCTAssertEqual(app.selectedFeedCardID, selected)
    XCTAssertTrue(app.buttons["sudoku.cell.2"].isEnabled)
    app.buttons["sudoku.cell.2"].tap()
    XCTAssertTrue(app.buttons["sudoku.cell.2"].isSelected)
    app.buttons["sudoku.number.3"].tap()
    XCTAssertEqual(app.buttons["sudoku.cell.2"].value as? String, "3")
    XCTAssertEqual(app.selectedFeedCardID, selected)
  }
}
