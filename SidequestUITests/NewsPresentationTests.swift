import XCTest

@MainActor
final class NewsPresentationTests: XCTestCase {
  func testOfflineSampleShowsSourceDateLabelAndImportPicker() {
    continueAfterFailure = false
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
    dismissNativeNewsPicker(app, doneIdentifier: "Done")
    XCTAssertTrue(app.staticTexts["news.sample"].firstMatch.exists)
    app.buttons["Done"].tap()
    XCTAssertTrue(read.waitForExistence(timeout: 5))
    XCTAssertTrue(read.isHittable)
  }
}

@MainActor
extension XCTestCase {
  func dismissNativeNewsPicker(_ app: XCUIApplication, doneIdentifier: String) {
    let browser = app.otherElements["Browse View (Picker)"]
    XCTAssertTrue(browser.waitForExistence(timeout: 5), app.debugDescription)
    let cancel = app.navigationBars["FullDocumentManagerViewControllerNavigationBar"]
      .buttons["Cancel"].firstMatch
    if !cancel.exists || !cancel.isHittable {
      // A restored folder can cover the host's Cancel element with its More button.
      // Browse returns to native Locations, which exposes a real Cancel button.
      let browse = app.tabBars["DOC.browsingModeTabBar"].buttons["Browse"]
      XCTAssertTrue(browse.isHittable, app.debugDescription)
      browse.tap()
    }
    let ready = expectation(
      for: NSPredicate { _, _ in cancel.exists && cancel.isHittable },
      evaluatedWith: app)
    wait(for: [ready], timeout: 5)
    let before = XCTAttachment(screenshot: app.screenshot())
    before.name = "Native Files visible Cancel"
    before.lifetime = .keepAlways
    add(before)
    let tree = XCTAttachment(string: app.debugDescription)
    tree.name = "Native Files visible Cancel accessibility"
    tree.lifetime = .keepAlways
    add(tree)
    cancel.tap()
    let dismissed = expectation(
      for: NSPredicate { _, _ in
        !browser.exists && app.buttons["news.import"].isHittable
          && app.buttons[doneIdentifier].isHittable
      }, evaluatedWith: app)
    wait(for: [dismissed], timeout: 5)
    let after = XCTAttachment(screenshot: app.screenshot())
    after.name = "News library after native Files cancellation"
    after.lifetime = .keepAlways
    add(after)
  }
}
