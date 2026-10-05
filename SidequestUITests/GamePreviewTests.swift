import XCTest

@MainActor
final class GamePreviewTests: XCTestCase {
  func testAllInitialBoardsRejectPreviewInputAndResetAfterSkipAndBackground() {
    for fixture in Fixture.allCases {
      let app = launch(fixture)
      assertPreview(app, fixture: fixture)
      let before = snapshot(app, fixture: fixture)
      anchor(app, fixture: fixture).coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        .tap()
      XCTAssertEqual(snapshot(app, fixture: fixture), before)
      capture(app, name: "preview-\(fixture.rawValue)-normal")
      let frame = anchor(app, fixture: fixture).frame
      app.buttons["game.start"].tap()
      XCTAssertFalse(app.buttons["game.start"].exists)
      XCTAssertEqual(snapshot(app, fixture: fixture), before)
      XCTAssertEqual(anchor(app, fixture: fixture).frame, frame)
      makeMove(app, fixture: fixture)
      app.nextFeedCard()
      app.previousFeedCard()
      assertPreview(app, fixture: fixture)
      XCTAssertEqual(snapshot(app, fixture: fixture), before)
      app.buttons["game.start"].tap()
      makeMove(app, fixture: fixture)
      XCUIDevice.shared.press(.home)
      app.activate()
      XCTAssertTrue(app.buttons["game.start"].waitForExistence(timeout: 5))
      assertPreview(app, fixture: fixture)
      XCTAssertEqual(snapshot(app, fixture: fixture), before)
      capture(app, name: "reset-preview-\(fixture.rawValue)-normal")
      app.terminate()
    }
  }

  func testLargestTextKeepsEveryInitialBoardAndStartReachableWithoutMovingTheBoard() {
    for fixture in Fixture.allCases {
      let app = launch(fixture, largeText: true)
      assertPreview(app, fixture: fixture)
      let before = snapshot(app, fixture: fixture)
      capture(app, name: "preview-\(fixture.rawValue)-largest-top")
      let frame = anchor(app, fixture: fixture).frame
      app.buttons["game.start"].tap()
      XCTAssertEqual(snapshot(app, fixture: fixture), before)
      XCTAssertEqual(anchor(app, fixture: fixture).frame, frame)
      reveal(lastBoardElement(app, fixture: fixture), in: app)
      capture(app, name: "started-\(fixture.rawValue)-largest-board-bottom")
      app.nextFeedCard()
      app.previousFeedCard()
      assertPreview(app, fixture: fixture)
      reveal(lastBoardElement(app, fixture: fixture), in: app)
      capture(app, name: "preview-\(fixture.rawValue)-largest-board-bottom")
      XCTAssertFalse(lastBoardElement(app, fixture: fixture).isEnabled)
      if fixture == .memory {
        XCTAssertEqual(lastBoardElement(app, fixture: fixture).label, "Hidden card 12")
      }
      reveal(app.buttons["game.start"], in: app)
      XCTAssertTrue(app.buttons["game.start"].isHittable)
      XCTAssertTrue(app.buttons["feed.navigation"].isHittable)
      app.terminate()
    }
  }

  private enum Fixture: String, CaseIterable {
    case sudoku, memory, chessWhite, chessBlack, bubble

    var argument: String {
      switch self {
      case .sudoku: "-sidequest-sudoku-test"
      case .memory: "-sidequest-memory-fixtures"
      case .chessWhite: "-sidequest-chess-white-fixture"
      case .chessBlack: "-sidequest-chess-black-fixture"
      case .bubble: "-sidequest-bubble-fixtures"
      }
    }
  }

  private func assertPreview(_ app: XCUIApplication, fixture: Fixture) {
    reveal(app.buttons["game.start"], in: app)
    XCTAssertTrue(app.buttons["game.start"].isEnabled)
    XCTAssertTrue(app.buttons["game.start"].isHittable)
    XCTAssertGreaterThanOrEqual(app.buttons["game.start"].frame.height + 0.001, 44)
    let element = anchor(app, fixture: fixture)
    XCTAssertTrue(element.exists)
    XCTAssertGreaterThan(element.frame.height, 0)
    XCTAssertTrue(app.scrollViews["feed.cardScroll"].frame.intersects(element.frame))
    if fixture != .bubble { XCTAssertFalse(element.isEnabled) }
    switch fixture {
    case .sudoku:
      XCTAssertFalse(app.buttons["sudoku.number.3"].isEnabled)
      XCTAssertFalse(element.isSelected)
    case .memory:
      for index in 0..<2 {
        XCTAssertEqual(app.buttons["memory.tile.\(index)"].label, "Hidden card \(index + 1)")
      }
    case .chessWhite, .chessBlack:
      XCTAssertEqual(app.staticTexts["chess.selection"].label, "No piece selected")
      XCTAssertFalse(app.staticTexts["chess.feedback"].exists)
      XCTAssertFalse(app.buttons["chess.submit"].isEnabled)
    case .bubble:
      XCTAssertFalse(app.buttons["bubble.fire"].isEnabled)
      XCTAssertFalse(app.sliders["bubble.aim"].isEnabled)
      XCTAssertEqual(app.staticTexts["bubble.angle"].label, "Aim: 0°")
      XCTAssertEqual(app.staticTexts["bubble.shots"].label, "Shots: 0 of 8")
      XCTAssertEqual(app.staticTexts["bubble.feedback"].label, "Clear matching groups of three.")
    }
  }

