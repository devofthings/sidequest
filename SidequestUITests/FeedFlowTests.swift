import XCTest

final class FeedFlowTests: XCTestCase {
  @MainActor
  func testStartConsumesNoMoveAndSkippingRequiresFreshStart() {
    let app = launch()
    XCTAssertTrue(app.buttons["game.start"].waitForExistence(timeout: 5))
    XCTAssertFalse(app.buttons["game.interact"].exists)
    app.nextFeedCard()
    app.previousFeedCard()
    XCTAssertTrue(app.buttons["game.start"].exists)
    for _ in 0..<2 {
      app.buttons["game.start"].tap()
      XCTAssertEqual(app.staticTexts["game.interactions"].label, "Interactions: 0")
      app.buttons["game.interact"].tap()
      XCTAssertEqual(app.staticTexts["game.interactions"].label, "Interactions: 1")
      app.nextFeedCard()
      XCTAssertTrue(app.buttons["game.start"].exists)
      app.previousFeedCard()
      XCTAssertTrue(app.buttons["game.start"].exists)
    }
    app.buttons["game.start"].tap()
    XCTAssertEqual(app.staticTexts["game.interactions"].label, "Interactions: 0")
  }

  @MainActor
  func testCompletedStateSurvivesOtherCardsAndViewRecomputation() {
    let app = launch()
    app.buttons["game.start"].tap()
    app.buttons["game.interact"].tap()
    app.buttons["game.complete"].tap()
    XCTAssertTrue(app.staticTexts["game.completed"].exists)
    app.nextFeedCard()
    app.buttons["game.start"].tap()
    XCTAssertEqual(app.staticTexts["game.interactions"].label, "Interactions: 0")
    app.previousFeedCard()
    XCTAssertTrue(app.staticTexts["game.completed"].exists)
    XCTAssertEqual(app.staticTexts["game.interactions"].label, "Interactions: 1")
    XCTAssertFalse(app.buttons["game.start"].exists)
  }

  @MainActor
  func testBackgroundStopsAnUnfinishedGame() {
    let app = launch()
    app.buttons["game.start"].tap()
    app.buttons["game.interact"].tap()
    XCUIDevice.shared.press(.home)
    app.activate()
    XCTAssertTrue(app.buttons["game.start"].waitForExistence(timeout: 5))
    app.buttons["game.start"].tap()
    XCTAssertEqual(app.staticTexts["game.interactions"].label, "Interactions: 0")
  }

  @MainActor
  func testLargestTextKeepsStartAndNavigationReachable() {
    let app = launch(largeText: true)
    XCTAssertTrue(app.buttons["game.start"].isHittable)
    XCTAssertTrue(app.buttons["feed.navigation"].isHittable)
    app.nextFeedCard()
    XCTAssertTrue(app.buttons["feed.navigation"].isHittable)
    app.previousFeedCard()
    XCTAssertTrue(app.buttons["game.start"].isHittable)
    XCTAssertEqual(app.staticTexts["feed.position"].label, "Card 1 of 6")
  }

  @MainActor
  func testNewsCardsKeepProvenanceWhileNavigatingTheMixedFeed() {
    let app = launch()
    for _ in 0..<4 { app.nextFeedCard() }
    XCTAssertEqual(app.staticTexts["feed.position"].label, "Card 5 of 6")
    XCTAssertTrue(app.staticTexts["news.sample"].exists)
    XCTAssertTrue(app.staticTexts["news.captured"].exists)
    XCTAssertTrue(app.links["news.source"].exists)
    XCTAssertFalse(app.buttons["game.start"].exists)
    app.nextFeedCard()
    XCTAssertTrue(app.staticTexts["news.sample"].exists)
    XCTAssertTrue(app.links["news.source"].exists)
    app.previousFeedCard()
    app.previousFeedCard()
    XCTAssertTrue(app.buttons["game.start"].exists)
  }

  @MainActor
  func testEmptyAndGamesOnlySessionsHaveUsableBoundaries() {
    let empty = launch(argument: "-sidequest-feed-empty")
    XCTAssertTrue(empty.staticTexts["No cards yet"].waitForExistence(timeout: 5))
    XCTAssertFalse(empty.buttons["game.start"].exists)
    empty.terminate()
    let games = launch(argument: "-sidequest-feed-games-only")
    XCTAssertTrue(games.buttons["game.start"].waitForExistence(timeout: 5))
    games.buttons["feed.navigation"].tap()
    XCTAssertFalse(games.buttons["feed.previous"].isEnabled)
    games.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.1)).tap()
    for _ in 0..<3 { games.nextFeedCard() }
    games.buttons["feed.navigation"].tap()
    XCTAssertFalse(games.buttons["feed.next"].isEnabled)
    games.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.1)).tap()
    XCTAssertTrue(games.staticTexts["feed.position"].label.hasPrefix("End of feed"))
    games.previousFeedCard()
    games.buttons["feed.navigation"].tap()
    XCTAssertTrue(games.buttons["feed.next"].isEnabled)
    games.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.1)).tap()
  }

  @MainActor
  private func launch(argument: String = "-sidequest-feed-test", largeText: Bool = false)
    -> XCUIApplication
  {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = [argument] + (largeText ? ["-sidequest-large-text"] : [])
    app.launch()
    XCTAssertTrue(app.staticTexts["foundation.title"].waitForExistence(timeout: 5))
    return app
  }
}
