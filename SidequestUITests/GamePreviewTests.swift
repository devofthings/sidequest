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
      assertPreview(app, fixture: fixture, allowBoardOverflow: true)
      let before = snapshot(app, fixture: fixture)
      let first = anchor(app, fixture: fixture)
      let last = lastBoardElement(app, fixture: fixture)
      reveal(first, in: app)
      XCTAssertTrue(app.scrollViews["feed.cardScroll"].frame.contains(first.frame))
      if fixture != .bubble { XCTAssertFalse(first.isEnabled) }
      capture(app, name: "preview-\(fixture.rawValue)-largest-board-top")
      reveal(last, in: app)
      XCTAssertTrue(app.scrollViews["feed.cardScroll"].frame.contains(last.frame))
      XCTAssertFalse(last.isEnabled)
      if fixture == .memory { XCTAssertEqual(last.label, "Hidden card 12") }
      XCTAssertEqual(snapshot(app, fixture: fixture), before)
      capture(app, name: "preview-\(fixture.rawValue)-largest-board-bottom-before-start")
      // Establish the start baseline only after restoring its viewport; tapping must not auto-scroll.
      reveal(app.buttons["game.start"], in: app)
      let viewport = app.scrollViews["feed.cardScroll"].frame
      let frame = first.frame
      app.buttons["game.start"].tap()
      XCTAssertEqual(snapshot(app, fixture: fixture), before)
      XCTAssertEqual(first.frame, frame)
      XCTAssertEqual(app.scrollViews["feed.cardScroll"].frame, viewport)
      reveal(lastBoardElement(app, fixture: fixture), in: app)
      capture(app, name: "started-\(fixture.rawValue)-largest-board-bottom")
      app.nextFeedCard()
      app.previousFeedCard()
      assertPreview(app, fixture: fixture, allowBoardOverflow: true)
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

  func testEveryNormalPocketBoardAndPrimaryControlFitsWithoutScrollingAcrossStart() {
    for fixture in Fixture.allCases {
      let app = launch(fixture)
      let viewport = app.scrollViews["feed.cardScroll"]
      let board = completeBoard(app, fixture: fixture)
      let controls = primaryControls(app, fixture: fixture)
      let start = app.buttons["game.start"]
      // Wait for viewport/chrome measurements to settle, without scrolling or changing the fixture.
      let contained = expectation(
        for: NSPredicate { _, _ in
          (board + controls + [start]).allSatisfy {
            $0.exists && !$0.frame.isEmpty && viewport.frame.contains($0.frame)
          }
        }, evaluatedWith: app)
      wait(for: [contained], timeout: 5)
      capture(app, name: "pocket-\(fixture.rawValue)-normal-full-preview")
      assertContained(board + controls + [start], in: viewport, app: app)
      for control in controls + [start] {
        XCTAssertGreaterThanOrEqual(control.frame.width + 0.001, 44, control.identifier)
        XCTAssertGreaterThanOrEqual(control.frame.height + 0.001, 44, control.identifier)
      }
      if fixture != .bubble {
        for cell in board {
          XCTAssertGreaterThanOrEqual(cell.frame.width + 0.001, 44, cell.identifier)
          XCTAssertGreaterThanOrEqual(cell.frame.height + 0.001, 44, cell.identifier)
          XCTAssertFalse(cell.isEnabled)
        }
      }
      let frozen = board.map { "\($0.label)|\(String(describing: $0.value))" }
      let frames = board.map(\.frame)
      let controlFrames = controls.map(\.frame)
      let viewportFrame = viewport.frame
      start.tap()
      XCTAssertFalse(start.exists)
      XCTAssertEqual(board.map { "\($0.label)|\(String(describing: $0.value))" }, frozen)
      XCTAssertEqual(board.map(\.frame), frames, "Start must not reposition any board target.")
      XCTAssertEqual(controls.map(\.frame), controlFrames)
      XCTAssertEqual(viewport.frame, viewportFrame)
      assertContained(board + controls, in: viewport, app: app)
      capture(app, name: "pocket-\(fixture.rawValue)-normal-full-started")
      app.terminate()
    }
  }

  private func completeBoard(_ app: XCUIApplication, fixture: Fixture) -> [XCUIElement] {
    switch fixture {
    case .sudoku: (0..<16).map { app.buttons["sudoku.cell.\($0)"] }
    case .memory: (0..<12).map { app.buttons["memory.tile.\($0)"] }
    case .chessWhite, .chessBlack:
      (fixture == .chessWhite ? [8, 7, 6, 5] : [4, 3, 2, 1]).flatMap { rank in
        (fixture == .chessWhite ? ["e", "f", "g", "h"] : ["a", "b", "c", "d"]).map {
          app.buttons["chess.square.\($0)\(rank)"]
        }
      }
    case .bubble: [app.otherElements["bubble.board"]]
    }
  }

  private func primaryControls(_ app: XCUIApplication, fixture: Fixture) -> [XCUIElement] {
    switch fixture {
    case .sudoku:
      (1...4).map { app.buttons["sudoku.number.\($0)"] } + [app.buttons["sudoku.clear"]]
    case .memory: completeBoard(app, fixture: fixture)
    case .chessWhite, .chessBlack:
      (fixture == .chessWhite ? ["f7", "g6"] : ["b3", "c2"]).map {
        app.buttons["chess.piece.\($0)"]
      } + [app.buttons["chess.file"], app.buttons["chess.rank"], app.buttons["chess.submit"]]
    case .bubble:
      [
        app.otherElements["bubble.directAim"], app.sliders["bubble.aim"],
        app.buttons["bubble.fire"],
      ]
    }
  }

  private func assertContained(
    _ elements: [XCUIElement], in viewport: XCUIElement, app: XCUIApplication
  ) {
    let diagnostic = elements.map {
      "\($0.identifier): exists=\($0.exists), frame=\($0.frame), viewport=\(viewport.frame)"
    }.joined(separator: "\n")
    let attachment = XCTAttachment(string: diagnostic)
    attachment.name = "pocket-normal-frame-evidence"
    attachment.lifetime = .keepAlways
    add(attachment)
    for element in elements {
      XCTAssertTrue(element.exists, element.identifier)
      XCTAssertFalse(element.frame.isEmpty, element.identifier)
      XCTAssertTrue(viewport.frame.contains(element.frame), element.identifier)
      XCTAssertTrue(app.frame.contains(element.frame), element.identifier)
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

  private func assertPreview(
    _ app: XCUIApplication, fixture: Fixture, allowBoardOverflow: Bool = false
  ) {
    reveal(app.buttons["game.start"], in: app)
    XCTAssertTrue(app.buttons["game.start"].isEnabled)
    XCTAssertTrue(app.buttons["game.start"].isHittable)
    XCTAssertGreaterThanOrEqual(app.buttons["game.start"].frame.height + 0.001, 44)
    let element = anchor(app, fixture: fixture)
    XCTAssertTrue(element.exists)
    XCTAssertGreaterThan(element.frame.height, 0)
    if !allowBoardOverflow {
      XCTAssertTrue(app.scrollViews["feed.cardScroll"].frame.intersects(element.frame))
    }
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
        withNormalizedOffset: CGVector(dx: 0.95, dy: upwards ? 0.7 : 0.3))
      let end = scroll.coordinate(
        withNormalizedOffset: CGVector(dx: 0.95, dy: upwards ? 0.4 : 0.6))
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
