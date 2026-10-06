import XCTest

@MainActor
extension XCUIApplication {
  func nextFeedCard() { navigateFeed(forward: true) }
  func previousFeedCard() { navigateFeed(forward: false) }

  func openNewsLibrary(file: StaticString = #filePath, line: UInt = #line) {
    let menu = buttons["feed.navigation"]
    XCTAssertTrue(menu.waitForExistence(timeout: 5), file: file, line: line)
    menu.tap()
    let news = buttons["feed.news"]
    XCTAssertTrue(news.waitForExistence(timeout: 5), file: file, line: line)
    XCTAssertTrue(news.isEnabled, file: file, line: line)
    news.tap()
    XCTAssertTrue(buttons["news.import"].waitForExistence(timeout: 5), file: file, line: line)
  }

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

  /// Historical interaction journeys explicitly keep manual navigation; timer gets its own route.
  func launchWithManualFeed() {
    if !launchArguments.contains("-sidequest-disable-auto-continue") {
      launchArguments.append("-sidequest-disable-auto-continue")
    }
    launch()
  }

  private func navigateFeed(forward: Bool) {
    let previous = selectedFeedCardID
    let pager = scrollViews["feed.pager"]
    XCTAssertTrue(pager.exists)
    for _ in 0..<12 {
      let start = pager.coordinate(
        withNormalizedOffset: CGVector(dx: 0.01, dy: forward ? 0.85 : 0.15))
      let end = pager.coordinate(
        withNormalizedOffset: CGVector(dx: 0.01, dy: forward ? 0.15 : 0.85))
      start.press(forDuration: 0.01, thenDragTo: end, withVelocity: .fast, thenHoldForDuration: 0.1)
      if selectedFeedCardID != previous { return }
    }
    XCTFail("Physical swipe did not reach an adjacent card from \(previous)")
  }
}
