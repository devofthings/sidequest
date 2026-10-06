import XCTest

final class BubbleFlowTests: XCTestCase {
  @MainActor
  func testThreeShotWinRetainsCompletionAndReplayStartsWithoutShot() {
    let app = launch()
    start(app)
    for (index, aim) in [0.5, 0.5, 0.65].enumerated() {
      fire(app, aim: aim, expectedShots: index + 1)
    }
    XCTAssertTrue(app.staticTexts["bubble.outcome"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts["game.successCelebration"].waitForExistence(timeout: 5))
    let success = XCTAttachment(screenshot: app.screenshot())
    success.name = "bubble-success-celebration"
    success.lifetime = .keepAlways
    add(success)
    XCTAssertEqual(app.staticTexts["bubble.outcome"].label, "You won!")
    assertCompletedAimAbsent(app)
    app.nextFeedCard()
    app.previousFeedCard()
    XCTAssertFalse(app.staticTexts["game.successCelebration"].exists)
    XCTAssertEqual(app.staticTexts["bubble.outcome"].label, "You won!")
    assertCompletedAimAbsent(app)
    XCTAssertFalse(app.buttons["bubble.replay"].exists)
    // Replay remains an assistive custom action; ordinary completed revisits keep the result.
    app.terminate()
    app.launch()
    XCTAssertTrue(app.bubbleAim.waitForExistence(timeout: 5))
    XCTAssertEqual(app.staticTexts["bubble.shots"].label, "Shots: 0 of 8")
    XCTAssertTrue(
      (app.otherElements["bubble.board"].value as? String)?.hasPrefix("9 bubbles remaining.")
        == true)
  }

  @MainActor
  func testSevenStraightShotsLoseAndReplayRestoresChallenge() {
    let app = launch()
    start(app)
    for count in 1...7 { fire(app, aim: 0.5, expectedShots: count) }
    XCTAssertTrue(app.staticTexts["bubble.outcome"].waitForExistence(timeout: 5))
    XCTAssertEqual(app.staticTexts["bubble.outcome"].label, "You lost")
    assertCompletedAimAbsent(app)
    XCTAssertFalse(app.staticTexts["game.successCelebration"].exists)
    XCTAssertFalse(app.buttons["bubble.replay"].exists)
    app.terminate()
    app.launch()
    XCTAssertTrue(app.bubbleAim.waitForExistence(timeout: 5))
    XCTAssertEqual(app.staticTexts["bubble.shots"].label, "Shots: 0 of 8")
    XCTAssertTrue(app.bubbleAim.isEnabled)
  }

  @MainActor
  func testSkippingAnActiveShotReturnsToPreviewAndCannotCommitLate() {
    let app = launch(slowShot: true)
    start(app)
    reveal(app.bubbleAim, in: app)
    app.shootBubble()
    XCTAssertEqual(app.staticTexts["bubble.feedback"].label, "Shot in flight.")
    XCTAssertFalse(app.bubbleAim.isEnabled)
    app.nextFeedCard()
    app.previousFeedCard()
    XCTAssertTrue(app.bubbleAim.waitForExistence(timeout: 5))
    XCTAssertTrue(app.bubbleAim.exists)
    XCTAssertTrue(app.bubbleAim.isEnabled)
    start(app)
    XCTAssertEqual(app.staticTexts["bubble.shots"].label, "Shots: 0 of 8")
    // Finishing a fresh current shot also proves the old animation never commits into this attempt.
    fire(app, aim: 0.5, expectedShots: 1)
    XCTAssertEqual(app.staticTexts["bubble.shots"].label, "Shots: 1 of 8")
  }

  @MainActor
  func testLargestTextAimAndFireRemainUsableWithoutNavigating() {
    let app = launch(largeText: true)
    start(app)
    let position = app.selectedFeedCardID
    let direct = app.bubbleAim
    reveal(direct, in: app)
    let directFrame = direct.frame
    let boardFrame = app.otherElements["bubble.board"].frame
    XCTAssertGreaterThanOrEqual(directFrame.width, 44)
    XCTAssertGreaterThanOrEqual(directFrame.height, 44)
    app.shootBubble(at: 0.75)
    waitForShots(1, in: app)
    XCTAssertNotEqual(observedAim(in: app), "Aim: 0 degrees")
    XCTAssertEqual(direct.frame, directFrame)
    XCTAssertEqual(app.otherElements["bubble.board"].frame, boardFrame)
    XCTAssertEqual(app.selectedFeedCardID, position)
    app.nextFeedCard()
    app.previousFeedCard()
    reveal(app.bubbleAim, in: app)
    XCTAssertTrue(app.bubbleAim.isHittable)
    XCTAssertEqual(app.staticTexts["bubble.shots"].label, "Shots: 0 of 8")
  }

  @MainActor
  func testNativeHorizontalAndDiagonalAimDragsDoNotPage() {
    let app = launch()
    start(app)
    let aim = app.bubbleAim
    reveal(aim, in: app)
    let position = app.selectedFeedCardID
    for (count, endpoint) in [CGVector(dx: 0.8, dy: 0.5), CGVector(dx: 0.2, dy: 0.65)].enumerated()
    {
      let center = aim.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
      center.press(
        forDuration: 0.01, thenDragTo: aim.coordinate(withNormalizedOffset: endpoint),
        withVelocity: .slow, thenHoldForDuration: 0.1)
      waitForShots(count + 1, in: app)
      XCTAssertNotEqual(observedAim(in: app), "Aim: 0 degrees")
      XCTAssertEqual(app.selectedFeedCardID, position)
    }
    fire(app, aim: 0.5, expectedShots: 3)
    XCTAssertEqual(app.selectedFeedCardID, position)
  }

  @MainActor
  func testDirectAimHorizontalVerticalAndDiagonalStayInTheirOwnedAreaUntilFire() {
    let app = launch()
    start(app)
    let aim = app.bubbleAim
    let board = app.otherElements["bubble.board"]
    let viewport = app.scrollViews["feed.cardScroll"]
    XCTAssertGreaterThanOrEqual(aim.frame.width + 0.001, 44)
    XCTAssertGreaterThanOrEqual(aim.frame.height + 0.001, 44)
    let frames = [board.frame, aim.frame, viewport.frame]
    let position = app.selectedFeedCardID
    for (index, gesture) in [
      ("launcher-origin-horizontal", CGVector(dx: 0.5, dy: 0.8), CGVector(dx: 0.8, dy: 0.8)),
      ("horizontal", CGVector(dx: 0.5, dy: 0.2), CGVector(dx: 0.8, dy: 0.2)),
      ("vertical", CGVector(dx: 0.8, dy: 0.1), CGVector(dx: 0.8, dy: 0.5)),
      ("diagonal", CGVector(dx: 0.5, dy: 0.1), CGVector(dx: 0.2, dy: 0.4)),
    ].enumerated() {
      let (name, from, to) = gesture
      if index > 0 {
        app.nextFeedCard()
        app.previousFeedCard()
        XCTAssertEqual(app.staticTexts["bubble.shots"].label, "Shots: 0 of 8")
      }
      aim.coordinate(withNormalizedOffset: from).press(
        forDuration: 0.01,
        thenDragTo: aim.coordinate(withNormalizedOffset: to), withVelocity: .slow,
        thenHoldForDuration: 0.1)
      waitForShots(1, in: app)
      capture(app, name: "direct-release-\(name)")
      let expectedDegrees = Int(((to.dx - 0.5) * 120).rounded())
      XCTAssertEqual(observedAim(in: app), "Aim: \(expectedDegrees) degrees")
      XCTAssertFalse(app.staticTexts["bubble.angle"].exists)
      XCTAssertEqual(app.selectedFeedCardID, position)
      XCTAssertEqual([board.frame, aim.frame, viewport.frame], frames)
    }
    // A release beyond the narrow area cancels without consuming another shot.
    app.cancelBubbleShot()
    XCTAssertEqual(app.staticTexts["bubble.shots"].label, "Shots: 1 of 8")
    app.nextFeedCard()
    waitForPosition("sample-news-garden", in: app)
    app.previousFeedCard()
    XCTAssertTrue(app.bubbleAim.waitForExistence(timeout: 5))
    XCTAssertEqual(app.staticTexts["bubble.shots"].label, "Shots: 0 of 8")
  }

  @MainActor
  func testBackgroundDuringDirectAimedFlightReturnsToFrozenPreview() {
    let app = launch(slowShot: true)
    start(app)
    app.shootBubble(at: 0.7)
    XCTAssertNotEqual(observedAim(in: app), "Aim: 0 degrees")
    XCTAssertEqual(app.staticTexts["bubble.feedback"].label, "Shot in flight.")
    XCTAssertFalse(app.bubbleAim.isEnabled)
    XCUIDevice.shared.press(.home)
    app.activate()
    XCTAssertTrue(app.bubbleAim.waitForExistence(timeout: 5))
    XCTAssertEqual(observedAim(in: app), "Aim: 0 degrees")
    XCTAssertEqual(app.staticTexts["bubble.shots"].label, "Shots: 0 of 8")
    start(app)
    fire(app, aim: 0.5, expectedShots: 1)
  }

  @MainActor
  func testShortBoardDragKeepsAttemptAndDirectSkipResetsPendingShot() {
    let app = launch(slowShot: true)
    start(app)
    let board = app.otherElements["bubble.board"]
    reveal(board, in: app)
    let middle = board.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
    let short = board.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.6))
    middle.press(
      forDuration: 0.01, thenDragTo: short, withVelocity: .slow, thenHoldForDuration: 0.2)
    XCTAssertEqual(app.selectedFeedCardID, "sample-game-bubbleShooter")
    XCTAssertFalse(app.buttons["game.start"].exists)
    XCTAssertEqual(app.staticTexts["bubble.shots"].label, "Shots: 0 of 8")
    reveal(app.bubbleAim, in: app)
    app.shootBubble()
    XCTAssertEqual(app.staticTexts["bubble.feedback"].label, "Shot in flight.")
    let pager = app.scrollViews["feed.pager"]
    for _ in 0..<3 {
      if app.selectedFeedCardID != "sample-game-bubbleShooter" { break }
      pager.swipeUp(velocity: .fast)
    }
    waitForPosition("sample-news-garden", in: app)
    pager.swipeDown(velocity: .fast)
    waitForPosition("sample-game-bubbleShooter", in: app)
    XCTAssertFalse(app.buttons["game.start"].exists)
    XCTAssertTrue(app.bubbleAim.exists)
    XCTAssertTrue(app.bubbleAim.isEnabled)
    start(app)
    fire(app, aim: 0.5, expectedShots: 1)
  }

  @MainActor
  func testSystemReduceMotionKeepsPendingShotStationary() {
    continueAfterFailure = false
    SystemAccessibilitySupport.withReduceMotion {
      let app = launch(slowShot: true)
      start(app)
      app.cancelBubbleShot()
      XCTAssertEqual(
        observedAim(in: app), "Aim: 0 degrees")
      XCTAssertEqual(app.staticTexts["bubble.shots"].label, "Shots: 0 of 8")
      reveal(app.bubbleAim, in: app)
      app.shootBubble()
      XCTAssertEqual(app.staticTexts["bubble.feedback"].label, "Shot in flight.")
      let first = app.otherElements["bubble.board"].screenshot()
      let second = app.otherElements["bubble.board"].screenshot()
      XCTAssertEqual(first.pngRepresentation, second.pngRepresentation)
      let attachment = XCTAttachment(screenshot: second)
      attachment.name = "Bubble flight with system Reduce Motion"
      attachment.lifetime = .keepAlways
      add(attachment)
      waitForShots(1, in: app)
      app.terminate()
    }
  }

  @MainActor
  private func observedAim(in app: XCUIApplication) -> String {
    let value = app.bubbleAim.value as? String ?? ""
    XCTAssertTrue(
      value.hasPrefix("Aim: "), "Missing named accessible aim value: \(app.debugDescription)")
    return value
  }

  @MainActor
  private func assertCompletedAimAbsent(_ app: XCUIApplication) {
    let directControls = app.descendants(matching: .any).matching(identifier: "bubble.directAim")
    let sliders = app.descendants(matching: .any).matching(identifier: "bubble.aim")
    let metadata = [directControls, sliders].flatMap { query in
      query.allElementsBoundByIndex.map { element in
        "type=\(element.elementType.rawValue) identifier=\(element.identifier) "
          + "label=\(element.label) value=\(String(describing: element.value)) "
          + "enabled=\(element.isEnabled) hittable=\(element.isHittable) frame=\(element.frame)"
      }
    }
    let diagnostic = XCTAttachment(
      string: "Completed aiming matches: direct=\(directControls.count), slider=\(sliders.count)\n"
        + metadata.joined(separator: "\n") + "\n\n" + app.debugDescription)
    diagnostic.name = "bubble-completed-aim-hierarchy"
    diagnostic.lifetime = .keepAlways
    add(diagnostic)
    XCTAssertFalse(app.bubbleAim.exists)
    XCTAssertFalse(app.sliders["bubble.aim"].exists)
    XCTAssertEqual(directControls.count, 0)
    XCTAssertEqual(sliders.count, 0)
  }

  @MainActor
  private func capture(_ app: XCUIApplication, name: String) {
    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }

  @MainActor
  private func waitForPosition(_ position: String, in app: XCUIApplication) {
    let expected = expectation(
      for: NSPredicate(format: "identifier == %@", "feed.selected.\(position)"),
      evaluatedWith: app.selectedFeedCard)
    wait(for: [expected], timeout: 5)
  }

  @MainActor
  private func launch(slowShot: Bool = false, largeText: Bool = false) -> XCUIApplication {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments =
      ["-sidequest-bubble-fixtures", "-sidequest-success-feedback-test"]
      + (slowShot ? ["-sidequest-bubble-slow-shot"] : [])
      + (largeText ? ["-sidequest-large-text"] : [])
    app.launchWithManualFeed()
    XCTAssertTrue(app.bubbleAim.waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts["Bubble shooter"].exists)
    XCTAssertTrue(app.bubbleAim.exists)
    XCTAssertTrue(app.bubbleAim.isEnabled)
    return app
  }

  @MainActor
  private func start(_ app: XCUIApplication) {
    let direct = app.bubbleAim
    reveal(direct, in: app)
    app.cancelBubbleShot(at: 0.7)
    XCTAssertNotEqual(observedAim(in: app), "Aim: 0 degrees")
    app.cancelBubbleShot()
    XCTAssertEqual(observedAim(in: app), "Aim: 0 degrees")
    XCTAssertTrue(app.otherElements["bubble.board"].waitForExistence(timeout: 5))
    XCTAssertEqual(app.staticTexts["bubble.shots"].label, "Shots: 0 of 8")
  }

  @MainActor
  private func fire(_ app: XCUIApplication, aim: Double, expectedShots: Int) {
    reveal(app.bubbleAim, in: app)
    XCTAssertGreaterThanOrEqual(app.bubbleAim.frame.height + 0.001, 44)
    XCTAssertGreaterThanOrEqual(app.bubbleAim.frame.width + 0.001, 44)
    app.shootBubble(at: aim)
    waitForShots(expectedShots, in: app)
    if aim != 0.5, app.bubbleAim.exists {
      let angle = Double(observedAim(in: app).filter { $0.isNumber || $0 == "-" })
      XCTAssertTrue(
        (6...30).contains(angle ?? -60), "Real touch must reach the winning aim window.")
    }
  }

  @MainActor
  private func waitForShots(_ count: Int, in app: XCUIApplication) {
    let committed = expectation(
      for: NSPredicate(format: "label == %@", "Shots: \(count) of 8"),
      evaluatedWith: app.staticTexts["bubble.shots"])
    wait(for: [committed], timeout: 10)
  }

  @MainActor
  private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
    let scroll = app.scrollViews["feed.cardScroll"]
    for _ in 0..<18 {
      if element.exists && element.isHittable && scroll.frame.contains(element.frame) { return }
      let needsUp = element.frame.midY > scroll.frame.midY
      // Stay beyond the board's direct input but away from UIKit's draggable scroll indicator.
      let board = app.otherElements["bubble.board"]
      let x =
        board.exists && !board.frame.isEmpty
        ? min(scroll.frame.width - 32, board.frame.maxX - scroll.frame.minX + 10)
        : scroll.frame.width - 32
      let origin = scroll.coordinate(withNormalizedOffset: .zero)
      let start = origin.withOffset(
        CGVector(dx: x, dy: scroll.frame.height * (needsUp ? 0.65 : 0.35)))
      let end = origin.withOffset(CGVector(dx: x, dy: scroll.frame.height * (needsUp ? 0.4 : 0.6)))
      start.press(forDuration: 0.1, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.1)
    }
    let diagnostic = XCTAttachment(string: app.debugDescription)
    diagnostic.name = "bubble-reveal-failed-hierarchy"
    diagnostic.lifetime = .keepAlways
    add(diagnostic)
    capture(app, name: "bubble-reveal-failed-viewport")
    XCTAssertTrue(element.isHittable)
    XCTAssertTrue(scroll.frame.contains(element.frame))
  }

}
