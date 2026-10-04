import XCTest

@MainActor
final class EndlessFlowTests: XCTestCase {
  func testGeneratedGamesCompleteResetAndRestoreAfterMultipleBatchesAndCanceledDrag() {
    let app = launch(extra: ["-sidequest-endless-slow-generation"])
    XCTAssertEqual(position(app), "Card 1")
    XCTAssertFalse(app.buttons["sudoku.cell.0"].exists)
    app.buttons["game.start"].tap()
    let solution = [3, 4, 1, 2, 1, 2, 3, 4, 2, 3, 4, 1, 4, 1, 2, 3]
    let givens = [4, 5, 8, 15]
    app.buttons["sudoku.cell.0"].tap()
    app.buttons["sudoku.number.3"].tap()
    app.nextFeedCard()
    app.previousFeedCard()
    XCTAssertTrue(app.buttons["game.start"].exists)
    app.buttons["game.start"].tap()
    XCTAssertEqual(app.buttons["sudoku.cell.0"].value as? String, "Empty")
    for index in 0..<16 where !givens.contains(index) {
      reveal(app.buttons["sudoku.cell.\(index)"], in: app)
      app.buttons["sudoku.cell.\(index)"].tap()
      reveal(app.buttons["sudoku.number.\(solution[index])"], in: app)
      app.buttons["sudoku.number.\(solution[index])"].tap()
    }
    XCTAssertEqual(app.staticTexts["sudoku.status"].label, "Sudoku solved!")
    app.nextFeedCard()
    app.buttons["game.start"].tap()
    // Seed104 freezes this original generated layout; no production layout is exposed to automation.
    for pair in [[0, 11], [1, 8], [2, 9], [3, 6], [4, 10], [5, 7]] {
      for index in pair {
        reveal(app.buttons["memory.tile.\(index)"], in: app)
        app.buttons["memory.tile.\(index)"].tap()
      }
    }
    XCTAssertTrue(app.staticTexts["memory.completed"].exists)
    app.nextFeedCard()
    app.buttons["game.start"].tap()
    reveal(app.buttons["chess.square.g6"], in: app)
    app.buttons["chess.square.g6"].tap()
    app.buttons["chess.square.g7"].tap()
    XCTAssertTrue(app.staticTexts["chess.completed"].exists)
    app.nextFeedCard()
    // This short native drag holds the finger while the off-actor replenishment finishes.
    let pager = app.scrollViews["feed.pager"]
    let origin = pager.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5))
    let nearby = pager.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.47))
    origin.press(forDuration: 5, thenDragTo: nearby, withVelocity: .slow, thenHoldForDuration: 0.3)
    XCTAssertEqual(position(app), "Card 4")
    XCTAssertTrue(app.buttons["game.start"].exists)
    app.buttons["game.start"].tap()
    reveal(app.sliders["bubble.aim"], in: app)
    app.sliders["bubble.aim"].adjust(toNormalizedSliderPosition: 0)
    reveal(app.buttons["bubble.fire"], in: app)
    app.buttons["bubble.fire"].tap()
    let won = expectation(
      for: NSPredicate(format: "label == %@", "You won!"),
      evaluatedWith: app.staticTexts["bubble.outcome"])
    wait(for: [won], timeout: 10)
    for _ in 0..<21 { app.nextFeedCard() }
    XCTAssertEqual(position(app), "Card 25")
    XCTAssertTrue(app.buttons["game.start"].exists)
    for _ in 0..<24 { app.previousFeedCard() }
    XCTAssertEqual(position(app), "Card 1")
    XCTAssertEqual(app.staticTexts["sudoku.status"].label, "Sudoku solved!")
    app.nextFeedCard()
    XCTAssertTrue(app.staticTexts["memory.completed"].exists)
    app.nextFeedCard()
    XCTAssertTrue(app.staticTexts["chess.completed"].exists)
    app.nextFeedCard()
    XCTAssertEqual(app.staticTexts["bubble.outcome"].label, "You won!")
    reveal(app.buttons["bubble.replay"], in: app)
    app.buttons["bubble.replay"].tap()
    XCTAssertEqual(app.staticTexts["bubble.shots"].label, "Shots: 0 of 8")
    reveal(app.buttons["bubble.fire"], in: app)
    app.buttons["bubble.fire"].tap()
    XCTAssertEqual(app.staticTexts["bubble.feedback"].label, "Shot in flight.")
    openLibrary(app)
    closeLibrary(app)
    XCTAssertTrue(app.buttons["game.start"].exists)
    app.buttons["game.start"].tap()
    XCTAssertEqual(app.staticTexts["bubble.shots"].label, "Shots: 0 of 8")
    XCUIDevice.shared.press(.home)
    app.activate()
    XCTAssertTrue(app.buttons["game.start"].waitForExistence(timeout: 5))
    app.terminate()
  }

  func testEndlessNativeImportsPersistAppearOnceAndKeepHistoryAfterRejectionOrCancel() {
    let app = launch()
    openLibrary(app)
    importFile("Valid News", in: app)
    waitForMessage("Imported 1 news snapshots.", in: app)
    closeLibrary(app)
    XCTAssertEqual(position(app), "Card 1")
    XCTAssertTrue(app.staticTexts["Imported fixture story"].exists)
    for _ in 0..<17 { app.nextFeedCard() }
    XCTAssertEqual(position(app), "Card 18")
    XCTAssertFalse(app.staticTexts["Imported fixture story"].exists)
    for name in ["Malformed News", "Collision News"] {
      openLibrary(app)
      importFile(name, in: app)
      let failed = expectation(
        for: NSPredicate(format: "label BEGINSWITH %@", "Import failed."),
        evaluatedWith: app.staticTexts["news.message"])
      wait(for: [failed], timeout: 5)
      closeLibrary(app)
      XCTAssertEqual(position(app), "Card 18")
    }
    openLibrary(app)
    app.buttons["news.import"].tap()
    dismissNativeNewsPicker(app, doneIdentifier: "news.done")
    closeLibrary(app)
    XCTAssertEqual(position(app), "Card 18")
    app.terminate()
    app.launchArguments = ["-sidequest-integration-fixtures", "-sidequest-endless-fixtures"]
    app.launch()
    XCTAssertTrue(app.staticTexts["Imported fixture story"].waitForExistence(timeout: 10))
    XCTAssertEqual(position(app), "Card 1")
    openLibrary(app)
    importFile("Empty News", in: app)
    waitForMessage("Imported 0 news snapshots.", in: app)
    closeLibrary(app)
    XCTAssertTrue(app.buttons["game.start"].exists)
    for _ in 0..<17 { app.nextFeedCard() }
    XCTAssertEqual(position(app), "Card 18")
    app.terminate()
    app.launch()
    XCTAssertTrue(app.buttons["game.start"].waitForExistence(timeout: 10))
    XCTAssertEqual(position(app), "Card 1")
    XCTAssertFalse(app.staticTexts["Imported fixture story"].exists)
    app.terminate()
  }

  func testLargestTextAndActualReduceMotionKeepEndlessPagingAndExplicitStartUsable() {
    SystemAccessibilitySupport.withReduceMotion {
      let app = launch(extra: ["-sidequest-large-text"])
      for identifier in ["feed.news", "feed.navigation", "game.start"] {
        XCTAssertTrue(app.buttons[identifier].isHittable)
        XCTAssertGreaterThanOrEqual(app.buttons[identifier].frame.width + 0.001, 44)
        XCTAssertGreaterThanOrEqual(app.buttons[identifier].frame.height + 0.001, 44)
      }
      for _ in 0..<17 { app.nextFeedCard() }
      XCTAssertEqual(position(app), "Card 18")
      app.buttons["game.start"].tap()
      reveal(app.buttons["memory.tile.0"], in: app)
      XCTAssertTrue(app.buttons["memory.tile.0"].isHittable)
      app.buttons["memory.tile.0"].tap()
      XCTAssertTrue(app.buttons["memory.tile.0"].label.hasPrefix("Revealed"))
      app.nextFeedCard()
      app.previousFeedCard()
      XCTAssertTrue(app.buttons["game.start"].isHittable)
      app.terminate()
    }
  }

  private func launch(extra: [String] = []) -> XCUIApplication {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments =
      [
        "-sidequest-integration-fixtures", "-sidequest-integration-reset",
        "-sidequest-endless-fixtures", "-sidequest-bubble-slow-shot",
      ] + extra
    app.launch()
    XCTAssertTrue(app.buttons["game.start"].waitForExistence(timeout: 10))
    return app
  }
  private func position(_ app: XCUIApplication) -> String { app.staticTexts["feed.position"].label }
  private func openLibrary(_ app: XCUIApplication) {
    app.buttons["feed.news"].tap()
    XCTAssertTrue(app.buttons["news.import"].waitForExistence(timeout: 5))
  }
  private func closeLibrary(_ app: XCUIApplication) {
    app.buttons["news.done"].tap()
    XCTAssertTrue(app.buttons["feed.news"].waitForExistence(timeout: 5))
  }
  private func waitForMessage(_ text: String, in app: XCUIApplication) {
    let message = expectation(
      for: NSPredicate(format: "label == %@", text),
      evaluatedWith: app.staticTexts["news.message"])
    wait(for: [message], timeout: 5)
  }
  private func importFile(_ name: String, in app: XCUIApplication) {
    app.buttons["news.import"].tap()
    let browser = app.otherElements["Browse View (Picker)"]
    XCTAssertTrue(browser.waitForExistence(timeout: 5))
    let file = browser.collectionViews["File View"].cells.matching(
      NSPredicate(format: "label BEGINSWITH %@ OR identifier BEGINSWITH %@", name, name)
    ).firstMatch
    if !file.exists {
      if app.buttons["Browse"].exists { app.buttons["Browse"].tap() }
      if app.buttons["Browse"].exists && !app.staticTexts["On My iPhone"].exists {
        app.buttons["Browse"].tap()
      }
      if browser.cells["DOC.sidebar.item.On My iPhone"].exists {
        browser.cells["DOC.sidebar.item.On My iPhone"].tap()
      }
      for folder in ["Sidequest", "Sidequest Fixtures"] {
        if file.exists { break }
        let cell = browser.collectionViews["File View"].cells.matching(
          NSPredicate(
            format: "label BEGINSWITH %@ OR identifier BEGINSWITH %@", folder + ",", folder + ",")
        ).firstMatch
        if cell.waitForExistence(timeout: 3) {
          cell.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25)).tap()
        }
      }
    }
    XCTAssertTrue(file.waitForExistence(timeout: 5), app.debugDescription)
    file.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25)).tap()
    XCTAssertTrue(app.buttons["news.import"].waitForExistence(timeout: 5))
  }
  private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
    let scroll = app.scrollViews["feed.cardScroll"]
    for _ in 0..<40 {
      if element.exists, element.isHittable, scroll.frame.contains(element.frame) { return }
      let up = element.frame.midY > scroll.frame.midY
      let start = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: up ? 0.75 : 0.25))
      let end = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: up ? 0.25 : 0.75))
      start.press(forDuration: 0.01, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.1)
    }
    XCTAssertTrue(scroll.frame.contains(element.frame))
    XCTAssertTrue(element.isHittable)
  }
}
