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
    reveal(app.buttons["bubble.replay"], in: app)
    XCTAssertGreaterThanOrEqual(app.buttons["bubble.replay"].frame.height + 0.001, 44)
    XCTAssertGreaterThanOrEqual(app.buttons["bubble.replay"].frame.width + 0.001, 44)
    app.buttons["bubble.replay"].tap()
    XCTAssertFalse(app.staticTexts["bubble.outcome"].exists)
    XCTAssertEqual(app.staticTexts["bubble.shots"].label, "Shots: 0 of 8")
    XCTAssertTrue(
      (app.otherElements["bubble.board"].value as? String)?.hasPrefix("9 bubbles remaining.")
        == true)
    XCTAssertTrue(app.buttons["bubble.fire"].isEnabled)
    XCTAssertTrue(app.otherElements["bubble.directAim"].exists)
    XCTAssertTrue(app.sliders["bubble.aim"].exists)
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
    reveal(app.buttons["bubble.replay"], in: app)
    XCTAssertGreaterThanOrEqual(app.buttons["bubble.replay"].frame.height + 0.001, 44)
    XCTAssertGreaterThanOrEqual(app.buttons["bubble.replay"].frame.width + 0.001, 44)
    app.buttons["bubble.replay"].tap()
    XCTAssertFalse(app.staticTexts["bubble.outcome"].exists)
    XCTAssertEqual(app.staticTexts["bubble.shots"].label, "Shots: 0 of 8")
    XCTAssertTrue(app.buttons["bubble.fire"].isEnabled)
    XCTAssertTrue(app.otherElements["bubble.directAim"].exists)
    XCTAssertTrue(app.sliders["bubble.aim"].exists)
  }

  @MainActor
  func testSkippingAnActiveShotReturnsToPreviewAndCannotCommitLate() {
    let app = launch(slowShot: true)
    start(app)
    reveal(app.buttons["bubble.fire"], in: app)
    app.buttons["bubble.fire"].tap()
    XCTAssertEqual(app.staticTexts["bubble.feedback"].label, "Shot in flight.")
    XCTAssertFalse(app.buttons["bubble.fire"].isEnabled)
    app.nextFeedCard()
    app.previousFeedCard()
    XCTAssertTrue(app.buttons["game.start"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.buttons["bubble.fire"].exists)
    XCTAssertFalse(app.buttons["bubble.fire"].isEnabled)
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
    let direct = app.otherElements["bubble.directAim"]
    reveal(direct, in: app)
    let directFrame = direct.frame
    let boardFrame = app.otherElements["bubble.board"].frame
    direct.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)).press(
      forDuration: 0.01,
      thenDragTo: direct.coordinate(withNormalizedOffset: CGVector(dx: 0.75, dy: 0.4)),
      withVelocity: .slow, thenHoldForDuration: 0.1)
    XCTAssertNotEqual(
      observedAim(in: app), "Aim: 0 degrees")
    XCTAssertEqual(direct.frame, directFrame)
    XCTAssertEqual(app.otherElements["bubble.board"].frame, boardFrame)
    XCTAssertEqual(app.staticTexts["bubble.shots"].label, "Shots: 0 of 8")
    XCTAssertEqual(app.selectedFeedCardID, position)
    reveal(app.sliders["bubble.aim"], in: app)
    XCTAssertTrue(app.sliders["bubble.aim"].isHittable)
    app.sliders["bubble.aim"].adjust(toNormalizedSliderPosition: 0.75)
    XCTAssertNotEqual(
      observedAim(in: app), "Aim: 0 degrees")
    XCTAssertEqual(app.selectedFeedCardID, position)
    reveal(app.buttons["bubble.fire"], in: app)
    XCTAssertTrue(app.buttons["bubble.fire"].isHittable)
    XCTAssertGreaterThanOrEqual(app.buttons["bubble.fire"].frame.height + 0.001, 44)
    app.buttons["bubble.fire"].tap()
    waitForShots(1, in: app)
    XCTAssertEqual(app.selectedFeedCardID, position)
    app.nextFeedCard()
    app.previousFeedCard()
    reveal(app.buttons["game.start"], in: app)
    XCTAssertTrue(app.buttons["game.start"].isHittable)
  }

  @MainActor
  func testNativeHorizontalAndDiagonalAimDragsDoNotPage() {
    let app = launch()
    start(app)
    let slider = app.sliders["bubble.aim"]
    reveal(slider, in: app)
    let position = app.selectedFeedCardID
    let center = slider.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
    let right = slider.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5))
    center.press(
      forDuration: 0.01, thenDragTo: right, withVelocity: .slow, thenHoldForDuration: 0.1)
    let afterHorizontal = observedAim(in: app)
    XCTAssertNotEqual(afterHorizontal, "Aim: 0 degrees")
    XCTAssertEqual(app.selectedFeedCardID, position)
    slider.adjust(toNormalizedSliderPosition: 0.5)
    let diagonal = slider.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.65))
    center.press(
      forDuration: 0.01, thenDragTo: diagonal, withVelocity: .slow, thenHoldForDuration: 0.1)
    XCTAssertNotEqual(
      observedAim(in: app), "Aim: 0 degrees")
    XCTAssertEqual(app.selectedFeedCardID, position)
    XCTAssertEqual(app.staticTexts["bubble.shots"].label, "Shots: 0 of 8")
    fire(app, aim: 0.5, expectedShots: 1)
    XCTAssertEqual(app.selectedFeedCardID, position)
  }

  @MainActor
  func testDirectAimHorizontalVerticalAndDiagonalStayInTheirOwnedAreaUntilFire() {
    let app = launch()
    start(app)
    let aim = app.otherElements["bubble.directAim"]
    let board = app.otherElements["bubble.board"]
    let slider = app.sliders["bubble.aim"]
    let fire = app.buttons["bubble.fire"]
    let viewport = app.scrollViews["feed.cardScroll"]
    XCTAssertTrue(aim.exists)
    XCTAssertGreaterThanOrEqual(aim.frame.width + 0.001, 44)
    XCTAssertGreaterThanOrEqual(aim.frame.height + 0.001, 44)
    let frames = [board.frame, aim.frame, slider.frame, fire.frame, viewport.frame]
    let position = app.selectedFeedCardID
    for (name, from, to) in [
      ("launcher-origin-horizontal", CGVector(dx: 0.5, dy: 0.8), CGVector(dx: 0.8, dy: 0.8)),
      ("horizontal", CGVector(dx: 0.5, dy: 0.2), CGVector(dx: 0.8, dy: 0.2)),
      ("vertical", CGVector(dx: 0.8, dy: 0.1), CGVector(dx: 0.8, dy: 0.5)),
      ("diagonal", CGVector(dx: 0.5, dy: 0.1), CGVector(dx: 0.2, dy: 0.4)),
    ] {
      aim.coordinate(withNormalizedOffset: from).tap()
      let initialAngle = observedAim(in: app)
      aim.coordinate(withNormalizedOffset: from).press(
        forDuration: 0.01, thenDragTo: aim.coordinate(withNormalizedOffset: to),
        withVelocity: .slow, thenHoldForDuration: 0.1)
      capture(app, name: "direct-aim-\(name)")
      if name == "vertical" {
        XCTAssertEqual(observedAim(in: app), initialAngle)
      } else {
        XCTAssertNotEqual(observedAim(in: app), initialAngle)
      }
      XCTAssertFalse(app.staticTexts["bubble.angle"].exists)
      XCTAssertEqual(app.selectedFeedCardID, position)
      XCTAssertEqual([board.frame, aim.frame, slider.frame, fire.frame, viewport.frame], frames)
      XCTAssertEqual(app.staticTexts["bubble.shots"].label, "Shots: 0 of 8")
      XCTAssertTrue(fire.isEnabled)
    }
    // Straight direct aim preserves the real first-shot solution, but release never shoots.
    aim.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)).tap()
    XCTAssertEqual(observedAim(in: app), "Aim: 0 degrees")
    fire.tap()
    waitForShots(1, in: app)
    XCTAssertEqual(app.selectedFeedCardID, position)
    XCTAssertEqual([board.frame, aim.frame, slider.frame, fire.frame, viewport.frame], frames)
    // A full settled swipe above the dedicated control still pages and resets the unfinished game.
    app.scrollViews["feed.pager"].coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.85))
      .press(
        forDuration: 0.01,
        thenDragTo: app.scrollViews["feed.pager"].coordinate(
          withNormalizedOffset: CGVector(dx: 0.05, dy: 0.05)), withVelocity: .fast,
        thenHoldForDuration: 0.1)
    waitForPosition("sample-news-garden", in: app)
    app.previousFeedCard()
    XCTAssertTrue(app.buttons["game.start"].waitForExistence(timeout: 5))
    XCTAssertEqual(app.staticTexts["bubble.shots"].label, "Shots: 0 of 8")
  }

  @MainActor
  func testBackgroundDuringDirectAimedFlightReturnsToFrozenPreview() {
    let app = launch(slowShot: true)
    start(app)
    let aim = app.otherElements["bubble.directAim"]
    aim.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.2)).tap()
    XCTAssertNotEqual(
      observedAim(in: app), "Aim: 0 degrees")
    app.buttons["bubble.fire"].tap()
    XCTAssertEqual(app.staticTexts["bubble.feedback"].label, "Shot in flight.")
    XCTAssertFalse(app.sliders["bubble.aim"].isEnabled)
    XCUIDevice.shared.press(.home)
    app.activate()
    XCTAssertTrue(app.buttons["game.start"].waitForExistence(timeout: 5))
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
    reveal(app.buttons["bubble.fire"], in: app)
    app.buttons["bubble.fire"].tap()
    XCTAssertEqual(app.staticTexts["bubble.feedback"].label, "Shot in flight.")
    let pager = app.scrollViews["feed.pager"]
    for _ in 0..<3 {
      if app.selectedFeedCardID != "sample-game-bubbleShooter" { break }
      pager.swipeUp(velocity: .fast)
    }
    waitForPosition("sample-news-garden", in: app)
    pager.swipeDown(velocity: .fast)
    waitForPosition("sample-game-bubbleShooter", in: app)
    XCTAssertTrue(app.buttons["game.start"].exists)
    XCTAssertTrue(app.buttons["bubble.fire"].exists)
    XCTAssertFalse(app.buttons["bubble.fire"].isEnabled)
    start(app)
    fire(app, aim: 0.5, expectedShots: 1)
  }

  @MainActor
  func testSystemReduceMotionKeepsPendingShotStationary() {
    continueAfterFailure = false
    SystemAccessibilitySupport.withReduceMotion {
      let app = launch(slowShot: true)
      start(app)
      let direct = app.otherElements["bubble.directAim"]
      direct.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)).tap()
      XCTAssertEqual(
        observedAim(in: app), "Aim: 0 degrees")
      XCTAssertEqual(app.staticTexts["bubble.shots"].label, "Shots: 0 of 8")
      reveal(app.buttons["bubble.fire"], in: app)
      app.buttons["bubble.fire"].tap()
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
    let value = app.otherElements["bubble.directAim"].value as? String ?? ""
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
    XCTAssertFalse(app.otherElements["bubble.directAim"].exists)
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
    app.launch()
    XCTAssertTrue(app.buttons["game.start"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts["Bubble shooter"].exists)
    XCTAssertTrue(app.buttons["bubble.fire"].exists)
    XCTAssertFalse(app.buttons["bubble.fire"].isEnabled)
    return app
  }

  @MainActor
  private func start(_ app: XCUIApplication) {
    app.buttons["game.start"].tap()
    XCTAssertTrue(app.otherElements["bubble.board"].waitForExistence(timeout: 5))
    XCTAssertEqual(app.staticTexts["bubble.shots"].label, "Shots: 0 of 8")
  }

  @MainActor
  private func fire(_ app: XCUIApplication, aim: Double, expectedShots: Int) {
    reveal(app.sliders["bubble.aim"], in: app)
    if aim != 0.5 { app.sliders["bubble.aim"].adjust(toNormalizedSliderPosition: 0.9) }
    app.sliders["bubble.aim"].adjust(toNormalizedSliderPosition: aim)
    if aim != 0.5 {
      let angle = Double(
        observedAim(in: app).filter {
          $0.isNumber || $0 == "-"
        })
      XCTAssertNotNil(angle)
      XCTAssertTrue(
        (6...30).contains(angle ?? -60), "Actual aiming must reach the demonstrated winning window."
      )
    }
    reveal(app.buttons["bubble.fire"], in: app)
    XCTAssertTrue(app.buttons["bubble.fire"].isEnabled)
    XCTAssertGreaterThanOrEqual(app.buttons["bubble.fire"].frame.height + 0.001, 44)
    XCTAssertGreaterThanOrEqual(app.buttons["bubble.fire"].frame.width + 0.001, 44)
    app.buttons["bubble.fire"].tap()
    waitForShots(expectedShots, in: app)
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
