import XCTest

@MainActor
final class FirstInteractionFlowTests: XCTestCase {
  func testFirstActionAppliesAcrossAllGamesAndSkippingResets() {
    continueAfterFailure = false
    for fixture in [
      "-sidequest-sudoku-test", "-sidequest-memory-fixtures",
      "-sidequest-chess-white-fixture", "-sidequest-chess-black-fixture",
      "-sidequest-bubble-fixtures",
    ] {
      let app = XCUIApplication()
      app.launchArguments = [fixture]
      app.launch()
      XCTAssertTrue(app.staticTexts["foundation.title"].waitForExistence(timeout: 10))
      let title =
        fixture.contains("sudoku")
        ? "Sudoku"
        : fixture.contains("memory")
          ? "Memory"
          : fixture.contains("chess") ? "Chess puzzle" : "Bubble shooter"
      let header = app.staticTexts["foundation.title"]
      XCTAssertEqual(header.label, title)
      XCTAssertEqual(app.staticTexts.matching(NSPredicate(format: "label == %@", title)).count, 1)
      let headerY = header.frame.minY
      let navigationFrame = app.buttons["feed.navigation"].frame
      XCTAssertFalse(app.buttons["game.start"].exists)
      if fixture.contains("sudoku") {
        let cell = app.buttons["sudoku.cell.2"]
        XCTAssertTrue(cell.isEnabled)
        cell.tap()
        XCTAssertTrue(cell.isSelected)
        XCTAssertTrue(app.buttons["sudoku.number.3"].isEnabled)
        app.buttons["sudoku.number.3"].tap()
        XCTAssertEqual(cell.value as? String, "3")
      } else if fixture.contains("memory") {
        let card = app.buttons["memory.tile.0"]
        XCTAssertTrue(card.isEnabled)
        card.tap()
        XCTAssertFalse(card.label.contains("Hidden"))
      } else if fixture.contains("chess") {
        let queen = app.buttons.matching(
          NSPredicate(format: "identifier BEGINSWITH %@", "chess.piece.")
        ).firstMatch
        XCTAssertTrue(queen.isEnabled)
        queen.tap()
        XCTAssertTrue(app.staticTexts["chess.selection"].label.hasPrefix("Selected:"))
      } else {
        XCTAssertTrue(app.sliders["bubble.aim"].isEnabled)
        app.sliders["bubble.aim"].adjust(toNormalizedSliderPosition: 0.75)
        XCTAssertEqual(app.staticTexts["bubble.shots"].label, "Shots: 0 of 8")
        XCTAssertTrue(app.buttons["bubble.fire"].isEnabled)
      }
      XCTAssertEqual(header.frame.minY, headerY)
      XCTAssertEqual(app.buttons["feed.navigation"].frame, navigationFrame)
      app.nextFeedCard()
      XCTAssertEqual(header.frame.minY, headerY)
      XCTAssertEqual(app.buttons["feed.navigation"].frame, navigationFrame)
      app.previousFeedCard()
      XCTAssertEqual(header.label, title)
      XCTAssertEqual(header.frame.minY, headerY)
      XCTAssertEqual(app.buttons["feed.navigation"].frame, navigationFrame)
      XCTAssertFalse(app.buttons["game.start"].exists)
      if fixture.contains("sudoku") {
        XCTAssertEqual(app.buttons["sudoku.cell.2"].value as? String, "Empty")
        XCTAssertFalse(app.buttons["sudoku.number.3"].isEnabled)
      } else if fixture.contains("memory") {
        XCTAssertTrue(app.buttons["memory.tile.0"].label.contains("Hidden"))
      } else if fixture.contains("chess") {
        XCTAssertEqual(app.staticTexts["chess.selection"].label, "No piece selected")
      } else {
        let resetValue = (app.sliders["bubble.aim"].value as? String)?.filter {
          !$0.isWhitespace
        }
        XCTAssertEqual(resetValue, "50%")
      }
      app.terminate()
    }
  }

  func testFirstFireShootsAndBackgroundReturnsToInactiveBoard() {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["-sidequest-bubble-fixtures"]
    app.launch()
    XCTAssertTrue(app.buttons["bubble.fire"].waitForExistence(timeout: 10))
    XCTAssertFalse(app.buttons["game.start"].exists)
    app.buttons["bubble.fire"].tap()
    XCTAssertTrue(
      app.staticTexts["bubble.feedback"].label == "Shot in flight."
        || app.staticTexts["bubble.shots"].label != "Shots: 0 of 8")
    XCUIDevice.shared.press(.home)
    app.activate()
    XCTAssertTrue(app.buttons["bubble.fire"].waitForExistence(timeout: 5))
    XCTAssertEqual(app.staticTexts["bubble.shots"].label, "Shots: 0 of 8")
  }
}
