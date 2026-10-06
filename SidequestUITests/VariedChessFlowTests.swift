import XCTest

final class VariedChessFlowTests: XCTestCase {
  @MainActor
  func testThreeSquareBothColorsStartResetAndCompletedRevisit() {
    for color in ["white", "black"] {
      let app = launch(size: 3, color: color)
      let queen = color == "white" ? "c2" : "c7"
      let mate = color == "white" ? "b2" : "b7"
      let board = assertWindow(app, size: 3, color: color)
      for target in board {
        assertTarget(target, viewport: app.scrollViews["feed.cardScroll"].frame)
      }
      let stableBoard = board.filter { $0.identifier != "chess.square.\(queen)" }
      let frames = stableBoard.map(\.frame)
      XCTAssertTrue(app.buttons["chess.square.\(queen)"].isEnabled)
      XCTAssertEqual(app.staticTexts["chess.selection"].label, "No piece selected")
      app.buttons["chess.square.\(queen)"].tap()
      XCTAssertTrue(app.staticTexts["chess.selection"].label.contains(queen))
      XCTAssertFalse(app.staticTexts["chess.feedback"].exists)
      XCTAssertEqual(stableBoard.map(\.frame), frames)
      navigate(app, color: color, forward: true)
      navigate(app, color: color, forward: false)
      assertWindow(app, size: 3, color: color)
      XCTAssertFalse(app.buttons["game.start"].exists)
      XCTAssertEqual(app.staticTexts["chess.selection"].label, "No piece selected")
      submit(app, queen: queen, destination: mate)
      assertCompletedRevisit(app, size: 3, color: color, mate: mate)
      app.terminate()
    }
  }

  @MainActor
  func testFiveSquareBothColorsFitAndCoordinateMoves() {
    for color in ["white", "black"] {
      let app = launch(size: 5, color: color)
      let queen = color == "white" ? "e1" : "e8"
      let mate = color == "white" ? "a5" : "a4"
      let outside = color == "white" ? "h1" : "h8"
      let board = assertWindow(app, size: 5, color: color)
      let controls = [app.buttons["chess.square.\(queen)"]]
      let viewport = app.scrollViews["feed.cardScroll"].frame
      for target in board + controls {
        assertTarget(target, viewport: viewport)
      }
      capture(app, name: "five-square-\(color)-preview-all-controls")
      let stableBoard = board.filter { $0.identifier != "chess.square.\(queen)" }
      let frames = stableBoard.map(\.frame)
      XCTAssertEqual(app.staticTexts["chess.selection"].label, "No piece selected")
      XCTAssertFalse(app.buttons["chess.square.\(outside)"].exists)
      let nonmate = color == "white" ? "e2" : "e7"
      submit(app, queen: queen, destination: nonmate)
      XCTAssertTrue(app.staticTexts["chess.feedback"].label.contains("not checkmate"))
      XCTAssertTrue(app.buttons["chess.square.\(queen)"].label.contains("queen"))
      XCTAssertEqual(stableBoard.map(\.frame), frames)
      submit(app, queen: queen, destination: mate)
      assertCompletedRevisit(app, size: 5, color: color, mate: mate)
      app.terminate()
    }
  }

  @MainActor
  func testLargestFiveSquareBlackCoordinatesAndRevisit() {
    let app = launch(size: 5, color: "black", largeText: true)
    let board = assertWindow(app, size: 5, color: "black")
    for target in board {
      reveal(target, in: app)
      assertTarget(target, viewport: app.scrollViews["feed.cardScroll"].frame)
    }
    XCTAssertEqual(app.staticTexts["chess.selection"].label, "No piece selected")
    submit(app, queen: "e8", destination: "a4")
    reveal(app.staticTexts["chess.completed"], in: app)
    capture(app, name: "five-square-black-largest-completed")
    assertCompletedRevisit(app, size: 5, color: "black", mate: "a4")
  }

