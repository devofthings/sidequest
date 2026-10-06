import XCTest

@MainActor
final class MixedDifficultyFlowTests: XCTestCase {
  func testAllTwelveGameTierCombinationsHaveFrozenAccessibleLabelsAndRealControls() {
    continueAfterFailure = false
    let app = launch()
    let names = ["Easy", "Medium", "Hard"]
    var newsCount = 0
    for index in 0..<12 {
      while !app.selectedFeedCardID.hasPrefix("game-") {
        XCTAssertFalse(app.staticTexts["game.difficulty"].exists)
        XCTAssertTrue(app.staticTexts["news.sample"].exists)
        newsCount += 1
        app.nextFeedCard()
      }
      XCTAssertTrue(app.selectedFeedCardID.hasSuffix("-\(index)"))
      let tier = names[(index / 4 + (201 + index % 4) % 3) % 3]
      let label = app.staticTexts["game.difficulty"]
      XCTAssertTrue(label.waitForExistence(timeout: 5))
      XCTAssertEqual(label.label, "Difficulty: \(tier)")
      XCTAssertTrue(app.staticTexts["foundation.title"].exists)
      XCTAssertFalse(app.buttons["game.start"].exists)
      switch index % 4 {
      case 0:
        XCTAssertTrue(app.otherElements["sudoku.board"].exists)
        let editable = app.buttons.matching(
          NSPredicate(
            format: "identifier BEGINSWITH %@ AND value == %@", "sudoku.cell.", "Empty")
        ).firstMatch
        XCTAssertTrue(editable.exists)
        editable.tap()
        XCTAssertTrue(
          editable.isSelected, "First input must start and select the actual editable cell")
      case 1:
        let pairs = tier == "Easy" ? 3 : (tier == "Medium" ? 4 : 6)
        XCTAssertTrue(app.staticTexts["Find all \(pairs) pairs."].exists)
        XCTAssertTrue(app.buttons["memory.tile.0"].isEnabled)
        XCTAssertEqual(app.buttons["memory.tile.0"].label, "Hidden card 1")
        app.buttons["memory.tile.0"].tap()
        XCTAssertTrue(app.buttons["memory.tile.0"].label.hasPrefix("Revealed "))
        app.nextFeedCard()
        app.previousFeedCard()
        XCTAssertEqual(app.staticTexts["game.difficulty"].label, "Difficulty: \(tier)")
        XCTAssertEqual(app.buttons["memory.tile.0"].label, "Hidden card 1")
      case 2:
        XCTAssertTrue(app.staticTexts["chess.focus"].exists)
        let side = app.staticTexts["chess.side"].label.hasPrefix("White") ? "White" : "Black"
        let piece = app.buttons.matching(
          NSPredicate(
            format: "identifier BEGINSWITH %@ AND label BEGINSWITH[c] %@ AND label CONTAINS[c] %@",
            "chess.square.", side, "queen")
        ).firstMatch
        XCTAssertTrue(piece.exists)
        piece.tap()
        XCTAssertEqual(app.staticTexts["chess.selection"].label, "Selected: \(piece.label)")
      default:
        XCTAssertTrue(app.bubbleAim.exists)
        XCTAssertTrue(app.bubbleAim.isEnabled)
        let cap = tier == "Easy" ? 8 : (tier == "Medium" ? 5 : 3)
        XCTAssertEqual(app.staticTexts["bubble.shots"].label, "Shots: 0 of \(cap)")
        let aim = app.bubbleAim
        XCTAssertTrue(aim.exists)
        app.shootBubble(at: 0.6)
        XCTAssertNotEqual(aim.value as? String, "Aim: 0 degrees")
        let committed = XCTNSPredicateExpectation(
          predicate: NSPredicate(format: "label == %@", "Shots: 1 of \(cap)"),
          object: app.staticTexts["bubble.shots"])
        XCTAssertEqual(XCTWaiter.wait(for: [committed], timeout: 10), .completed)
      }
      app.nextFeedCard()
    }
    XCTAssertEqual(newsCount, 2, "The existing five-game/news cadence must remain unchanged.")
    app.terminate()
  }

