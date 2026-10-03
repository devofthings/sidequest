import XCTest

@MainActor
final class NewsPresentationTests: XCTestCase {
  func testOfflineSampleShowsSourceDateLabelAndImportPicker() {
    let app = XCUIApplication()
    app.launchArguments = ["-sidequest-news-preview", "-sidequest-news-fixtures"]
    app.launch()
    let read = app.buttons["foundation.news"]
    XCTAssertTrue(read.waitForExistence(timeout: 10))
    read.tap()
    XCTAssertTrue(app.staticTexts["news.sample"].firstMatch.waitForExistence(timeout: 10))
    XCTAssertTrue(app.staticTexts["news.captured"].firstMatch.exists)
    let source = app.links["news.source"].firstMatch
    XCTAssertTrue(source.exists)
    XCTAssertEqual(source.label, "Read original article from Sidequest sample")
    let importer = app.buttons["news.import"]
    XCTAssertTrue(importer.exists)
    importer.tap()
    XCTAssertTrue(app.buttons["Cancel"].waitForExistence(timeout: 5))
    app.buttons["Cancel"].tap()
    XCTAssertTrue(app.buttons["news.import"].exists)
    app.buttons["Done"].tap()
    XCTAssertTrue(read.exists)
  }
}
