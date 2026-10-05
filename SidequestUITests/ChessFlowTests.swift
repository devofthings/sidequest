import XCTest

final class ChessFlowTests: XCTestCase {
  @MainActor
  func testCoordinateAlternativesHaveUsableTargetsAndAcceptEdgeTaps() {
    let app = launch(color: "white", successFeedback: false)
    app.buttons["game.start"].tap()
    tapEdge(app.buttons["chess.piece.g6"], in: app)
    XCTAssertTrue(app.staticTexts["chess.selection"].label.contains("g6"))
    tapEdge(app.buttons["chess.file"], in: app)
    XCTAssertTrue(app.buttons["File G"].waitForExistence(timeout: 3))
    app.buttons["File G"].tap()
    tapEdge(app.buttons["chess.rank"], in: app)
    XCTAssertTrue(app.buttons["Rank 7"].waitForExistence(timeout: 3))
    app.buttons["Rank 7"].tap()
    reveal(app.buttons["chess.submit"], in: app)
    let viewport = app.scrollViews["feed.cardScroll"].frame
    let submitFrame = app.buttons["chess.submit"].frame
    tapEdge(app.buttons["chess.submit"], in: app)
    assertSuccessVisible(app)
    XCTAssertEqual(app.scrollViews["feed.cardScroll"].frame, viewport)
    XCTAssertEqual(app.buttons["chess.submit"].frame, submitFrame)
    let expired = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "exists == false"),
      object: app.staticTexts["game.successCelebration"])
    XCTAssertEqual(XCTWaiter.wait(for: [expired], timeout: 5), .completed)
    XCTAssertTrue(app.staticTexts["chess.completed"].exists)
    XCTAssertTrue(app.staticTexts["foundation.title"].exists)
    XCTAssertEqual(app.scrollViews["feed.cardScroll"].frame, viewport)
    XCTAssertEqual(app.buttons["chess.submit"].frame, submitFrame)
  }

  @MainActor
  func testNormalPocketBoardAndAllMoveControlsFitTogether() {
    for color in ["white", "black"] {
      let app = launch(color: color)
      assertWindow(app, color: color)
      let viewport = app.scrollViews["feed.cardScroll"].frame
      let files = color == "white" ? ["e", "f", "g", "h"] : ["a", "b", "c", "d"]
      let ranks = color == "white" ? [8, 7, 6, 5] : [4, 3, 2, 1]
      let board = ranks.flatMap { rank in files.map { app.buttons["chess.square.\($0)\(rank)"] } }
      let pieces = color == "white" ? ["f7", "g6"] : ["b3", "c2"]
      let controls =
        pieces.map { app.buttons["chess.piece.\($0)"] }
        + [app.buttons["chess.file"], app.buttons["chess.rank"], app.buttons["chess.submit"]]
      for target in board + controls + [app.buttons["game.start"]] {
        XCTAssertTrue(target.exists)
        XCTAssertTrue(viewport.contains(target.frame), "Full target must fit: \(target.identifier)")
        XCTAssertGreaterThanOrEqual(target.frame.width, 44)
        XCTAssertGreaterThanOrEqual(target.frame.height, 44)
      }
      let before = (board + controls).map(\.frame)
      let attachment = XCTAttachment(screenshot: app.screenshot())
      attachment.name = "pocket-\(color)-normal-all-controls"
      attachment.lifetime = .keepAlways
      add(attachment)
      app.buttons["game.start"].tap()
      XCTAssertEqual((board + controls).map(\.frame), before)
      XCTAssertEqual(app.scrollViews["feed.cardScroll"].frame, viewport)
      XCTAssertEqual(app.staticTexts["chess.selection"].label, "No piece selected")
      app.terminate()
    }
  }

  @MainActor
  func testWhiteFixtureWrongMovesResetAndCompletedRevisit() {
    checkFixture(color: "white", queen: "g6", opponent: "h8", wrong: "g5", mate: "g7")
  }

  @MainActor
  func testBlackFixtureWrongMovesResetAndCompletedRevisit() {
    checkFixture(color: "black", queen: "b3", opponent: "a1", wrong: "b4", mate: "b2")
  }

  @MainActor
  func testBackgroundRequiresFreshChessStart() {
    let app = launch(color: "white")
    app.buttons["game.start"].tap()
    app.buttons["chess.square.g6"].tap()
    XCTAssertTrue(app.staticTexts["chess.selection"].label.contains("g6"))
    XCUIDevice.shared.press(.home)
    app.activate()
    XCTAssertTrue(app.buttons["game.start"].waitForExistence(timeout: 5))
    app.buttons["game.start"].tap()
    XCTAssertEqual(app.staticTexts["chess.selection"].label, "No piece selected")
    XCTAssertFalse(app.staticTexts["chess.feedback"].exists)
  }

  @MainActor
  func testLargestTextSupportsCoordinateSolutionAndNavigation() {
    let app = launch(color: "black", largeText: true)
    assertWindow(app, color: "black")
    XCTAssertTrue(app.buttons["game.start"].isHittable)
    XCTAssertTrue(app.buttons["feed.navigation"].isHittable)
    app.buttons["game.start"].tap()
    submit(app, queen: "b3", destination: "b2")
    assertSuccessVisible(app)
    capture(app, name: "largest-chess-viewport-success")
    reveal(app.staticTexts["chess.completed"], in: app)
    XCTAssertTrue(app.staticTexts["chess.completed"].isHittable)
    XCTAssertTrue(app.buttons["feed.navigation"].isHittable)
    navigate(app, forward: true)
    XCTAssertTrue(app.buttons["feed.navigation"].isHittable)
    navigate(app, forward: false)
    XCTAssertFalse(app.staticTexts["game.successCelebration"].exists)
    XCTAssertTrue(app.staticTexts["chess.completed"].exists)
    XCTAssertFalse(app.buttons["game.start"].exists)
  }

  @MainActor
  private func checkFixture(
    color: String, queen: String, opponent: String, wrong: String, mate: String
  ) {
    let app = launch(color: color)
    assertWindow(app, color: color)
    XCTAssertTrue(app.buttons["chess.square.\(queen)"].exists)
    XCTAssertFalse(app.buttons["chess.square.\(queen)"].isEnabled)
    app.buttons["game.start"].tap()
    XCTAssertTrue(app.staticTexts["chess.side"].label.hasPrefix(color.capitalized))
    XCTAssertEqual(app.staticTexts["chess.selection"].label, "No piece selected")
    XCTAssertFalse(app.staticTexts["chess.feedback"].exists)
    XCTAssertTrue(app.buttons["chess.square.\(queen)"].label.contains("queen"))
    capture(app, name: "chess-\(color)-started")
    app.buttons["chess.square.\(opponent)"].tap()
    XCTAssertEqual(app.staticTexts["chess.selection"].label, "No piece selected")
    reveal(app.staticTexts["chess.feedback"], in: app)
    XCTAssertTrue(app.staticTexts["chess.feedback"].label.hasPrefix("Select a"))
    submit(app, queen: queen, destination: wrong)
    reveal(app.staticTexts["chess.feedback"], in: app)
    XCTAssertTrue(app.staticTexts["chess.feedback"].label.contains("not checkmate"))
    reveal(app.buttons["chess.square.\(queen)"], in: app)
    XCTAssertTrue(app.buttons["chess.square.\(queen)"].label.contains("queen"))
    reveal(app.buttons["chess.square.\(wrong)"], in: app)
    XCTAssertTrue(app.buttons["chess.square.\(wrong)"].label.contains("Empty square"))
    let outside = color == "white" ? "a6" : "h3"
    XCTAssertFalse(app.buttons["chess.square.\(outside)"].exists)
    submit(app, queen: queen, destination: outside)
    reveal(app.staticTexts["chess.feedback"], in: app)
    XCTAssertTrue(app.staticTexts["chess.feedback"].label.contains("not checkmate"))
    assertWindow(app, color: color)
    submit(app, queen: queen, destination: queen)
    reveal(app.staticTexts["chess.feedback"], in: app)
    XCTAssertTrue(app.staticTexts["chess.feedback"].label.contains("not legal"))
    reveal(app.buttons["chess.piece.\(queen)"], in: app)
    app.buttons["chess.piece.\(queen)"].tap()
    navigate(app, forward: true)
    navigate(app, forward: false)
    XCTAssertTrue(app.buttons["game.start"].exists)
    app.buttons["game.start"].tap()
    XCTAssertEqual(app.staticTexts["chess.selection"].label, "No piece selected")
    XCTAssertFalse(app.staticTexts["chess.feedback"].exists)
    submit(app, queen: queen, destination: mate)
    assertSuccessVisible(app)
    capture(app, name: "chess-\(color)-success-celebration")
    XCTAssertTrue(app.staticTexts["chess.completed"].waitForExistence(timeout: 5))
    reveal(app.buttons["chess.square.\(queen)"], in: app)
    XCTAssertTrue(app.buttons["chess.square.\(queen)"].label.contains("Empty square"))
    reveal(app.buttons["chess.square.\(mate)"], in: app)
    XCTAssertTrue(app.buttons["chess.square.\(mate)"].label.contains("queen"))
    XCTAssertFalse(app.buttons["chess.square.\(mate)"].isEnabled)
    capture(app, name: "chess-\(color)-solved")
    navigate(app, forward: true)
    navigate(app, forward: false)
    XCTAssertFalse(app.staticTexts["game.successCelebration"].exists)
    XCTAssertTrue(app.staticTexts["chess.completed"].exists)
    reveal(app.buttons["chess.square.\(mate)"], in: app)
    XCTAssertTrue(app.buttons["chess.square.\(mate)"].label.contains("queen"))
    XCTAssertFalse(app.buttons["game.start"].exists)
    assertWindow(app, color: color)
  }

  @MainActor
  private func assertWindow(_ app: XCUIApplication, color: String) {
    let range = color == "white" ? "e5–h8" : "a1–d4"
    XCTAssertTrue(app.staticTexts["chess.focus"].label.contains(range))
    XCTAssertTrue(app.staticTexts["chess.focus"].label.contains("Standard 8×8 rules"))
    let corners = color == "white" ? ["e8", "h8", "e5", "h5"] : ["a4", "d4", "a1", "d1"]
    for corner in corners { XCTAssertTrue(app.buttons["chess.square.\(corner)"].exists) }
    XCTAssertEqual(
      app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "chess.square.")).count,
      16)
    XCTAssertFalse(app.buttons["chess.square.\(color == "white" ? "a1" : "h8")"].exists)
  }

  @MainActor
  private func assertSuccessVisible(_ app: XCUIApplication) {
    let badge = app.staticTexts["game.successCelebration"]
    XCTAssertTrue(badge.waitForExistence(timeout: 5))
    let badgeFrame = badge.frame
    XCTAssertTrue(app.frame.contains(badgeFrame), "The whole celebration must be on screen.")
    XCTAssertLessThanOrEqual(
      badgeFrame.maxY, app.scrollViews["feed.cardScroll"].frame.minY + 1,
      "Celebration stays in the fixed header after scrolling to Chess controls.")
    XCTAssertTrue(badge.label.contains("Chess puzzle completed"))
  }

  @MainActor
  private func navigate(_ app: XCUIApplication, forward: Bool) {
    if forward { app.nextFeedCard() } else { app.previousFeedCard() }
    let side = app.launchArguments.contains("-sidequest-chess-black-fixture") ? "black" : "white"
    app.waitForFeedCard(forward ? "sample-news-garden" : "sample-game-chess-\(side)")
  }

  @MainActor
  private func submit(_ app: XCUIApplication, queen: String, destination: String) {
    let piece = app.buttons["chess.piece.\(queen)"]
    reveal(piece, in: app)
    piece.tap()
    let file = app.buttons["chess.file"]
    reveal(file, in: app)
    file.tap()
    let fileOption = app.buttons["File \(destination.prefix(1).uppercased())"]
    XCTAssertTrue(fileOption.waitForExistence(timeout: 3))
    fileOption.tap()
    let rank = app.buttons["chess.rank"]
    reveal(rank, in: app)
    rank.tap()
    let rankOption = app.buttons["Rank \(destination.suffix(1))"]
    XCTAssertTrue(rankOption.waitForExistence(timeout: 3))
    rankOption.tap()
    let submit = app.buttons["chess.submit"]
    reveal(submit, in: app)
    XCTAssertTrue(submit.isEnabled)
    if app.launchArguments.contains("-sidequest-large-text") {
      capture(app, name: "chess-largest-coordinate-submit")
    }
    submit.tap()
  }

  @MainActor
  private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
    let scroll = app.scrollViews["feed.cardScroll"].firstMatch
    for fallbackUpwards in [true, false] {
      for _ in 0..<12 {
        if element.exists && element.isHittable && scroll.frame.contains(element.frame) { return }
        let upwards: Bool
        if element.exists {
          upwards = element.frame.midY > scroll.frame.midY
        } else {
          upwards = fallbackUpwards
        }
        let start = scroll.coordinate(
          withNormalizedOffset: CGVector(dx: 0.5, dy: upwards ? 0.65 : 0.35))
        let end = scroll.coordinate(
          withNormalizedOffset: CGVector(dx: 0.5, dy: upwards ? 0.4 : 0.6))
        start.press(
          forDuration: 0, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0)
      }
    }
    XCTAssertTrue(element.isHittable)
    XCTAssertTrue(
      scroll.frame.contains(element.frame),
      "Bring the entire control into view before tapping: \(element.identifier) \(element.frame) in \(scroll.frame)."
    )
  }

  @MainActor
  private func tapEdge(_ element: XCUIElement, in app: XCUIApplication) {
    reveal(element, in: app)
    XCTAssertGreaterThanOrEqual(element.frame.width, 44)
    XCTAssertGreaterThanOrEqual(element.frame.height, 44)
    element.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.8)).tap()
  }

  @MainActor
  private func capture(_ app: XCUIApplication, name: String) {
    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }

  @MainActor
  private func launch(color: String, largeText: Bool = false, successFeedback: Bool = true)
    -> XCUIApplication
  {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments =
      ["-sidequest-chess-\(color)-fixture"]
      + (successFeedback ? ["-sidequest-success-feedback-test"] : [])
      + (largeText ? ["-sidequest-large-text"] : [])
    app.launch()
    XCTAssertTrue(app.buttons["game.start"].waitForExistence(timeout: 5))
    return app
  }
}