  func testHardestGamesAtLargestTextKeepLabelAndPrimaryControlsStableDuringInput() {
    continueAfterFailure = false
    let app = launch(extra: ["-sidequest-large-text"])
    let hardIndices = [2, 5, 8, 11]
    for index in 0...11 {
      while !app.selectedFeedCardID.hasPrefix("game-") { app.nextFeedCard() }
      if hardIndices.contains(index) {
        XCTAssertEqual(app.staticTexts["game.difficulty"].label, "Difficulty: Hard")
        let control: XCUIElement
        switch index % 4 {
        case 0:
          let editable = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@ AND value == %@", "sudoku.cell.", "Empty")
          ).firstMatch
          let cell = Int(editable.identifier.dropFirst("sudoku.cell.".count)) ?? -1
          XCTAssertGreaterThanOrEqual(cell, 0)
          selectSudoku(row: cell / 9 + 1, column: cell % 9 + 1, app: app)
          control = app.buttons["sudoku.number.9"]
        case 1: control = app.buttons["memory.tile.0"]
        case 2:
          control =
            app.buttons.matching(
              NSPredicate(
                format: "identifier BEGINSWITH %@ AND label CONTAINS[c] %@", "chess.square.",
                "queen"
              )
            ).firstMatch
        default: control = app.bubbleAim
        }
        reveal(control, app: app)
        XCTAssertTrue(control.exists)
        XCTAssertTrue(control.isHittable)
        XCTAssertGreaterThanOrEqual(control.frame.height, 44)
        let frame = control.frame
        let heading = app.staticTexts["foundation.title"].frame
        let viewport = app.scrollViews["feed.pager"].frame
        XCTAssertTrue(app.frame.contains(heading))
        XCTAssertTrue(app.frame.contains(app.staticTexts["game.difficulty"].frame))
        XCTAssertGreaterThanOrEqual(viewport.minY, heading.maxY)
        switch index % 4 {
        case 0:
          control.tap()
          XCTAssertTrue(app.buttons["sudoku.clear"].isEnabled)
        case 1:
          control.tap()
          XCTAssertTrue(control.label.hasPrefix("Revealed "))
        case 2:
          control.tap()
          XCTAssertEqual(app.staticTexts["chess.selection"].label, "Selected: \(control.label)")
        default:
          app.shootBubble(at: 0.6)
          waitForShots(1, cap: 3, app: app)
        }
        XCTAssertEqual(app.staticTexts["foundation.title"].frame, heading)
        XCTAssertEqual(app.scrollViews["feed.pager"].frame, viewport)
        capture(app, name: "mixed-hard-largest-\(index)")
        XCTAssertEqual(control.frame.minY, frame.minY, accuracy: 1)
        XCTAssertEqual(app.staticTexts["game.difficulty"].label, "Difficulty: Hard")
      }
      app.nextFeedCard()
    }
    app.terminate()
  }

  func testRealCompletionsSurviveCrossBatchEvictionAndQuietRestoration() {
    continueAfterFailure = false
    let app = launch()
    var ids: [String] = []
    var tiers: [String] = []
    let answers = [
      (0, 4), (4, 9), (10, 9), (14, 8), (20, 8), (24, 5),
      (30, 9), (34, 8), (40, 8), (50, 5), (60, 8), (70, 5),
    ]
    for index in 0..<4 {
      ids.append(app.selectedFeedCardID)
      tiers.append(app.staticTexts["game.difficulty"].label)
      switch index {
      case 0:
        for (cell, digit) in answers {
          let target = app.buttons["sudoku.cell.\(cell)"]
          XCTAssertEqual(target.value as? String, "Empty")
          target.tap()
          app.buttons["sudoku.number.\(digit)"].tap()
          XCTAssertEqual(target.value as? String, "\(digit)")
        }
        XCTAssertEqual(app.staticTexts["sudoku.status"].label, "Sudoku solved!")
      case 1:
        for (left, right) in [(0, 2), (1, 6), (3, 4), (5, 7)] {
          app.buttons["memory.tile.\(left)"].tap()
          app.buttons["memory.tile.\(right)"].tap()
          XCTAssertTrue(app.buttons["memory.tile.\(right)"].label.hasPrefix("Matched "))
        }
        XCTAssertTrue(app.staticTexts["memory.completed"].exists)
      case 2:
        app.buttons["chess.square.c2"].tap()
        app.buttons["chess.square.b2"].tap()
        XCTAssertTrue(app.staticTexts["chess.completed"].exists)
      default:
        // Audited seed201 route: -55,-60,-60 degrees; interior -59.4 remains winning.
        for (shot, horizontal) in [0.5 - 55.0 / 120, 0.005, 0.005].enumerated() {
          reveal(app.bubbleAim, app: app)
          app.shootBubble(at: horizontal)
          waitForShots(shot + 1, cap: 8, app: app)
        }
        XCTAssertEqual(app.staticTexts["bubble.outcome"].label, "You won!")
      }
      capture(app, name: "mixed-real-completion-\(index)")
      app.nextFeedCard()
    }
    // The owner window is selected ±1. Crossing to game12 evicts all four original adapters.
    let distant = "game-00000000-0000-0000-0000-000000000201-12"
    for _ in 0..<10 {
      if app.selectedFeedCardID == distant { break }
      app.nextFeedCard()
    }
    XCTAssertEqual(app.selectedFeedCardID, distant)
    for _ in 0..<14 { app.previousFeedCard() }
    for index in 0..<4 {
      XCTAssertEqual(app.selectedFeedCardID, ids[index])
      XCTAssertEqual(app.staticTexts["game.difficulty"].label, tiers[index])
      XCTAssertFalse(app.staticTexts["game.successCelebration"].exists)
      switch index {
      case 0:
        XCTAssertEqual(app.staticTexts["sudoku.status"].label, "Sudoku solved!")
        for (cell, digit) in answers {
          XCTAssertEqual(app.buttons["sudoku.cell.\(cell)"].value as? String, "\(digit)")
        }
        XCTAssertFalse(app.buttons["sudoku.number.9"].isEnabled)
      case 1:
        for tile in 0..<8 {
          XCTAssertTrue(app.buttons["memory.tile.\(tile)"].label.hasPrefix("Matched "))
          XCTAssertFalse(app.buttons["memory.tile.\(tile)"].isEnabled)
        }
      case 2:
        XCTAssertTrue(app.staticTexts["chess.completed"].exists)
        XCTAssertTrue(app.buttons["chess.square.b2"].label.contains("queen"))
        XCTAssertFalse(app.buttons["chess.square.b2"].isEnabled)
      default:
        XCTAssertEqual(app.staticTexts["bubble.outcome"].label, "You won!")
        XCTAssertEqual(app.staticTexts["bubble.shots"].label, "Shots: 3 of 8")
        XCTAssertFalse(app.bubbleAim.exists)
      }
      capture(app, name: "mixed-restored-completion-\(index)")
      if index < 3 { app.nextFeedCard() }
    }
    app.terminate()
  }

  private func launch(extra: [String] = []) -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments = ["-sidequest-mixed-difficulties-test"] + extra
    app.launchWithManualFeed()
    XCTAssertTrue(app.buttons["feed.navigation"].waitForExistence(timeout: 10))
    return app
  }

  private func reveal(_ element: XCUIElement, app: XCUIApplication) {
    let selected = app.selectedFeedCardID
    for _ in 0..<12 {
      let viewport = app.scrollViews["feed.cardScroll"].frame
      if element.exists, element.isHittable, viewport.contains(element.frame) { return }
      let above = element.exists && element.frame.minY < viewport.minY
      let origin = app.coordinate(withNormalizedOffset: .zero)
      let start = origin.withOffset(
        CGVector(
          dx: viewport.minX + 8,
          dy: viewport.minY + viewport.height * (above ? 0.35 : 0.75)))
      let end = origin.withOffset(
        CGVector(
          dx: viewport.minX + 8,
          dy: viewport.minY + viewport.height * (above ? 0.65 : 0.35)))
      start.press(forDuration: 0.1, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.1)
      XCTAssertEqual(app.selectedFeedCardID, selected, "Owned scrolling must retain the card")
    }
    capture(app, name: "mixed-reveal-failure")
    let hierarchy = XCTAttachment(string: app.debugDescription)
    hierarchy.lifetime = .keepAlways
    add(hierarchy)
    XCTFail("Primary control \(element.identifier) not reachable: \(element.frame)")
  }

  private func selectSudoku(row: Int, column: Int, app: XCUIApplication) {
    reveal(app.buttons["sudoku.row"], app: app)
    app.buttons["sudoku.row"].tap()
    app.buttons["sudoku.row.\(row)"].tap()
    reveal(app.buttons["sudoku.column"], app: app)
    app.buttons["sudoku.column"].tap()
    app.buttons["sudoku.column.\(column)"].tap()
  }

  private func waitForShots(_ count: Int, cap: Int, app: XCUIApplication) {
    let committed = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "label == %@", "Shots: \(count) of \(cap)"),
      object: app.staticTexts["bubble.shots"])
    XCTAssertEqual(XCTWaiter.wait(for: [committed], timeout: 10), .completed)
  }

  private func capture(_ app: XCUIApplication, name: String) {
    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }
}
