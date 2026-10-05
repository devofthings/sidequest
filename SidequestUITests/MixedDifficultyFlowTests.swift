import XCTest

@MainActor
final class MixedDifficultyFlowTests: XCTestCase {
  func testAllTwelveGameTierCombinationsHaveFrozenAccessibleLabelsAndRealControls() {
    continueAfterFailure = false
    let app = launch()
    let names = ["Easy", "Medium", "Hard"]
    var newsCount = 0
    for index in 0..<12 {
      while !app.selectedFeedCardID.hasPrefix("game-") {
        XCTAssertFalse(app.staticTexts["game.difficulty"].exists)
        XCTAssertTrue(app.staticTexts["news.sample"].exists)
        newsCount += 1
        app.nextFeedCard()
      }
      XCTAssertTrue(app.selectedFeedCardID.hasSuffix("-\(index)"))
      let tier = names[(index / 4 + (201 + index % 4) % 3) % 3]
      let label = app.staticTexts["game.difficulty"]
      XCTAssertTrue(label.waitForExistence(timeout: 5))
      XCTAssertEqual(label.label, "Difficulty: \(tier)")
      XCTAssertTrue(app.staticTexts["game.heading"].exists)
      XCTAssertFalse(app.buttons["game.start"].exists)
      switch index % 4 {
      case 0: XCTAssertTrue(app.otherElements["sudoku.board"].exists)
      case 1:
        let pairs = tier == "Easy" ? 3 : (tier == "Medium" ? 4 : 6)
        XCTAssertTrue(app.staticTexts["Find all \(pairs) pairs."].exists)
        XCTAssertTrue(app.buttons["memory.tile.0"].isEnabled)
        XCTAssertEqual(app.buttons["memory.tile.0"].label, "Hidden card 1")
        app.buttons["memory.tile.0"].tap()
        XCTAssertTrue(app.buttons["memory.tile.0"].label.hasPrefix("Revealed "))
        app.nextFeedCard()
        app.previousFeedCard()
        XCTAssertEqual(app.staticTexts["game.difficulty"].label, "Difficulty: \(tier)")
        XCTAssertEqual(app.buttons["memory.tile.0"].label, "Hidden card 1")
      case 2: XCTAssertTrue(app.staticTexts["chess.focus"].exists)
      default:
        XCTAssertTrue(app.buttons["bubble.fire"].exists)
        XCTAssertTrue(app.buttons["bubble.fire"].isEnabled)
        XCTAssertTrue(app.staticTexts["bubble.shots"].exists)
      }
      app.nextFeedCard()
    }
    XCTAssertEqual(newsCount, 2, "The existing five-game/news cadence must remain unchanged.")
    app.terminate()
  }

  func testHardestGamesAtLargestTextKeepLabelAndPrimaryControlsStableDuringInput() {
    continueAfterFailure = false
    let app = launch(extra: ["-sidequest-large-text"])
    let hardIndices = [2, 5, 8, 11]
    for index in 0...11 {
      while !app.selectedFeedCardID.hasPrefix("game-") { app.nextFeedCard() }
      if hardIndices.contains(index) {
        XCTAssertEqual(app.staticTexts["game.difficulty"].label, "Difficulty: Hard")
        let control: XCUIElement
        switch index % 4 {
        case 0: control = app.buttons["sudoku.number.9"]
        case 1: control = app.buttons["memory.tile.0"]
        case 2: control = app.buttons["chess.submit"]
        default: control = app.buttons["bubble.fire"]
        }
        reveal(control, app: app)
        XCTAssertTrue(control.exists)
        XCTAssertTrue(control.isHittable)
        XCTAssertGreaterThanOrEqual(control.frame.height, 44)
        let frame = control.frame
        if index % 4 == 1 { control.tap() }
        XCTAssertEqual(control.frame.minY, frame.minY, accuracy: 1)
        XCTAssertEqual(app.staticTexts["game.difficulty"].label, "Difficulty: Hard")
      }
      app.nextFeedCard()
    }
    app.terminate()
  }

  private func launch(extra: [String] = []) -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments = ["-sidequest-mixed-difficulties-test"] + extra
    app.launch()
    XCTAssertTrue(app.buttons["feed.navigation"].waitForExistence(timeout: 10))
    return app
  }

  private func reveal(_ element: XCUIElement, app: XCUIApplication) {
    let viewport = app.scrollViews["feed.pager"].frame
    for _ in 0..<12 {
      if element.exists, element.isHittable,
        element.frame.minY >= viewport.minY, element.frame.maxY <= viewport.maxY
      {
        return
      }
      let start = app.coordinate(withNormalizedOffset: .zero).withOffset(
        CGVector(dx: viewport.minX + 8, dy: viewport.minY + viewport.height * 0.85))
      let end = app.coordinate(withNormalizedOffset: .zero).withOffset(
        CGVector(dx: viewport.minX + 8, dy: viewport.minY + viewport.height * 0.25))
      start.press(forDuration: 0.1, thenDragTo: end)
    }
    XCTFail("Primary control was not reachable within the owned content scroller")
  }
}
