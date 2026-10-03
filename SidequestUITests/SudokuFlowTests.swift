import XCTest

final class SudokuFlowTests: XCTestCase {
  @MainActor
  func testTapStartsOnlyAndCorrectionsResetAfterSkipping() {
    let app = launch()
    XCTAssertFalse(app.buttons["sudoku.cell.2"].exists)
    app.buttons["game.start"].tap()
    XCTAssertEqual(app.buttons["sudoku.cell.2"].value as? String, "Empty")
    XCTAssertFalse(app.buttons["sudoku.number.3"].isEnabled)
    app.buttons["sudoku.cell.2"].tap()
    app.buttons["sudoku.number.1"].tap()
    XCTAssertTrue(app.staticTexts["sudoku.status"].label.contains("Conflicts"))
    XCTAssertTrue((app.buttons["sudoku.cell.2"].value as? String)?.contains("conflict") == true)
    app.buttons["sudoku.number.3"].tap()
    XCTAssertEqual(app.buttons["sudoku.cell.2"].value as? String, "3")
    app.buttons["sudoku.clear"].tap()
    XCTAssertEqual(app.buttons["sudoku.cell.2"].value as? String, "Empty")
    app.buttons["sudoku.number.3"].tap()
    app.nextFeedCard()
    app.previousFeedCard()
    XCTAssertTrue(app.buttons["game.start"].exists)
    app.buttons["game.start"].tap()
    XCTAssertEqual(app.buttons["sudoku.cell.2"].value as? String, "Empty")
    XCTAssertFalse(app.buttons["sudoku.number.3"].isEnabled)
  }

  @MainActor
  func testNormalControlsHaveFullTouchAreasAndCellCornersSelect() {
    let app = launch()
    app.buttons["game.start"].tap()
    let cell = app.buttons["sudoku.cell.2"]
    reveal(cell, in: app, upwards: true)
    XCTAssertGreaterThanOrEqual(cell.frame.width + 0.001, 44)
    XCTAssertGreaterThanOrEqual(cell.frame.height + 0.001, 44)
    for point in [(0.1, 0.1), (0.9, 0.1), (0.1, 0.9), (0.9, 0.9)] {
      app.buttons["sudoku.cell.4"].tap()
      cell.coordinate(withNormalizedOffset: CGVector(dx: point.0, dy: point.1)).tap()
      XCTAssertTrue(cell.isSelected)
      XCTAssertTrue(app.buttons["sudoku.number.3"].isEnabled)
    }
    for value in 1...4 {
      let number = app.buttons["sudoku.number.\(value)"]
      reveal(number, in: app, upwards: true)
      XCTAssertGreaterThanOrEqual(number.frame.width + 0.001, 44)
      XCTAssertGreaterThanOrEqual(number.frame.height + 0.001, 44)
    }
    let clear = app.buttons["sudoku.clear"]
    reveal(clear, in: app, upwards: true)
    XCTAssertGreaterThanOrEqual(clear.frame.width + 0.001, 44)
    XCTAssertGreaterThanOrEqual(clear.frame.height + 0.001, 44)
    XCTAssertFalse(app.buttons["sudoku.cell.0"].isEnabled)
    capture(app, name: "normal-full-touch-controls")
  }

  @MainActor
  func testSolvedBoardRemainsOnCardAndSurvivesRevisit() {
    let app = launch()
    app.buttons["game.start"].tap()
    for (cell, value) in [(2, 3), (4, 3), (7, 2), (8, 2), (11, 3), (13, 3), (14, 2)] {
      app.buttons["sudoku.cell.\(cell)"].tap()
      app.buttons["sudoku.number.\(value)"].tap()
    }
    XCTAssertEqual(app.staticTexts["sudoku.status"].label, "Sudoku solved!")
    XCTAssertEqual(app.staticTexts["feed.position"].label, "Card 1 of 2")
    app.nextFeedCard()
    app.previousFeedCard()
    XCTAssertEqual(app.staticTexts["sudoku.status"].label, "Sudoku solved!")
    XCTAssertFalse(app.buttons["game.start"].exists)
    XCTAssertFalse(app.buttons["sudoku.cell.2"].isEnabled)
  }

  @MainActor
  func testLargestTextKeepsBoardAndInputUsable() {
    let app = launch(largeText: true)
    XCTAssertTrue(app.buttons["game.start"].isHittable)
    app.buttons["game.start"].tap()
    let cell = app.buttons["sudoku.cell.2"]
    reveal(cell, in: app, upwards: true)
    XCTAssertTrue(cell.isHittable)
    cell.tap()
    capture(app, name: "cell-selected")
    XCTAssertTrue(cell.isSelected)
    let number = app.buttons["sudoku.number.3"]
    reveal(number, in: app, upwards: true)
    XCTAssertTrue(number.isHittable)
    capture(app, name: "number-visible")
    XCTAssertTrue(number.isEnabled)
    number.tap()
    capture(app, name: "number-tapped")
    reveal(cell, in: app, upwards: false)
    XCTAssertEqual(cell.value as? String, "3")
    XCTAssertTrue(app.buttons["feed.navigation"].isHittable)
    app.nextFeedCard()
    XCTAssertTrue(app.buttons["feed.navigation"].isHittable)
  }

  @MainActor
  private func reveal(_ element: XCUIElement, in app: XCUIApplication, upwards: Bool) {
    let scroll = app.scrollViews["feed.cardScroll"]
    for _ in 0..<18 {
      if element.exists && element.isHittable && scroll.frame.contains(element.frame) { return }
      let start = scroll.coordinate(
        withNormalizedOffset: CGVector(dx: 0.5, dy: upwards ? 0.65 : 0.35))
      let end = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: upwards ? 0.4 : 0.6))
      start.press(forDuration: 0.1, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.1)
    }
    XCTAssertTrue(
      scroll.frame.contains(element.frame), "The control must be fully visible before tapping.")
  }

  @MainActor
  private func capture(_ app: XCUIApplication, name: String) {
    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }

  @MainActor
  private func launch(largeText: Bool = false) -> XCUIApplication {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["-sidequest-sudoku-test"] + (largeText ? ["-sidequest-large-text"] : [])
    app.launch()
    XCTAssertTrue(app.buttons["game.start"].waitForExistence(timeout: 5))
    return app
  }
}
