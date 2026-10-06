import XCTest

@MainActor
final class LiveNewsFlowTests: XCTestCase {
  func testImageCreditAndForegroundRefreshKeepSelectedCard() {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["-sidequest-tagesschau-fixtures"]
    app.launch()
    XCTAssertTrue(app.selectedFeedCard.waitForExistence(timeout: 10))
    let selected = app.selectedFeedCardID
    app.openNewsLibrary()
    let headline = app.staticTexts["news.headline"].firstMatch
    XCTAssertTrue(headline.waitForExistence(timeout: 10))
    let before = headline.label
    XCTAssertTrue(
      app.staticTexts["news.imageCredit"].firstMatch.label.contains("Sidequest test artwork"))
    XCTAssertTrue(app.images["news.imageLoaded"].firstMatch.waitForExistence(timeout: 10))
    XCTAssertTrue(app.links["news.source"].firstMatch.exists)
    XCTAssertFalse(app.staticTexts["news.sample"].firstMatch.exists)
    XCUIDevice.shared.press(.home)
    app.activate()
    let updated = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "label != %@ AND exists == true", before), object: headline)
    XCTAssertEqual(XCTWaiter.wait(for: [updated], timeout: 10), .completed)
    app.buttons["news.done"].tap()
    app.waitForFeedCard(selected)
  }

  func testFailedRefreshAndImageKeepReadableArticle() {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = [
      "-sidequest-tagesschau-fixtures",
      "-sidequest-tagesschau-refresh-failure", "-sidequest-tagesschau-image-failure",
    ]
    app.launch()
    XCTAssertTrue(app.selectedFeedCard.waitForExistence(timeout: 10))
    app.openNewsLibrary()
    let headline = app.staticTexts["news.headline"].firstMatch
    XCTAssertTrue(headline.waitForExistence(timeout: 10))
    let before = headline.label
    XCUIDevice.shared.press(.home)
    app.activate()
    let message = app.staticTexts["news.message"]
    XCTAssertTrue(message.waitForExistence(timeout: 10))
    XCTAssertTrue(message.label.contains("latest articles"))
    XCTAssertEqual(headline.label, before)
    XCTAssertTrue(app.links["news.source"].firstMatch.exists)
    XCTAssertTrue(app.staticTexts["news.imageCredit"].firstMatch.exists)
    XCTAssertFalse(app.images["news.imageLoaded"].firstMatch.exists)
  }
}
