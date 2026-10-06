import XCTest

@MainActor
final class EndlessFlowTests: XCTestCase {
  func testGeneratedPreviewInputSkipAndFirstNewsBoundary() {
    let app = launch()
    app.waitForFeedCard(gameID(0))
    XCTAssertTrue(app.buttons["sudoku.cell.0"].exists)
    XCTAssertTrue(app.buttons["sudoku.cell.0"].isEnabled)
    app.buttons["sudoku.cell.0"].tap()
    app.buttons["sudoku.number.3"].tap()
    XCTAssertEqual(app.buttons["sudoku.cell.0"].value as? String, "3")
    app.nextFeedCard()
    app.previousFeedCard()
    XCTAssertFalse(app.buttons["game.start"].exists)
    XCTAssertEqual(app.buttons["sudoku.cell.0"].value as? String, "Empty")
    for _ in 0..<5 { app.nextFeedCard() }
    app.waitForFeedCard(newsID(0))
    XCTAssertTrue(app.staticTexts["news.sample"].exists)
    XCTAssertFalse(app.buttons["game.start"].exists)
    XCTAssertFalse(app.staticTexts["feed.position"].exists)
    app.previousFeedCard()
    app.waitForFeedCard(gameID(4))
    XCTAssertFalse(app.buttons["game.start"].exists)
    app.terminate()
  }