  @MainActor
  @discardableResult
  private func assertWindow(_ app: XCUIApplication, size: Int, color: String) -> [XCUIElement] {
    let files = Array("abcde").prefix(size).map(String.init)
    let ranks = color == "white" ? Array(1...size) : Array((9 - size)...8)
    let range =
      color == "white" ? "a1–\(files[size - 1])\(size)" : "a\(9 - size)–\(files[size - 1])8"
    XCTAssertTrue(app.staticTexts["chess.focus"].label.contains(range))
    XCTAssertTrue(app.staticTexts["chess.focus"].label.contains("Standard 8×8 rules"))
    let board = ranks.flatMap { rank in files.map { app.buttons["chess.square.\($0)\(rank)"] } }
    for square in board { XCTAssertTrue(square.exists) }
    XCTAssertEqual(
      app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'chess.square.'")).count,
      size * size)
    return board
  }

  @MainActor
  private func submit(_ app: XCUIApplication, queen: String, destination: String) {
    for coordinate in [queen, destination] {
      let control = app.buttons["chess.square.\(coordinate)"]
      reveal(control, in: app)
      assertTarget(control, viewport: app.scrollViews["feed.cardScroll"].frame)
      XCTAssertTrue(control.isEnabled)
      control.tap()
      if coordinate == queen {
        XCTAssertTrue(app.staticTexts["chess.selection"].label.contains(queen))
      }
    }
  }

  @MainActor
  private func assertCompletedRevisit(
    _ app: XCUIApplication, size: Int, color: String, mate: String
  ) {
    XCTAssertTrue(app.staticTexts["chess.completed"].waitForExistence(timeout: 5))
    reveal(app.buttons["chess.square.\(mate)"], in: app)
    XCTAssertTrue(app.buttons["chess.square.\(mate)"].label.contains("queen"))
    XCTAssertFalse(app.buttons["chess.square.\(mate)"].isEnabled)
    navigate(app, color: color, forward: true)
    navigate(app, color: color, forward: false)
    assertWindow(app, size: size, color: color)
    XCTAssertTrue(app.staticTexts["chess.completed"].exists)
    XCTAssertFalse(app.buttons["game.start"].exists)
    XCTAssertFalse(app.staticTexts["game.successCelebration"].exists)
  }

  @MainActor
  private func navigate(_ app: XCUIApplication, color: String, forward: Bool) {
    if forward { app.nextFeedCard() } else { app.previousFeedCard() }
    app.waitForFeedCard(forward ? "sample-news-garden" : "sample-game-chess-\(color)")
  }

  @MainActor
  private func assertTarget(_ target: XCUIElement, viewport: CGRect) {
    XCTAssertTrue(target.exists)
    XCTAssertTrue(viewport.contains(target.frame), "Whole target must fit: \(target.identifier)")
    XCTAssertGreaterThanOrEqual(target.frame.width, 44)
    XCTAssertGreaterThanOrEqual(target.frame.height, 44)
  }

  @MainActor
  private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
    let scroll = app.scrollViews["feed.cardScroll"].firstMatch
    for _ in 0..<18 {
      if element.exists && element.isHittable && scroll.frame.contains(element.frame) { return }
      let upwards = !element.exists || element.frame.midY > scroll.frame.midY
      let start = scroll.coordinate(withNormalizedOffset: .zero).withOffset(
        .init(dx: 8, dy: scroll.frame.height * (upwards ? 0.7 : 0.3)))
      let end = scroll.coordinate(withNormalizedOffset: .zero).withOffset(
        .init(dx: 8, dy: scroll.frame.height * (upwards ? 0.4 : 0.6)))
      start.press(forDuration: 0, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0)
    }
    XCTFail("Full target unreachable: \(element.identifier) \(element.frame) in \(scroll.frame)")
  }

  @MainActor
  private func capture(_ app: XCUIApplication, name: String) {
    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }

  @MainActor
  private func launch(size: Int, color: String, largeText: Bool = false) -> XCUIApplication {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments =
      [
        "-sidequest-chess-\(color)-fixture", "-sidequest-chess-catalog",
        "hard-\(size == 3 ? "three" : "five")-\(color)",
      ] + (largeText ? ["-sidequest-large-text"] : [])
    app.launch()
    XCTAssertTrue(app.staticTexts["chess.selection"].waitForExistence(timeout: 5))
    XCTAssertEqual(app.staticTexts["chess.selection"].label, "No piece selected")
    XCTAssertFalse(app.buttons["game.start"].exists)
    return app
  }
}
