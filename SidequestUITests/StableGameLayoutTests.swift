import XCTest

@MainActor
final class StableGameLayoutTests: XCTestCase {
  func testSudokuFeedbackAndCompletionKeepBoardAndControlsStable() { checkSudoku(largeText: false) }
  func testLargestTextSudokuFeedbackAndCompletionKeepBoardAndControlsStable() {
    checkSudoku(largeText: true)
  }
  func testMemoryMismatchAndCompletionKeepTilesStable() { checkMemory(largeText: false) }
  func testLargestTextMemoryMismatchAndCompletionKeepTilesStable() { checkMemory(largeText: true) }
  func testChessSelectionFeedbackAndCompletionKeepBoardAndControlsStable() {
    checkChess(largeText: false)
  }
  func testLargestTextChessSelectionFeedbackAndCompletionKeepBoardAndControlsStable() {
    checkChess(largeText: true)
  }
  func testBubbleFeedbackCompletionAndReplayKeepBoardAndControlsStable() {
    checkBubble(largeText: false)
  }
  func testLargestTextBubbleFeedbackCompletionAndReplayKeepBoardAndControlsStable() {
    checkBubble(largeText: true)
  }

  private func checkSudoku(largeText: Bool) {
    let app = launch("-sidequest-sudoku-test", largeText: largeText)
    let board = app.buttons["sudoku.cell.0"]
    let number = app.buttons["sudoku.number.1"]
    let clear = app.buttons["sudoku.clear"]
    reveal(app.buttons["sudoku.cell.2"], in: app)
    app.buttons["sudoku.cell.2"].tap()
    reveal(clear, in: app)
    XCTAssertTrue(app.scrollViews["feed.cardScroll"].frame.contains(number.frame))
    let conflictBaseline = frames([board, number, clear], in: app)
    number.tap()
    XCTAssertEqual(app.staticTexts["sudoku.status"].label, "Conflicts need correction.")
    assertStable(
      [board, number, clear], baseline: conflictBaseline, in: app, state: "Sudoku conflict")
    clear.tap()
    XCTAssertEqual(
      app.staticTexts["sudoku.status"].label, "Select an empty cell, then enter a number.")
    assertStable(
      [board, number, clear], baseline: conflictBaseline, in: app, state: "Sudoku correction")
    for (cell, value) in [(2, 3), (4, 3), (7, 2), (8, 2), (11, 3), (13, 3)] {
      reveal(app.buttons["sudoku.cell.\(cell)"], in: app)
      app.buttons["sudoku.cell.\(cell)"].tap()
      reveal(app.buttons["sudoku.number.\(value)"], in: app)
      app.buttons["sudoku.number.\(value)"].tap()
    }
    reveal(app.buttons["sudoku.cell.14"], in: app)
    app.buttons["sudoku.cell.14"].tap()
    let lastNumber = app.buttons["sudoku.number.2"]
    reveal(clear, in: app)
    XCTAssertTrue(app.scrollViews["feed.cardScroll"].frame.contains(lastNumber.frame))
    let completionBaseline = frames([board, lastNumber, clear], in: app)
    lastNumber.tap()
    XCTAssertEqual(app.staticTexts["sudoku.status"].label, "Sudoku solved!")
    assertStable(
      [board, lastNumber, clear], baseline: completionBaseline, in: app, state: "Sudoku completion")
    XCTAssertFalse(lastNumber.isEnabled)
    XCTAssertFalse(clear.isEnabled)
    reveal(app.staticTexts["sudoku.status"], in: app)
    capture(app, name: "stable-sudoku-\(largeText ? "largest" : "normal")")
  }

