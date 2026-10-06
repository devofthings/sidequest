import XCTest

@MainActor
final class LiveNewsFlowTests: XCTestCase {
  func testImageCreditAndForegroundRefreshKeepSelectedCard() {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["-sidequest-tagesschau-fixtures"]
    app.launchWithManualFeed()
    XCTAssertTrue(app.selectedFeedCard.waitForExistence(timeout: 10))
    let selected = app.selectedFeedCardID
    app.openNewsLibrary()
    let headline = app.staticTexts["news.headline"].firstMatch
    XCTAssertTrue(headline.waitForExistence(timeout: 10), app.debugDescription)
    let before = headline.label
    XCTAssertTrue(
      app.staticTexts["news.imageCredit"].firstMatch.label.contains("Sidequest test artwork"))
    let image = app.images["news.image"].firstMatch
    let loaded = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "value == %@", "Image loaded"), object: image)
    XCTAssertEqual(XCTWaiter.wait(for: [loaded], timeout: 10), .completed)
    let screenshot = XCTAttachment(screenshot: app.screenshot())
    screenshot.name = "Original news image and attribution"
    screenshot.lifetime = .keepAlways
    add(screenshot)
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
    app.launchWithManualFeed()
    XCTAssertTrue(app.selectedFeedCard.waitForExistence(timeout: 10))
    app.openNewsLibrary()
    let headline = app.staticTexts["news.headline"].firstMatch
    XCTAssertTrue(headline.waitForExistence(timeout: 10), app.debugDescription)
    let before = headline.label
    XCUIDevice.shared.press(.home)
    app.activate()
    let message = app.staticTexts["news.message"]
    XCTAssertTrue(message.waitForExistence(timeout: 10))
    XCTAssertTrue(message.label.contains("latest articles"))
    XCTAssertEqual(headline.label, before)
    XCTAssertTrue(app.links["news.source"].firstMatch.exists)
    XCTAssertTrue(app.staticTexts["news.imageCredit"].firstMatch.exists)
    let image = app.images["news.image"].firstMatch
    let unavailable = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "value == %@", "Image unavailable"), object: image)
    XCTAssertEqual(XCTWaiter.wait(for: [unavailable], timeout: 10), .completed)
  }
}
