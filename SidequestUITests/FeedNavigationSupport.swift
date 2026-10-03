import XCTest

@MainActor
extension XCUIApplication {
  func nextFeedCard() { navigateFeed(using: "feed.next") }
  func previousFeedCard() { navigateFeed(using: "feed.previous") }

  private func navigateFeed(using identifier: String) {
    buttons["feed.navigation"].tap()
    let action = buttons[identifier]
    XCTAssertTrue(action.waitForExistence(timeout: 3))
    XCTAssertTrue(action.isEnabled)
    action.tap()
    XCTAssertTrue(buttons["feed.navigation"].waitForExistence(timeout: 3))
  }
}
