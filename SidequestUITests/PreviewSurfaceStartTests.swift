import XCTest

@MainActor
final class PreviewSurfaceStartTests: XCTestCase {
  func testEveryGameSurfaceTapStartsWithoutMakingItsFirstMoveAndSkipRequiresRestart() {
    for fixture in Fixture.allCases {
      let app = launch(fixture)
      let start = app.buttons["game.start"]
      XCTAssertEqual(start.label, "Start game")
      let target = boardTarget(app, fixture: fixture)
      let boardFrame = target.frame
      let frozen = boardState(app, fixture: fixture)
      target.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
      XCTAssertFalse(start.exists)
      XCTAssertEqual(target.frame, boardFrame)
      XCTAssertEqual(boardState(app, fixture: fixture), frozen)
      assertNoMove(app, fixture: fixture)
      app.nextFeedCard()
      app.previousFeedCard()
      XCTAssertTrue(start.waitForExistence(timeout: 5))
      XCTAssertEqual(boardState(app, fixture: fixture), frozen)
      assertNoMove(app, fixture: fixture)
      let screenshot = XCTAttachment(screenshot: app.screenshot())
      screenshot.name = "surface-restart-\(fixture.rawValue)"
      screenshot.lifetime = .keepAlways
      add(screenshot)
      app.terminate()
    }
  }

  func testPreviewDragsAndOwnedOverflowNeverStartGames() {
    for fixture in Fixture.allCases {
      let app = launch(fixture)
      let start = app.buttons["game.start"]
      let target = boardTarget(app, fixture: fixture)
      let from = target.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
      let end = from.withOffset(CGVector(dx: 0, dy: -24))
      from.press(forDuration: 0, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0)
      XCTAssertTrue(start.exists, "A short canceled page drag must remain an inactive preview.")
      assertNoMove(app, fixture: fixture)
      let pager = app.scrollViews["feed.pager"]
      let viewport = app.scrollViews["feed.cardScroll"]
      let origin = viewport.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
      let destination = viewport.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
      let originalCard = app.selectedFeedCardID
      origin.press(
        forDuration: 0, thenDragTo: destination, withVelocity: .fast, thenHoldForDuration: 0)
      let settled = XCTNSPredicateExpectation(
        predicate: NSPredicate { _, _ in app.selectedFeedCardID != originalCard }, object: app)
      XCTAssertEqual(XCTWaiter.wait(for: [settled], timeout: 5), .completed)
      XCTAssertTrue(pager.exists)
      // Returning through the existing menu must reveal a preview, never an attempt started by swipe.
      app.previousFeedCard()
      XCTAssertTrue(start.waitForExistence(timeout: 5))
      assertNoMove(app, fixture: fixture)
      app.terminate()

      let large = launch(fixture, largeText: true)
      let scroll = large.scrollViews["feed.cardScroll"]
      let upper = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.88, dy: 0.65))
      let lower = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.88, dy: 0.35))
      upper.press(forDuration: 0, thenDragTo: lower, withVelocity: .slow, thenHoldForDuration: 0)
      XCTAssertTrue(large.buttons["game.start"].exists)
      assertNoMove(large, fixture: fixture)
      XCTAssertTrue(large.buttons["feed.navigation"].isHittable)
      large.terminate()
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

  private func launch(_ fixture: Fixture, largeText: Bool = false) -> XCUIApplication {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = [fixture.argument] + (largeText ? ["-sidequest-large-text"] : [])
    app.launch()
    XCTAssertTrue(app.buttons["game.start"].waitForExistence(timeout: 5))
    return app
  }

  private func boardTarget(_ app: XCUIApplication, fixture: Fixture) -> XCUIElement {
    switch fixture {
    case .sudoku: app.buttons["sudoku.cell.2"]
    case .memory: app.buttons["memory.tile.0"]
    case .chessWhite: app.buttons["chess.square.g6"]
    case .chessBlack: app.buttons["chess.square.b3"]
    case .bubble: app.otherElements["bubble.board"]
    }
  }

  private func boardState(_ app: XCUIApplication, fixture: Fixture) -> [String] {
    switch fixture {
    case .sudoku:
      (0..<16).map { app.buttons["sudoku.cell.\($0)"].value as? String ?? "Missing" }
    case .memory:
      (0..<12).map { app.buttons["memory.tile.\($0)"].label }
    case .chessWhite, .chessBlack:
      [app.staticTexts["chess.selection"].label]
    case .bubble:
      [app.otherElements["bubble.board"].value as? String ?? "Missing"]
    }
  }

  private func assertNoMove(_ app: XCUIApplication, fixture: Fixture) {
    switch fixture {
    case .sudoku:
      XCTAssertFalse(app.buttons["sudoku.cell.2"].isSelected)
      XCTAssertFalse(app.buttons["sudoku.number.3"].isEnabled)
    case .memory:
      XCTAssertEqual(app.buttons["memory.tile.0"].label, "Hidden card 1")
      XCTAssertEqual(app.staticTexts["memory.progress"].label, "0 of 6 pairs matched")
    case .chessWhite, .chessBlack:
      XCTAssertEqual(app.staticTexts["chess.selection"].label, "No piece selected")
      XCTAssertFalse(app.buttons["chess.submit"].isEnabled)
    case .bubble:
      XCTAssertEqual(app.staticTexts["bubble.shots"].label, "Shots: 0 of 8")
      XCTAssertEqual(app.otherElements["bubble.directAim"].value as? String, "Aim: 0 degrees")
    }
  }
}
