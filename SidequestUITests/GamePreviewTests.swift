import XCTest

@MainActor
final class GamePreviewTests: XCTestCase {
  func testAllInitialBoardsAcceptFirstInputAndResetAfterSkipAndBackground() {
    for fixture in Fixture.allCases {
      let app = launch(fixture)
      assertPreview(app, fixture: fixture)
      let before = snapshot(app, fixture: fixture)
      capture(app, name: "preview-\(fixture.rawValue)-normal")
      let frame = anchor(app, fixture: fixture).frame
      XCTAssertFalse(app.buttons["game.start"].exists)
      makeMove(app, fixture: fixture)
      XCTAssertEqual(anchor(app, fixture: fixture).frame, frame)
      app.nextFeedCard()
      app.previousFeedCard()
      assertPreview(app, fixture: fixture)
      XCTAssertEqual(snapshot(app, fixture: fixture), before)
      makeMove(app, fixture: fixture)
      XCUIDevice.shared.press(.home)
      app.activate()
      XCTAssertTrue(anchor(app, fixture: fixture).waitForExistence(timeout: 5))
      assertPreview(app, fixture: fixture)
      XCTAssertEqual(snapshot(app, fixture: fixture), before)
      capture(app, name: "reset-preview-\(fixture.rawValue)-normal")
      app.terminate()
    }
  }

