import XCTest

@MainActor
final class IntegrationFlowTests: XCTestCase {
  func testNativeImportsReplaceTheMixedDeckPersistAndRejectInvalidFiles() {
    let app = launch()
    XCTAssertEqual(app.selectedFeedCardID, "sample-game-bubbleShooter")
    XCTAssertFalse(app.staticTexts["news.sample"].exists)
    openLibrary(app)
    importFile("Valid News", in: app)
    waitForMessage("Imported 1 news snapshots.", in: app)
    closeLibrary(app)
    XCTAssertEqual(app.selectedFeedCardID, "imported-news-one")
    XCTAssertTrue(app.staticTexts["Imported fixture story"].exists)
    app.terminate()
    app.launchArguments = ["-sidequest-integration-fixtures"]
    app.launch()
    XCTAssertTrue(app.staticTexts["Imported fixture story"].waitForExistence(timeout: 10))
    XCTAssertEqual(app.selectedFeedCardID, "imported-news-one")
    for name in ["Malformed News", "Reserved News"] {
      openLibrary(app)
      importFile(name, in: app)
      let failed = expectation(
        for: NSPredicate(format: "label BEGINSWITH %@", "Import failed."),
        evaluatedWith: app.staticTexts["news.message"])
      wait(for: [failed], timeout: 5)
      closeLibrary(app)
      XCTAssertEqual(app.selectedFeedCardID, "imported-news-one")
      XCTAssertTrue(app.staticTexts["Imported fixture story"].exists)
    }
    openLibrary(app)
    app.buttons["news.import"].tap()
    dismissNativeNewsPicker(app, doneIdentifier: "news.done")
    closeLibrary(app)
    XCTAssertEqual(app.selectedFeedCardID, "imported-news-one")
    XCTAssertTrue(app.staticTexts["Imported fixture story"].exists)
    app.terminate()
    app.launch()
    XCTAssertTrue(app.staticTexts["Imported fixture story"].waitForExistence(timeout: 10))
    XCTAssertEqual(app.selectedFeedCardID, "imported-news-one")
    openLibrary(app)
    importFile("Empty News", in: app)
    waitForMessage("Imported 0 news snapshots.", in: app)
    closeLibrary(app)
    XCTAssertEqual(app.selectedFeedCardID, "sample-game-bubbleShooter")
    XCTAssertTrue(app.bubbleAim.isEnabled)
    app.terminate()
    app.launch()
    XCTAssertTrue(app.bubbleAim.waitForExistence(timeout: 10))
    XCTAssertEqual(app.selectedFeedCardID, "sample-game-bubbleShooter")
  }

  func testLibraryAndBackgroundCancelPendingRealGamesAndCompletionSurvivesCancel() {
    let app = launch(extra: ["-sidequest-bubble-slow-shot"])
    reveal(app.bubbleAim, in: app)
    app.shootBubble()
    XCTAssertEqual(app.staticTexts["bubble.feedback"].label, "Shot in flight.")
    openLibrary(app)
    XCUIDevice.shared.press(.home)
    app.activate()
    XCTAssertTrue(app.buttons["news.done"].waitForExistence(timeout: 5))
    closeLibrary(app)
    XCTAssertFalse(app.buttons["game.start"].exists)
    XCTAssertEqual(app.staticTexts["bubble.shots"].label, "Shots: 0 of 8")
    for (index, aim) in [0.5, 0.5, 0.65].enumerated() {
      reveal(app.bubbleAim, in: app)
      app.shootBubble(at: aim)
      let committed = expectation(
        for: NSPredicate(format: "label == %@", "Shots: \(index + 1) of 8"),
        evaluatedWith: app.staticTexts["bubble.shots"])
      wait(for: [committed], timeout: 10)
    }
    XCTAssertEqual(app.staticTexts["bubble.outcome"].label, "You won!")
    openLibrary(app)
    closeLibrary(app)
    XCTAssertEqual(app.staticTexts["bubble.outcome"].label, "You won!")
    for _ in 0..<3 { app.nextFeedCard() }
    XCTAssertTrue(app.staticTexts["Memory"].exists)
    XCTAssertFalse(app.buttons["game.start"].exists)
    app.buttons["memory.tile.0"].tap()
    app.buttons["memory.tile.2"].tap()
    XCTAssertTrue(app.buttons["memory.tile.0"].label.hasPrefix("Revealed"))
    openLibrary(app)
    closeLibrary(app)
    XCTAssertFalse(app.buttons["game.start"].exists)
    XCTAssertEqual(app.buttons["memory.tile.0"].label, "Hidden card 1")
    XCTAssertEqual(app.staticTexts["memory.progress"].label, "0 of 6 pairs matched")
    app.nextFeedCard()
    app.previousFeedCard()
    XCTAssertFalse(app.buttons["game.start"].exists)
  }

