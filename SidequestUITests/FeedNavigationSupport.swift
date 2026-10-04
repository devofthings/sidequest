import XCTest

@MainActor
extension XCUIApplication {
  func nextFeedCard() { navigateFeed(using: "feed.next") }
  func previousFeedCard() { navigateFeed(using: "feed.previous") }

  var selectedFeedCard: XCUIElement {
    otherElements.matching(NSPredicate(format: "identifier BEGINSWITH %@", "feed.selected."))
      .firstMatch
  }

  var selectedFeedCardID: String {
    String(selectedFeedCard.identifier.dropFirst("feed.selected.".count))
  }

  func waitForFeedCard(_ id: String, file: StaticString = #filePath, line: UInt = #line) {
    let card = otherElements["feed.selected.\(id)"]
    if card.exists { return }
    XCTAssertTrue(
      card.waitForExistence(timeout: 10),
      "Expected settled card \(id)", file: file, line: line)
  }

  private func navigateFeed(using identifier: String) {
    let previous = selectedFeedCard.identifier
    buttons["feed.navigation"].tap()
    let action = buttons[identifier]
    XCTAssertTrue(action.exists || action.waitForExistence(timeout: 3))
    XCTAssertTrue(action.isEnabled)
    action.tap()
    XCTAssertTrue(
      buttons["feed.navigation"].exists
        || buttons["feed.navigation"].waitForExistence(timeout: 3))
    if selectedFeedCard.exists, selectedFeedCard.identifier != previous { return }
    let settled = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "exists == true AND identifier != %@", previous),
      object: selectedFeedCard)
    XCTAssertEqual(XCTWaiter.wait(for: [settled], timeout: 10), .completed)
  }
}