  private func checkMemory(largeText: Bool) {
    let app = launch("-sidequest-memory-fixtures", largeText: largeText)
    let first = app.buttons["memory.tile.0"]
    let third = app.buttons["memory.tile.2"]
    reveal(third, in: app)
    let mismatchBaseline = frames([first, third], in: app)
    first.tap()
    third.tap()
    XCTAssertTrue(app.staticTexts["memory.feedback"].exists)
    assertStable([first, third], baseline: mismatchBaseline, in: app, state: "Memory mismatch")
    let concealed = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "label == %@", "Hidden card 1"), object: first)
    XCTAssertEqual(XCTWaiter.wait(for: [concealed], timeout: 5), .completed)
    assertStable(
      [first, third], baseline: mismatchBaseline, in: app, state: "Memory feedback removed")
    for index in 0..<10 {
      reveal(app.buttons["memory.tile.\(index)"], in: app)
      app.buttons["memory.tile.\(index)"].tap()
    }
    let last = app.buttons["memory.tile.11"]
    reveal(last, in: app)
    app.buttons["memory.tile.10"].tap()
    let completionBaseline = frames([first, last], in: app)
    last.tap()
    XCTAssertTrue(app.staticTexts["memory.completed"].exists)
    assertStable([first, last], baseline: completionBaseline, in: app, state: "Memory completion")
    XCTAssertFalse(last.isEnabled)
    reveal(app.staticTexts["memory.completed"], in: app)
    XCTAssertEqual(app.staticTexts["memory.completed"].label, "All pairs found!")
    capture(app, name: "stable-memory-\(largeText ? "largest" : "normal")")
  }

  private func checkChess(largeText: Bool) {
    let app = launch("-sidequest-chess-white-fixture", largeText: largeText)
    // An unselected square avoids measuring the selected square's decorative outline.
    let board = app.buttons["chess.square.e8"]
    let queen = app.buttons["chess.square.g6"]
    let destination = app.buttons["chess.square.g7"]
    let targets = [board, app.buttons["chess.square.h5"]]
    reveal(queen, in: app)
    let selectionBaseline = frames(targets, in: app)
    queen.tap()
    XCTAssertTrue(app.staticTexts["chess.selection"].label.contains("g6"))
    assertStable(targets, baseline: selectionBaseline, in: app, state: "Chess selection")
    let illegal = app.buttons["chess.square.e5"]
    reveal(illegal, in: app)
    let feedbackBaseline = frames(targets, in: app)
    illegal.tap()
    XCTAssertEqual(
      app.staticTexts["chess.feedback"].label, "That move is not legal. Try another move.")
    assertStable(targets, baseline: feedbackBaseline, in: app, state: "Chess feedback")
    reveal(queen, in: app)
    queen.tap()
    reveal(destination, in: app)
    let completionBaseline = frames(targets, in: app)
    destination.tap()
    XCTAssertEqual(app.staticTexts["chess.completed"].label, "Checkmate! White wins.")
    assertStable(targets, baseline: completionBaseline, in: app, state: "Chess completion")
    XCTAssertFalse(destination.isEnabled)
    reveal(app.staticTexts["chess.completed"], in: app)
    capture(app, name: "stable-chess-\(largeText ? "largest" : "normal")")
  }

  private func checkBubble(largeText: Bool) {
    let app = launch("-sidequest-bubble-fixtures", largeText: largeText, slowShot: true)
    let board = app.otherElements["bubble.board"]
    let aim = app.bubbleAim
    reveal(aim, in: app)
    let feedbackBaseline = frames([board, aim], in: app)
    app.shootBubble()
    XCTAssertEqual(app.staticTexts["bubble.feedback"].label, "Shot in flight.")
    assertStable([board, aim], baseline: feedbackBaseline, in: app, state: "Bubble flight")
    waitForShots(1, in: app)
    XCTAssertTrue(app.staticTexts["bubble.feedback"].label.hasPrefix("Cleared"))
    assertStable([board, aim], baseline: feedbackBaseline, in: app, state: "Bubble long feedback")
    app.shootBubble()
    waitForShots(2, in: app)
    let completionBaseline = frames([board], in: app)
    app.shootBubble(at: 0.65)
    XCTAssertTrue(app.staticTexts["bubble.outcome"].waitForExistence(timeout: 12))
    XCTAssertEqual(app.staticTexts["bubble.outcome"].label, "You won!")
    assertStable([board], baseline: completionBaseline, in: app, state: "Bubble completion")
    XCTAssertFalse(aim.exists)
    XCTAssertFalse(app.buttons["bubble.fire"].exists)
    reveal(app.staticTexts["bubble.feedback"], in: app)
    XCTAssertEqual(app.staticTexts["bubble.feedback"].label, "Board cleared!")
    capture(app, name: "stable-bubble-\(largeText ? "largest" : "normal")")
    app.nextFeedCard()
    app.previousFeedCard()
    reveal(board, in: app)
    XCTAssertEqual(app.staticTexts["bubble.outcome"].label, "You won!")
    XCTAssertFalse(aim.exists)
  }

  private struct FrameBaseline {
    let elements: [CGRect]
    let viewport: CGRect
    let cardID: String
  }

  private func frames(_ elements: [XCUIElement], in app: XCUIApplication) -> FrameBaseline {
    FrameBaseline(
      elements: elements.map(\.frame), viewport: app.scrollViews["feed.cardScroll"].frame,
      cardID: app.selectedFeedCardID)
  }

  private func assertStable(
    _ elements: [XCUIElement], baseline: FrameBaseline, in app: XCUIApplication, state: String,
    file: StaticString = #filePath, line: UInt = #line
  ) {
    XCTAssertEqual(app.selectedFeedCardID, baseline.cardID, file: file, line: line)
    XCTAssertEqual(
      app.scrollViews["feed.cardScroll"].frame, baseline.viewport, file: file, line: line)
    for (element, original) in zip(elements, baseline.elements) {
      let current = element.frame
      print("STABLE_GAME_LAYOUT \(state) \(element.identifier): \(original) -> \(current)")
      XCTAssertEqual(current.minX, original.minX, accuracy: 0.5, state, file: file, line: line)
      XCTAssertEqual(current.minY, original.minY, accuracy: 0.5, state, file: file, line: line)
      XCTAssertEqual(current.width, original.width, accuracy: 0.5, state, file: file, line: line)
      XCTAssertEqual(current.height, original.height, accuracy: 0.5, state, file: file, line: line)
    }
  }

  private func waitForShots(_ count: Int, in app: XCUIApplication) {
    let committed = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "label == %@", "Shots: \(count) of 8"),
      object: app.staticTexts["bubble.shots"])
    XCTAssertEqual(XCTWaiter.wait(for: [committed], timeout: 12), .completed)
  }

  private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
    let scroll = app.scrollViews["feed.cardScroll"]
    for _ in 0..<20 {
      if element.exists && element.isHittable && scroll.frame.contains(element.frame) { return }
      let upwards = element.frame.midY > scroll.frame.midY
      let start = scroll.coordinate(
        withNormalizedOffset: CGVector(dx: 0.9, dy: upwards ? 0.7 : 0.3))
      let end = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: upwards ? 0.4 : 0.6))
      start.press(
        forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.05)
    }
    XCTFail(
      "The full control must be visible: \(element.identifier) \(element.frame) in \(scroll.frame)")
  }

  private func capture(_ app: XCUIApplication, name: String) {
    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }

  private func launch(_ route: String, largeText: Bool, slowShot: Bool = false) -> XCUIApplication {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments =
      [route] + (largeText ? ["-sidequest-large-text"] : [])
      + (slowShot ? ["-sidequest-bubble-slow-shot"] : [])
    app.launchWithManualFeed()
    XCTAssertTrue(app.staticTexts["foundation.title"].waitForExistence(timeout: 5))
    XCTAssertFalse(app.buttons["game.start"].exists)
    return app
  }
}
