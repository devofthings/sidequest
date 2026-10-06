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
      XCTAssertTrue(app.staticTexts["foundation.title"].exists)
      XCTAssertFalse(app.buttons["game.start"].exists)
      switch index % 4 {
      case 0:
        XCTAssertTrue(app.otherElements["sudoku.board"].exists)
        let editable = app.buttons.matching(
          NSPredicate(
            format: "identifier BEGINSWITH %@ AND value == %@", "sudoku.cell.", "Empty")
        ).firstMatch
        XCTAssertTrue(editable.exists)
        editable.tap()
        XCTAssertTrue(
          editable.isSelected, "First input must start and select the actual editable cell")
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
      case 2:
        XCTAssertTrue(app.staticTexts["chess.focus"].exists)
        let side = app.staticTexts["chess.side"].label.hasPrefix("White") ? "White" : "Black"
        let piece = app.buttons.matching(
          NSPredicate(
            format: "identifier BEGINSWITH %@ AND label BEGINSWITH[c] %@ AND label CONTAINS[c] %@",
            "chess.square.", side, "queen")
        ).firstMatch
        XCTAssertTrue(piece.exists)
        piece.tap()
        XCTAssertEqual(app.staticTexts["chess.selection"].label, "Selected: \(piece.label)")
      default:
        XCTAssertTrue(app.bubbleAim.exists)
        XCTAssertTrue(app.bubbleAim.isEnabled)
        let cap = tier == "Easy" ? 8 : (tier == "Medium" ? 5 : 3)
        XCTAssertEqual(app.staticTexts["bubble.shots"].label, "Shots: 0 of \(cap)")
        let aim = app.bubbleAim
        XCTAssertTrue(aim.exists)
        app.shootBubble(at: 0.6)
        XCTAssertNotEqual(aim.value as? String, "Aim: 0 degrees")
        let committed = XCTNSPredicateExpectation(
          predicate: NSPredicate(format: "label == %@", "Shots: 1 of \(cap)"),
          object: app.staticTexts["bubble.shots"])
        XCTAssertEqual(XCTWaiter.wait(for: [committed], timeout: 10), .completed)
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
        case 2:
          control =
            app.buttons.matching(
              NSPredicate(
                format: "identifier BEGINSWITH %@ AND label CONTAINS[c] %@", "chess.square.",
                "queen"
              )
            ).firstMatch
        default: control = app.bubbleAim
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