  func testLargestTextKeepsEveryInitialBoardAndFirstInputReachableWithoutMovingTheBoard() {
    for fixture in Fixture.allCases {
      let app = launch(fixture, largeText: true)
      assertPreview(app, fixture: fixture, allowBoardOverflow: true)
      let before = snapshot(app, fixture: fixture)
      let first = anchor(app, fixture: fixture)
      let last = lastBoardElement(app, fixture: fixture)
      reveal(first, in: app)
      XCTAssertTrue(app.scrollViews["feed.cardScroll"].frame.contains(first.frame))
      if fixture == .sudoku || fixture == .memory { XCTAssertTrue(first.isEnabled) }
      capture(app, name: "preview-\(fixture.rawValue)-largest-board-top")
      reveal(last, in: app)
      XCTAssertTrue(app.scrollViews["feed.cardScroll"].frame.contains(last.frame))
      if fixture == .memory || fixture == .bubble { XCTAssertTrue(last.isEnabled) }
      if fixture == .memory { XCTAssertEqual(last.label, "Hidden card 12") }
      XCTAssertEqual(snapshot(app, fixture: fixture), before)
      capture(app, name: "preview-\(fixture.rawValue)-largest-board-bottom-before-start")
      // Establish the start baseline only after restoring its viewport; tapping must not auto-scroll.
      reveal(firstActionTarget(app, fixture: fixture), in: app)
      let viewport = app.scrollViews["feed.cardScroll"].frame
      let frame = first.frame
      makeMove(app, fixture: fixture)
      XCTAssertEqual(first.frame, frame)
      XCTAssertEqual(app.scrollViews["feed.cardScroll"].frame, viewport)
      reveal(lastBoardElement(app, fixture: fixture), in: app)
      capture(app, name: "started-\(fixture.rawValue)-largest-board-bottom")
      app.nextFeedCard()
      app.previousFeedCard()
      assertPreview(app, fixture: fixture, allowBoardOverflow: true)
      reveal(lastBoardElement(app, fixture: fixture), in: app)
      capture(app, name: "preview-\(fixture.rawValue)-largest-board-bottom")
      if fixture == .memory || fixture == .bubble {
        XCTAssertTrue(lastBoardElement(app, fixture: fixture).isEnabled)
      }
      if fixture == .memory {
        XCTAssertEqual(lastBoardElement(app, fixture: fixture).label, "Hidden card 12")
      }
      reveal(firstActionTarget(app, fixture: fixture), in: app)
      XCTAssertTrue(firstActionTarget(app, fixture: fixture).isHittable)
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
      let start = firstActionTarget(app, fixture: fixture)
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
          if fixture == .memory { XCTAssertTrue(cell.isEnabled) }
        }
      }
      // Selected Chess decoration changes its accessibility outline, so compare unselected squares.
      let stableBoard = board.filter {
        $0.identifier != "chess.square.g6" && $0.identifier != "chess.square.b3"
      }
      let frames = stableBoard.map(\.frame)
      let controlFrames = controls.map(\.frame)
      let viewportFrame = viewport.frame
      makeMove(app, fixture: fixture)
      XCTAssertFalse(app.buttons["game.start"].exists)
      XCTAssertEqual(
        stableBoard.map(\.frame), frames, "First input must not reposition board targets.")
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
        app.buttons["chess.square.\($0)"]
      }
    case .bubble: [app.bubbleAim]
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
    XCTAssertFalse(app.buttons["game.start"].exists)
    let element = anchor(app, fixture: fixture)
    XCTAssertTrue(element.exists)
    XCTAssertGreaterThan(element.frame.height, 0)
    if !allowBoardOverflow {
      XCTAssertTrue(app.scrollViews["feed.cardScroll"].frame.intersects(element.frame))
    }
    if fixture == .sudoku || fixture == .memory { XCTAssertTrue(element.isEnabled) }
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
      XCTAssertFalse(app.buttons["chess.submit"].exists)
    case .bubble:
      XCTAssertTrue(app.bubbleAim.isEnabled)
      XCTAssertFalse(app.buttons["bubble.fire"].exists)
      XCTAssertFalse(app.sliders["bubble.aim"].exists)
      XCTAssertEqual(app.bubbleAim.value as? String, "Aim: 0 degrees")
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
    case .bubble: app.bubbleAim
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

  private func firstActionTarget(_ app: XCUIApplication, fixture: Fixture) -> XCUIElement {
    switch fixture {
    case .sudoku: app.buttons["sudoku.cell.2"]
    case .memory: app.buttons["memory.tile.0"]
    case .chessWhite: app.buttons["chess.square.g6"]
    case .chessBlack: app.buttons["chess.square.b3"]
    case .bubble: app.bubbleAim
    }
  }

  private func makeMove(_ app: XCUIApplication, fixture: Fixture) {
    let element: XCUIElement
    switch fixture {
    case .sudoku: element = app.buttons["sudoku.cell.2"]
    case .memory: element = app.buttons["memory.tile.0"]
    case .chessWhite: element = app.buttons["chess.square.g6"]
    case .chessBlack: element = app.buttons["chess.square.b3"]
    case .bubble: element = app.bubbleAim
    }
    reveal(element, in: app)
    XCTAssertTrue(element.isEnabled)
    if fixture == .bubble {
      app.cancelBubbleShot(at: 0.7)
    } else {
      element.tap()
    }
    switch fixture {
    case .sudoku: XCTAssertTrue(element.isSelected)
    case .memory: XCTAssertEqual(element.label, "Revealed star, card 1")
    case .chessWhite: XCTAssertTrue(app.staticTexts["chess.selection"].label.contains("g6"))
    case .chessBlack: XCTAssertTrue(app.staticTexts["chess.selection"].label.contains("b3"))
    case .bubble:
      XCTAssertNotEqual(element.value as? String, "Aim: 0 degrees")
      XCTAssertEqual(app.staticTexts["bubble.shots"].label, "Shots: 0 of 8")
    }
  }

  private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
    let scroll = app.scrollViews["feed.cardScroll"]
    for _ in 0..<18 {
      if element.exists && element.isHittable && scroll.frame.contains(element.frame) { return }
      let upwards = !element.exists || element.frame.midY > scroll.frame.midY
      let bubbleBoard = app.otherElements["bubble.board"]
      let x =
        bubbleBoard.exists && !bubbleBoard.frame.isEmpty
        ? min(scroll.frame.width - 32, bubbleBoard.frame.maxX - scroll.frame.minX + 10)
        : scroll.frame.width * 0.9
      let origin = scroll.coordinate(withNormalizedOffset: .zero)
      let start = origin.withOffset(
        CGVector(dx: x, dy: scroll.frame.height * (upwards ? 0.7 : 0.3)))
      let end = origin.withOffset(CGVector(dx: x, dy: scroll.frame.height * (upwards ? 0.4 : 0.6)))
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
    app.launchWithManualFeed()
    XCTAssertTrue(anchor(app, fixture: fixture).waitForExistence(timeout: 5))
    return app
  }
}