  func testLargestTextImportedOverflowSourceLinkAndActualReducedMotionKeepNavigation() {
    SystemAccessibilitySupport.withReduceMotion {
      let app = launch(extra: ["-sidequest-large-text"])
      for identifier in ["feed.navigation"] {
        XCTAssertTrue(app.buttons[identifier].isHittable)
        XCTAssertGreaterThanOrEqual(app.buttons[identifier].frame.width + 0.001, 44)
        XCTAssertGreaterThanOrEqual(app.buttons[identifier].frame.height + 0.001, 44)
      }
      openLibrary(app)
      importFile("Valid News", in: app)
      waitForMessage("Imported 1 news snapshots.", in: app)
      closeLibrary(app)
      let scroll = app.scrollViews["feed.cardScroll"]
      let source = app.links["news.source"]
      let before = source.frame.minY
      let bottom = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.85))
      let top = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.15))
      bottom.press(
        forDuration: 0.01, thenDragTo: top, withVelocity: .slow, thenHoldForDuration: 0.1)
      XCTAssertLessThan(source.frame.minY, before)
      XCTAssertEqual(app.selectedFeedCardID, "imported-news-one")
      reveal(source, in: app, maximumDrags: 100)
      source.tap()
      let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
      XCTAssertTrue(safari.wait(for: .runningForeground, timeout: 5))
      app.activate()
      XCTAssertEqual(app.selectedFeedCardID, "imported-news-one")
      // Reaching an edge consumes that gesture; a NEW outward gesture pages.
      for _ in 0..<8 {
        if app.selectedFeedCardID != "imported-news-one" { break }
        bottom.press(
          forDuration: 0.01, thenDragTo: top, withVelocity: .slow, thenHoldForDuration: 0.2)
      }
      let second = expectation(
        for: NSPredicate(format: "identifier == %@", "feed.selected.sample-game-bubbleShooter"),
        evaluatedWith: app.selectedFeedCard)
      wait(for: [second], timeout: 5)
      XCTAssertFalse(app.buttons["game.start"].exists)
      app.previousFeedCard()
      XCTAssertEqual(app.selectedFeedCardID, "imported-news-one")
      app.terminate()
    }
  }

  func testNewsMenuAtNormalAndLargestTextResetsUnfinishedGame() {
    for extra in [[], ["-sidequest-large-text"]] {
      let app = launch(extra: extra)
      let menu = app.buttons["feed.navigation"]
      XCTAssertEqual(menu.label, "More options")
      XCTAssertTrue(menu.isHittable)
      XCTAssertGreaterThanOrEqual(menu.frame.width + 0.001, 44)
      XCTAssertGreaterThanOrEqual(menu.frame.height + 0.001, 44)
      XCTAssertFalse(app.buttons["feed.news"].exists)
      let headerFrame = menu.frame
      XCTAssertTrue(app.frame.contains(headerFrame))
      captureUtilityScreen(
        app, name: extra.isEmpty ? "Neutral menu normal" : "Neutral menu largest")
      let selected = app.selectedFeedCardID
      reveal(app.bubbleAim, in: app)
      app.cancelBubbleShot(at: 0.65)
      let changedAim = app.bubbleAim.value as? String ?? ""
      XCTAssertFalse(changedAim.isEmpty)
      XCTAssertNotEqual(changedAim, "Aim: 0 degrees")
      openLibrary(app)
      XCTAssertTrue(app.buttons["news.import"].isHittable)
      XCTAssertGreaterThanOrEqual(app.buttons["news.import"].frame.height + 0.001, 44)
      captureUtilityScreen(
        app, name: extra.isEmpty ? "Neutral library normal" : "Neutral library largest")
      closeLibrary(app)
      XCTAssertEqual(app.selectedFeedCardID, selected)
      XCTAssertEqual(app.staticTexts["bubble.shots"].label, "Shots: 0 of 8")
      let aimValue = app.bubbleAim.value as? String ?? ""
      XCTAssertEqual(aimValue, "Aim: 0 degrees")
      XCTAssertEqual(menu.frame, headerFrame)
      XCTAssertTrue(menu.isHittable)
      XCTAssertFalse(app.buttons["feed.news"].exists)
      app.terminate()
    }
  }

  private func captureUtilityScreen(_ app: XCUIApplication, name: String) {
    let screenshot = XCTAttachment(screenshot: app.screenshot())
    screenshot.name = name
    screenshot.lifetime = .keepAlways
    add(screenshot)
  }

  private func launch(extra: [String] = []) -> XCUIApplication {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments =
      ["-sidequest-integration-fixtures", "-sidequest-integration-reset"] + extra
    app.launch()
    XCTAssertTrue(app.bubbleAim.waitForExistence(timeout: 10))
    return app
  }

  private func openLibrary(_ app: XCUIApplication) {
    app.openNewsLibrary()
  }

  private func closeLibrary(_ app: XCUIApplication) {
    app.buttons["news.done"].tap()
    XCTAssertTrue(app.buttons["feed.navigation"].waitForExistence(timeout: 5))
    XCTAssertFalse(app.buttons["feed.news"].exists)
  }

  private func importFile(_ name: String, in app: XCUIApplication) {
    app.buttons["news.import"].tap()
    XCTAssertTrue(app.otherElements["Browse View (Picker)"].waitForExistence(timeout: 10))
    let browser = app.otherElements["Browse View (Picker)"]
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

  private func waitForMessage(_ message: String, in app: XCUIApplication) {
    let expected = expectation(
      for: NSPredicate(format: "label == %@", message),
      evaluatedWith: app.staticTexts["news.message"])
    wait(for: [expected], timeout: 5)
  }

  private func reveal(_ element: XCUIElement, in app: XCUIApplication, maximumDrags: Int = 30) {
    let scroll = app.scrollViews["feed.cardScroll"]
    for _ in 0..<maximumDrags {
      if element.exists && element.isHittable && scroll.frame.contains(element.frame) { return }
      let needsUp = element.frame.midY > scroll.frame.midY
      let isBubbleControl =
        element.identifier == "bubble.directAim"
      let horizontal: CGFloat
      if isBubbleControl {
        // Bubble owns lower-board drags; use its outer gap, clear of the scroll indicator.
        let board = app.otherElements["bubble.board"]
        horizontal =
          board.exists && !board.frame.isEmpty
          ? min(scroll.frame.width - 32, board.frame.maxX - scroll.frame.minX + 10)
          : scroll.frame.width - 32
      } else {
        horizontal = scroll.frame.width * 0.8
      }
      let startY = isBubbleControl ? (needsUp ? 0.65 : 0.35) : (needsUp ? 0.75 : 0.25)
      let endY = isBubbleControl ? (needsUp ? 0.4 : 0.6) : (needsUp ? 0.25 : 0.75)
      let origin = scroll.coordinate(withNormalizedOffset: .zero)
      let start = origin.withOffset(CGVector(dx: horizontal, dy: scroll.frame.height * startY))
      let end = origin.withOffset(CGVector(dx: horizontal, dy: scroll.frame.height * endY))
      start.press(forDuration: 0.01, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.1)
    }
    let diagnostic = XCTAttachment(string: app.debugDescription)
    diagnostic.name = "integration-reveal-failed-hierarchy"
    diagnostic.lifetime = .keepAlways
    add(diagnostic)
    captureUtilityScreen(app, name: "Integration reveal failed viewport")
    XCTAssertTrue(
      scroll.frame.contains(element.frame),
      "Control must be completely in the viewport: target=\(element.frame), viewport=\(scroll.frame)"
    )
    XCTAssertTrue(element.isHittable)
  }
}
