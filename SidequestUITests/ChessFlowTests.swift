import XCTest

final class ChessFlowTests: XCTestCase {
  @MainActor
  func testCoordinateAlternativesHaveUsableTargetsAndAcceptEdgeTaps() {
    let app = launch(color: "white")
    app.buttons["game.start"].tap()
    tapEdge(app.buttons["chess.piece.g6"], in: app)
    XCTAssertTrue(app.staticTexts["chess.selection"].label.contains("g6"))
    tapEdge(app.buttons["chess.file"], in: app)
    XCTAssertTrue(app.buttons["File G"].waitForExistence(timeout: 3))
    app.buttons["File G"].tap()
    tapEdge(app.buttons["chess.rank"], in: app)
    XCTAssertTrue(app.buttons["Rank 7"].waitForExistence(timeout: 3))
    app.buttons["Rank 7"].tap()
    tapEdge(app.buttons["chess.submit"], in: app)
    XCTAssertTrue(app.staticTexts["chess.completed"].waitForExistence(timeout: 3))
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
    XCTAssertTrue(app.buttons["game.start"].isHittable)
    XCTAssertTrue(app.buttons["feed.next"].isHittable)
    app.buttons["game.start"].tap()
    submit(app, queen: "b3", destination: "b2")
    reveal(app.staticTexts["chess.completed"], in: app)
    XCTAssertTrue(app.staticTexts["chess.completed"].isHittable)
    XCTAssertTrue(app.buttons["feed.next"].isHittable)
    app.buttons["feed.next"].tap()
    XCTAssertTrue(app.buttons["feed.previous"].isHittable)
    app.buttons["feed.previous"].tap()
    XCTAssertTrue(app.staticTexts["chess.completed"].exists)
    XCTAssertFalse(app.buttons["game.start"].exists)
  }

  @MainActor
  private func checkFixture(
    color: String, queen: String, opponent: String, wrong: String, mate: String
  ) {
    let app = launch(color: color)
    XCTAssertFalse(app.buttons["chess.square.\(queen)"].exists)
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
    submit(app, queen: queen, destination: queen)
    reveal(app.staticTexts["chess.feedback"], in: app)
    XCTAssertTrue(app.staticTexts["chess.feedback"].label.contains("not legal"))
    reveal(app.buttons["chess.piece.\(queen)"], in: app)
    app.buttons["chess.piece.\(queen)"].tap()
    app.buttons["feed.next"].tap()
    app.buttons["feed.previous"].tap()
    XCTAssertTrue(app.buttons["game.start"].exists)
    app.buttons["game.start"].tap()
    XCTAssertEqual(app.staticTexts["chess.selection"].label, "No piece selected")
    XCTAssertFalse(app.staticTexts["chess.feedback"].exists)
    submit(app, queen: queen, destination: mate)
    XCTAssertTrue(app.staticTexts["chess.completed"].waitForExistence(timeout: 5))
    reveal(app.buttons["chess.square.\(queen)"], in: app)
    XCTAssertTrue(app.buttons["chess.square.\(queen)"].label.contains("Empty square"))
    reveal(app.buttons["chess.square.\(mate)"], in: app)
    XCTAssertTrue(app.buttons["chess.square.\(mate)"].label.contains("queen"))
    XCTAssertFalse(app.buttons["chess.square.\(mate)"].isEnabled)
    capture(app, name: "chess-\(color)-solved")
    app.buttons["feed.next"].tap()
    app.buttons["feed.previous"].tap()
    XCTAssertTrue(app.staticTexts["chess.completed"].exists)
    reveal(app.buttons["chess.square.\(mate)"], in: app)
    XCTAssertTrue(app.buttons["chess.square.\(mate)"].label.contains("queen"))
    XCTAssertFalse(app.buttons["game.start"].exists)
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
    let scroll = app.scrollViews.firstMatch
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
  private func launch(color: String, largeText: Bool = false) -> XCUIApplication {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments =
      ["-sidequest-chess-\(color)-fixture"]
      + (largeText ? ["-sidequest-large-text"] : [])
    app.launch()
    XCTAssertTrue(app.buttons["game.start"].waitForExistence(timeout: 5))
    return app
  }
}