  private func anchor(_ app: XCUIApplication, fixture: Fixture) -> XCUIElement {
    switch fixture {
    case .sudoku: app.buttons["sudoku.cell.2"]
    case .memory: app.buttons["memory.tile.0"]
    case .chessWhite: app.buttons["chess.square.e8"]
    case .chessBlack: app.buttons["chess.square.a4"]
    case .bubble: app.otherElements["bubble.board"]
    }
  }

  private func lastBoardElement(_ app: XCUIApplication, fixture: Fixture) -> XCUIElement {
    switch fixture {
    case .sudoku: app.buttons["sudoku.cell.15"]
    case .memory: app.buttons["memory.tile.11"]
    case .chessWhite: app.buttons["chess.square.h5"]
    case .chessBlack: app.buttons["chess.square.d1"]
    case .bubble: app.buttons["bubble.fire"]
    }
  }

  private func snapshot(_ app: XCUIApplication, fixture: Fixture) -> [String] {
    switch fixture {
    case .sudoku:
      (0..<16).map { app.buttons["sudoku.cell.\($0)"].value as? String ?? "Missing" }
    case .memory:
      (0..<2).map { app.buttons["memory.tile.\($0)"].label }
    case .chessWhite, .chessBlack:
      (fixture == .chessWhite ? ["h8", "f7", "g6", "g7"] : ["a1", "c2", "b3", "b2"])
        .map { app.buttons["chess.square.\($0)"].label }
    case .bubble:
      [app.otherElements["bubble.board"].value as? String ?? "Missing"]
    }
  }

  private func makeMove(_ app: XCUIApplication, fixture: Fixture) {
    let element: XCUIElement
    switch fixture {
    case .sudoku: element = app.buttons["sudoku.cell.2"]
    case .memory: element = app.buttons["memory.tile.0"]
    case .chessWhite: element = app.buttons["chess.square.g6"]
    case .chessBlack: element = app.buttons["chess.square.b3"]
    case .bubble: element = app.buttons["bubble.fire"]
    }
    reveal(element, in: app)
    XCTAssertTrue(element.isEnabled)
    element.tap()
    switch fixture {
    case .sudoku: XCTAssertTrue(element.isSelected)
    case .memory: XCTAssertEqual(element.label, "Revealed star, card 1")
    case .chessWhite: XCTAssertTrue(app.staticTexts["chess.selection"].label.contains("g6"))
    case .chessBlack: XCTAssertTrue(app.staticTexts["chess.selection"].label.contains("b3"))
    case .bubble:
      XCTAssertEqual(app.staticTexts["bubble.feedback"].label, "Shot in flight.")
    }
  }

  private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
    let scroll = app.scrollViews["feed.cardScroll"]
    for _ in 0..<18 {
      if element.exists && element.isHittable && scroll.frame.contains(element.frame) { return }
      let upwards = !element.exists || element.frame.midY > scroll.frame.midY
      let start = scroll.coordinate(
        withNormalizedOffset: CGVector(dx: 0.9, dy: upwards ? 0.7 : 0.3))
      let end = scroll.coordinate(
        withNormalizedOffset: CGVector(dx: 0.9, dy: upwards ? 0.4 : 0.6))
      start.press(forDuration: 0, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0)
    }
    XCTAssertTrue(element.isHittable)
    XCTAssertTrue(scroll.frame.contains(element.frame), "Control must be fully visible.")
  }

  private func capture(_ app: XCUIApplication, name: String) {
    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }

  private func launch(_ fixture: Fixture, largeText: Bool = false) -> XCUIApplication {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments =
      [fixture.argument]
      + (largeText ? ["-sidequest-large-text"] : [])
      + (fixture == .bubble ? ["-sidequest-bubble-slow-shot"] : [])
    app.launch()
    XCTAssertTrue(app.buttons["game.start"].waitForExistence(timeout: 5))
    return app
  }
}