  func testGeneratedGamesCompleteResetAndRestoreAfterMultipleBatchesAndCanceledDrag() {
    let app = launch(extra: ["-sidequest-endless-slow-generation"])
    XCTAssertEqual(app.selectedFeedCardID, gameID(0))
    XCTAssertTrue(app.buttons["sudoku.cell.0"].exists)
    XCTAssertTrue(app.buttons["sudoku.cell.0"].isEnabled)
    let solution = [3, 4, 1, 2, 1, 2, 3, 4, 2, 3, 4, 1, 4, 1, 2, 3]
    let givens = [4, 5, 8, 15]
    app.buttons["sudoku.cell.0"].tap()
    app.buttons["sudoku.number.3"].tap()
    app.nextFeedCard()
    app.previousFeedCard()
    XCTAssertFalse(app.buttons["game.start"].exists)
    XCTAssertEqual(app.buttons["sudoku.cell.0"].value as? String, "Empty")
    for index in 0..<16 where !givens.contains(index) {
      reveal(app.buttons["sudoku.cell.\(index)"], in: app)
      app.buttons["sudoku.cell.\(index)"].tap()
      reveal(app.buttons["sudoku.number.\(solution[index])"], in: app)
      app.buttons["sudoku.number.\(solution[index])"].tap()
    }
    XCTAssertEqual(app.staticTexts["sudoku.status"].label, "Sudoku solved!")
    app.nextFeedCard()
    // Seed104 freezes this original generated layout; no production layout is exposed to automation.
    for pair in [[0, 11], [1, 8], [2, 9], [3, 6], [4, 10], [5, 7]] {
      for index in pair {
        reveal(app.buttons["memory.tile.\(index)"], in: app)
        app.buttons["memory.tile.\(index)"].tap()
      }
    }
    XCTAssertTrue(app.staticTexts["memory.completed"].exists)
    app.nextFeedCard()
    reveal(app.buttons["chess.square.g6"], in: app)
    app.buttons["chess.square.g6"].tap()
    app.buttons["chess.square.g7"].tap()
    XCTAssertTrue(app.staticTexts["chess.completed"].exists)
    app.nextFeedCard()
    app.nextFeedCard()
    app.previousFeedCard()
    // This short native drag holds the finger while the off-actor replenishment finishes.
    let pager = app.scrollViews["feed.pager"]
    let origin = pager.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5))
    let nearby = pager.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.47))
    origin.press(forDuration: 5, thenDragTo: nearby, withVelocity: .slow, thenHoldForDuration: 0.3)
    XCTAssertEqual(app.selectedFeedCardID, gameID(3))
    XCTAssertFalse(app.buttons["game.start"].exists)
    solveGeneratedBubble(app)
    for _ in 0..<21 { app.nextFeedCard() }
    XCTAssertEqual(app.selectedFeedCardID, gameID(20))
    XCTAssertFalse(app.buttons["game.start"].exists)
    for _ in 0..<24 { app.previousFeedCard() }
    XCTAssertEqual(app.selectedFeedCardID, gameID(0))
    XCTAssertEqual(app.staticTexts["sudoku.status"].label, "Sudoku solved!")
    app.nextFeedCard()
    XCTAssertTrue(app.staticTexts["memory.completed"].exists)
    app.nextFeedCard()
    XCTAssertTrue(app.staticTexts["chess.completed"].exists)
    app.nextFeedCard()
    XCTAssertEqual(app.staticTexts["bubble.outcome"].label, "You won!")
    XCTAssertFalse(app.buttons["bubble.replay"].exists)
    XCTAssertFalse(app.bubbleAim.exists)
    // Completed results remain intact through library presentation and foreground reopening.
    openLibrary(app)
    closeLibrary(app)
    XCTAssertEqual(app.staticTexts["bubble.outcome"].label, "You won!")
    XCTAssertEqual(app.staticTexts["bubble.shots"].label, "Shots: 3 of 8")
    XCUIDevice.shared.press(.home)
    app.activate()
    XCTAssertTrue(app.staticTexts["foundation.title"].waitForExistence(timeout: 5))
    app.terminate()
  }

  func testEndlessNativeImportsCyclePersistAndKeepHistoryAfterRejectionOrCancel() {
    let app = launch()
    openLibrary(app)
    importFile("Valid News", in: app)
    waitForMessage("Imported 1 news snapshots.", in: app)
    closeLibrary(app)
    app.waitForFeedCard(gameID(0))
    for _ in 0..<5 { app.nextFeedCard() }
    app.waitForFeedCard(newsID(0))
    XCTAssertTrue(app.staticTexts["Imported fixture story"].exists)
    for _ in 0..<12 { app.nextFeedCard() }
    app.waitForFeedCard(newsID(2))
    XCTAssertTrue(app.staticTexts["Imported fixture story"].exists)
    openLibrary(app)
    importFile("Malformed News", in: app)
    let failed = expectation(
      for: NSPredicate(format: "label BEGINSWITH %@", "Import failed."),
      evaluatedWith: app.staticTexts["news.message"])
    wait(for: [failed], timeout: 5)
    closeLibrary(app)
    app.waitForFeedCard(newsID(2))
    openLibrary(app)
    importFile("Collision News", in: app)
    waitForMessage("Imported 1 news snapshots.", in: app)
    closeLibrary(app)
    app.waitForFeedCard(gameID(0))
    for _ in 0..<5 { app.nextFeedCard() }
    app.waitForFeedCard(newsID(0))
    XCTAssertTrue(app.staticTexts["Imported fixture story"].exists)
    openLibrary(app)
    app.buttons["news.import"].tap()
    dismissNativeNewsPicker(app, doneIdentifier: "news.done")
    closeLibrary(app)
    app.waitForFeedCard(newsID(0))
    app.terminate()
    app.launchArguments = ["-sidequest-integration-fixtures", "-sidequest-endless-fixtures"]
    app.launchWithManualFeed()
    app.waitForFeedCard(gameID(0))
    for _ in 0..<5 { app.nextFeedCard() }
    app.waitForFeedCard(newsID(0))
    XCTAssertTrue(app.staticTexts["Imported fixture story"].exists)
    openLibrary(app)
    importFile("Empty News", in: app)
    waitForMessage("Imported 0 news snapshots.", in: app)
    closeLibrary(app)
    XCTAssertFalse(app.buttons["game.start"].exists)
    for _ in 0..<17 { app.nextFeedCard() }
    app.waitForFeedCard(gameID(17))
    XCTAssertFalse(app.staticTexts["news.sample"].exists)
    app.terminate()
    app.launchWithManualFeed()
    app.waitForFeedCard(gameID(0))
    XCTAssertFalse(app.buttons["game.start"].exists)
    for _ in 0..<5 { app.nextFeedCard() }
    app.waitForFeedCard(gameID(5))
    XCTAssertFalse(app.staticTexts["news.sample"].exists)
    app.terminate()
  }

  func testFreshDemoCadenceAcrossBatchesUsesDistinctStoriesAndHasNoCounter() {
    let app = launch()
    var headlines = Set<String>()
    for index in 0..<24 {
      XCTAssertFalse(app.staticTexts["feed.position"].exists)
      if index % 6 == 5 {
        app.waitForFeedCard(newsID(index / 6))
        XCTAssertTrue(app.staticTexts["news.sample"].exists)
        XCTAssertFalse(app.buttons["game.start"].exists)
        XCTAssertEqual(
          app.scrollViews["feed.pager"].label,
          app.staticTexts["news.headline"].label)
        headlines.insert(app.staticTexts["news.headline"].label)
        reveal(app.links["news.source"], in: app)
        XCTAssertTrue(app.links["news.source"].label.contains("fictional sample placeholder"))
      } else {
        app.waitForFeedCard(gameID(index - index / 6))
        XCTAssertFalse(app.buttons["game.start"].exists)
        XCTAssertFalse(app.staticTexts["news.sample"].exists)
      }
      if index < 23 { app.nextFeedCard() }
    }
    XCTAssertEqual(headlines.count, 4)
    for _ in 0..<18 { app.previousFeedCard() }
    app.waitForFeedCard(newsID(0))
    XCTAssertTrue(headlines.contains(app.staticTexts["news.headline"].label))
    app.terminate()
  }

  func testLargestTextAndActualReduceMotionKeepEndlessPagingAndExplicitStartUsable() {
    SystemAccessibilitySupport.withReduceMotion {
      let app = launch(extra: ["-sidequest-large-text"])
      for identifier in ["feed.navigation"] {
        XCTAssertTrue(app.buttons[identifier].isHittable)
        XCTAssertGreaterThanOrEqual(app.buttons[identifier].frame.width + 0.001, 44)
        XCTAssertGreaterThanOrEqual(app.buttons[identifier].frame.height + 0.001, 44)
      }
      for _ in 0..<20 { app.nextFeedCard() }
      XCTAssertEqual(app.selectedFeedCardID, gameID(17))
      reveal(app.buttons["memory.tile.0"], in: app)
      XCTAssertTrue(app.buttons["memory.tile.0"].isHittable)
      app.buttons["memory.tile.0"].tap()
      XCTAssertTrue(app.buttons["memory.tile.0"].label.hasPrefix("Revealed"))
      app.nextFeedCard()
      app.previousFeedCard()
      XCTAssertEqual(app.buttons["memory.tile.0"].label, "Hidden card 1")
      XCTAssertTrue(app.buttons["memory.tile.0"].isEnabled)
      app.terminate()
    }
  }

  func testGeneratedBubbleNeedsThreeShotsAndResetRestoresTheChallenge() {
    let app = launch(slowShot: false)
    for _ in 0..<3 { app.nextFeedCard() }
    app.waitForFeedCard(gameID(3))
    XCTAssertEqual(app.staticTexts["bubble.shots"].label, "Shots: 0 of 8")
    reveal(app.bubbleAim, in: app)
    app.shootBubble()
    waitForBubbleShots(1, in: app)
    XCTAssertFalse(app.staticTexts["bubble.outcome"].exists)
    app.nextFeedCard()
    app.previousFeedCard()
    app.waitForFeedCard(gameID(3))
    XCTAssertFalse(app.buttons["game.start"].exists)
    XCTAssertEqual(app.staticTexts["bubble.shots"].label, "Shots: 0 of 8")
    solveGeneratedBubble(app)
    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = "generated-bubble-three-shot-completion"
    attachment.lifetime = .keepAlways
    add(attachment)
    app.nextFeedCard()
    app.previousFeedCard()
    app.waitForFeedCard(gameID(3))
    XCTAssertEqual(app.staticTexts["bubble.outcome"].label, "You won!")
    XCTAssertEqual(app.staticTexts["bubble.shots"].label, "Shots: 3 of 8")
  }

  private func solveGeneratedBubble(_ app: XCUIApplication) {
    // Seed104 has the audited real three-shot route: 0°, 0°, then 24° left.
    for (index, horizontal) in [0.5, 0.5, 0.3].enumerated() {
      reveal(app.bubbleAim, in: app)
      let boardFrame = app.otherElements["bubble.board"].frame
      let viewportFrame = app.scrollViews["feed.cardScroll"].frame
      app.shootBubble(at: horizontal)
      waitForBubbleShots(index + 1, in: app)
      XCTAssertEqual(app.otherElements["bubble.board"].frame, boardFrame)
      XCTAssertEqual(app.scrollViews["feed.cardScroll"].frame, viewportFrame)
      XCTAssertEqual(app.selectedFeedCardID, gameID(3))
      captureBubbleAim(app, name: "shot-\(index + 1)")
      if index < 2 {
        XCTAssertEqual(app.bubbleAim.value as? String, "Aim: 0 degrees")
        XCTAssertFalse(app.staticTexts["bubble.outcome"].exists)
      }
    }
    XCTAssertEqual(app.staticTexts["bubble.outcome"].label, "You won!")
  }

  private func captureBubbleAim(_ app: XCUIApplication, name: String) {
    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = "generated-bubble-actual-aim-\(name)"
    attachment.lifetime = .keepAlways
    add(attachment)
  }

  private func waitForBubbleShots(_ count: Int, in app: XCUIApplication) {
    let committed = expectation(
      for: NSPredicate(format: "label == %@", "Shots: \(count) of 8"),
      evaluatedWith: app.staticTexts["bubble.shots"])
    wait(for: [committed], timeout: 10)
  }

  private func launch(extra: [String] = [], slowShot: Bool = true) -> XCUIApplication {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments =
      [
        "-sidequest-integration-fixtures", "-sidequest-integration-reset",
        "-sidequest-endless-fixtures",
      ] + (slowShot ? ["-sidequest-bubble-slow-shot"] : []) + extra
    app.launchWithManualFeed()
    XCTAssertTrue(app.staticTexts["foundation.title"].waitForExistence(timeout: 10))
    return app
  }
  private func gameID(_ sequence: Int) -> String {
    "game-00000000-0000-0000-0000-000000000104-\(sequence)"
  }
  private func newsID(_ ordinal: Int) -> String {
    "news-00000000-0000-0000-0000-000000000104-\(ordinal)"
  }
  private func openLibrary(_ app: XCUIApplication) {
    app.openNewsLibrary()
  }
  private func closeLibrary(_ app: XCUIApplication) {
    app.buttons["news.done"].tap()
    XCTAssertTrue(app.buttons["feed.navigation"].waitForExistence(timeout: 5))
    XCTAssertFalse(app.buttons["feed.news"].exists)
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
    XCTAssertTrue(browser.waitForExistence(timeout: 10))
    let file = browser.collectionViews["File View"].cells.matching(
      NSPredicate(format: "label BEGINSWITH %@ OR identifier BEGINSWITH %@", name, name)
    ).firstMatch
    // Restored File Provider locations can reference the previous test installation.
    // Resolve the current app container through native Locations on every import.
    let phone = browser.cells["DOC.sidebar.item.On My iPhone"]
    if !phone.exists {
      let browse = app.tabBars["DOC.browsingModeTabBar"].buttons["Browse"]
      XCTAssertTrue(browse.isHittable, app.debugDescription)
      browse.tap()
      // A fresh picker opens Recents. The first tap selects Browse's provider;
      // tapping the selected tab returns from that provider to Locations.
      if !phone.exists { browse.tap() }
    }
    XCTAssertTrue(phone.waitForExistence(timeout: 5), app.debugDescription)
    phone.tap()
    for folder in ["Sidequest", "Sidequest Fixtures v2"] {
      let cell = browser.collectionViews["File View"].cells.matching(
        NSPredicate(
          format: "label BEGINSWITH %@ OR identifier BEGINSWITH %@", folder + ",", folder + ",")
      ).firstMatch
      XCTAssertTrue(cell.waitForExistence(timeout: 5), app.debugDescription)
      cell.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25)).tap()
    }
    XCTAssertTrue(file.waitForExistence(timeout: 5), app.debugDescription)
    let thumbnail = file.images.firstMatch
    XCTAssertTrue(thumbnail.exists, file.debugDescription)
    thumbnail.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    XCTAssertTrue(browser.waitForNonExistence(timeout: 5), app.debugDescription)
    let importer = app.buttons["news.import"]
    XCTAssertTrue(importer.waitForExistence(timeout: 5), app.debugDescription)
    XCTAssertTrue(importer.isHittable, app.debugDescription)
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
