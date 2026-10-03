import XCTest

@MainActor
final class MemoryFlowTests: XCTestCase {
  func testStartMakesNoFlipAndMatchingAllPairsRetainsCompletion() {
    let app = launch()
    XCTAssertTrue(app.buttons["game.start"].exists)
    XCTAssertFalse(app.buttons["memory.tile.0"].exists)
    app.buttons["game.start"].tap()
    XCTAssertEqual(app.buttons["memory.tile.0"].label, "Hidden card 1")
    XCTAssertEqual(app.staticTexts["memory.progress"].label, "0 of 6 pairs matched")
    app.buttons["memory.tile.0"].tap()
    XCTAssertEqual(app.buttons["memory.tile.0"].label, "Revealed star, card 1")
    app.buttons["memory.tile.0"].tap()
    app.buttons["memory.tile.1"].tap()
    XCTAssertEqual(app.buttons["memory.tile.0"].label, "Matched star, card 1")
    XCTAssertFalse(app.buttons["memory.tile.0"].isEnabled)
    for index in 2..<12 { tapTile(index, app: app) }
    XCTAssertTrue(app.staticTexts["memory.completed"].waitForExistence(timeout: 5))
    app.buttons["feed.next"].tap()
    app.buttons["feed.previous"].tap()
    XCTAssertTrue(app.staticTexts["memory.completed"].exists)
    XCTAssertFalse(app.buttons["game.start"].exists)
    XCTAssertEqual(app.staticTexts["memory.progress"].label, "6 of 6 pairs matched")
  }

  func testMismatchTurnsOverAndSkippingReturnsToUnflippedPreview() {
    let app = launch()
    app.buttons["game.start"].tap()
    app.buttons["memory.tile.0"].tap()
    app.buttons["memory.tile.2"].tap()
    let first = app.buttons["memory.tile.0"]
    let third = app.buttons["memory.tile.2"]
    let concealed = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "label == %@", "Hidden card 1"), object: first)
    XCTAssertEqual(XCTWaiter.wait(for: [concealed], timeout: 5), .completed)
    XCTAssertEqual(third.label, "Hidden card 3")
    first.tap()
    third.tap()
    app.buttons["feed.next"].tap()
    app.buttons["feed.previous"].tap()
    XCTAssertTrue(app.buttons["game.start"].exists)
    XCTAssertFalse(app.buttons["memory.tile.0"].exists)
    app.buttons["game.start"].tap()
    XCTAssertEqual(app.buttons["memory.tile.0"].label, "Hidden card 1")
    XCTAssertEqual(app.buttons["memory.tile.2"].label, "Hidden card 3")
    XCTAssertEqual(app.staticTexts["memory.progress"].label, "0 of 6 pairs matched")
  }

  func testLargestTextKeepsEveryTileAndNavigationReachable() {
    let app = launch(largeText: true)
    XCTAssertTrue(app.buttons["game.start"].isHittable)
    app.buttons["game.start"].tap()
    for index in 0..<12 { tapTile(index, app: app) }
    XCTAssertTrue(app.staticTexts["memory.completed"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.buttons["feed.next"].isHittable)
    app.buttons["feed.next"].tap()
    XCTAssertTrue(app.buttons["feed.previous"].isHittable)
    app.buttons["feed.previous"].tap()
    XCTAssertEqual(app.staticTexts["memory.progress"].label, "6 of 6 pairs matched")
  }

  private func tapTile(_ index: Int, app: XCUIApplication) {
    let tile = app.buttons["memory.tile.\(index)"]
    for _ in 0..<8 where !tile.isHittable {
      app.scrollViews.firstMatch.swipeUp()
    }
    XCTAssertTrue(tile.isHittable, "Card \(index + 1) must be reachable.")
    tile.tap()
  }

  private func launch(largeText: Bool = false) -> XCUIApplication {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments =
      ["-sidequest-memory-fixtures"]
      + (largeText ? ["-sidequest-large-text"] : [])
    app.launch()
    XCTAssertTrue(app.buttons["game.start"].waitForExistence(timeout: 5))
    return app
  }
}
