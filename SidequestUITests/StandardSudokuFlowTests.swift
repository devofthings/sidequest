import XCTest

final class StandardSudokuFlowTests: XCTestCase {
  @MainActor
  func testStandardOverviewAndAllPrimaryControlsFitWithoutScrollingAndReset() {
    let app = launch()
    let board = app.otherElements["sudoku.board"]
    let viewport = app.scrollViews["feed.cardScroll"].frame
    XCTAssertEqual(
      app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'sudoku.cell.'")).count, 81)
    XCTAssertTrue(viewport.contains(board.frame))
    for id in ["sudoku.row", "sudoku.column", "sudoku.clear"]
      + (1...9).map({ "sudoku.number.\($0)" })
    {
      let control = app.buttons[id]
      XCTAssertTrue(viewport.contains(control.frame), "\(id) must fit without scrolling")
      XCTAssertGreaterThanOrEqual(control.frame.width, 44)
      XCTAssertGreaterThanOrEqual(control.frame.height, 44)
    }
    let initial = board.frame
    app.buttons["sudoku.cell.8"].tap()
    XCTAssertTrue(app.buttons["sudoku.cell.8"].isSelected)
    XCTAssertTrue(app.buttons["sudoku.number.9"].isEnabled, "First interaction selects the cell")
    XCTAssertEqual(board.frame, initial)
    select(row: 1, column: 9, in: app)
    app.buttons["sudoku.number.1"].tap()
    XCTAssertTrue(app.staticTexts["sudoku.status"].label.contains("Conflicts"))
    XCTAssertEqual(board.frame, initial)
    app.buttons["sudoku.number.9"].tap()
    XCTAssertEqual(app.buttons["sudoku.cell.8"].value as? String, "9")
    XCTAssertEqual(board.frame, initial)
    app.buttons["sudoku.clear"].tap()
    XCTAssertEqual(app.buttons["sudoku.cell.8"].value as? String, "Empty")
    app.buttons["sudoku.number.9"].tap()
    app.nextFeedCard()
    app.previousFeedCard()
    XCTAssertEqual(app.buttons["sudoku.cell.8"].value as? String, "Empty")
    XCTAssertFalse(app.buttons["sudoku.number.9"].isEnabled)
    screenshot(app, name: "standard-nine-pocket-overview")
  }

  @MainActor
  func testStandardRealCompletionRetainsTheNineByNineBoard() {
    let app = launch()
    let board = app.otherElements["sudoku.board"]
    let initial = board.frame
    for column in 1...9 {
      select(row: 1, column: column, in: app)
      app.buttons["sudoku.number.\(column)"].tap()
    }
    for (row, value) in [(2, 4), (3, 7), (4, 2)] {
      select(row: row, column: 1, in: app)
      app.buttons["sudoku.number.\(value)"].tap()
    }
    XCTAssertEqual(app.staticTexts["sudoku.status"].label, "Sudoku solved!")
    XCTAssertEqual(board.frame, initial)
    app.nextFeedCard()
    app.previousFeedCard()
    XCTAssertEqual(app.staticTexts["sudoku.status"].label, "Sudoku solved!")
    XCTAssertFalse(app.buttons["sudoku.row"].isEnabled)
    XCTAssertFalse(app.buttons["sudoku.number.9"].isEnabled)
    screenshot(app, name: "standard-nine-completed-revisit")
  }

  @MainActor
  func testLargestTextCoordinatesAndNineRemainReachableWithStableFeedback() {
    let app = launch(large: true)
    reveal(app.buttons["sudoku.column"], in: app, upward: true)
    select(row: 1, column: 9, in: app)
    reveal(app.buttons["sudoku.number.9"], in: app, upward: true)
    let number = app.buttons["sudoku.number.9"]
    XCTAssertGreaterThanOrEqual(number.frame.width, 44)
    XCTAssertGreaterThanOrEqual(number.frame.height, 44)
    let initial = number.frame
    number.tap()
    XCTAssertEqual(number.frame, initial)
    let clear = app.buttons["sudoku.clear"]
    reveal(clear, in: app, upward: true)
    XCTAssertGreaterThanOrEqual(clear.frame.width, 44)
    XCTAssertGreaterThanOrEqual(clear.frame.height, 44)
    let clearFrame = clear.frame
    clear.tap()
    XCTAssertEqual(clear.frame, clearFrame)
    reveal(number, in: app, upward: false)
    number.tap()
    screenshot(app, name: "standard-nine-largest-readable-controls")
    reveal(app.buttons["sudoku.cell.8"], in: app, upward: false)
    XCTAssertEqual(app.buttons["sudoku.cell.8"].value as? String, "9")
    screenshot(app, name: "standard-nine-largest-overview")
    app.nextFeedCard()
    app.previousFeedCard()
    XCTAssertEqual(app.buttons["sudoku.cell.8"].value as? String, "Empty")
  }

  @MainActor
  private func select(row: Int, column: Int, in app: XCUIApplication) {
    reveal(app.buttons["sudoku.row"], in: app, upward: false)
    app.buttons["sudoku.row"].tap()
    app.buttons["sudoku.row.\(row)"].tap()
    reveal(app.buttons["sudoku.column"], in: app, upward: true)
    app.buttons["sudoku.column"].tap()
    app.buttons["sudoku.column.\(column)"].tap()
  }

  @MainActor
  private func reveal(_ element: XCUIElement, in app: XCUIApplication, upward: Bool) {
    let scroll = app.scrollViews["feed.cardScroll"]
    for _ in 0..<18 {
      if element.exists && element.isHittable && scroll.frame.contains(element.frame) { return }
      // The card's left padding is outside native coordinate menus and the right scroll indicator.
      let horizontal = min(8, scroll.frame.width / 2) / scroll.frame.width
      let start = scroll.coordinate(
        withNormalizedOffset: CGVector(dx: horizontal, dy: upward ? 0.7 : 0.3))
      let end = scroll.coordinate(
        withNormalizedOffset: CGVector(dx: horizontal, dy: upward ? 0.4 : 0.6))
      start.press(forDuration: 0.1, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.1)
    }
    let hierarchy = XCTAttachment(string: app.debugDescription)
    hierarchy.name = "standard-nine-reveal-failure-hierarchy"
    hierarchy.lifetime = .keepAlways
    add(hierarchy)
    screenshot(app, name: "standard-nine-reveal-failure")
    XCTAssertTrue(
      scroll.frame.contains(element.frame),
      "Required target \(element.identifier) must be fully contained: target=\(element.frame), viewport=\(scroll.frame), selected=\(app.selectedFeedCardID), hittable=\(element.isHittable)"
    )
  }

  @MainActor
  private func launch(large: Bool = false) -> XCUIApplication {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments =
      ["-sidequest-standard-sudoku-test"] + (large ? ["-sidequest-large-text"] : [])
    app.launchWithManualFeed()
    XCTAssertTrue(app.buttons["sudoku.cell.8"].waitForExistence(timeout: 5))
    return app
  }

  @MainActor
  private func screenshot(_ app: XCUIApplication, name: String) {
    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }
}
