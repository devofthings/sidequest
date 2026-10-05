import XCTest

@MainActor
final class MemoryWorkloadFlowTests: XCTestCase {
  func testSmallerWorkloadsKeepFrozenLayoutResetAndCompletedRevisit() {
    continueAfterFailure = false
    for pairCount in [3, 4] {
      let app = XCUIApplication()
      app.launchArguments =
        [
          "-sidequest-memory-fixtures",
          pairCount == 3 ? "-sidequest-memory-three-pairs" : "-sidequest-memory-four-pairs",
        ] + (pairCount == 4 ? ["-sidequest-large-text"] : [])
      app.launch()
      let start = app.buttons["game.start"]
      XCTAssertTrue(start.waitForExistence(timeout: 5))
      XCTAssertTrue(app.staticTexts["Find all \(pairCount) pairs."].exists)
      XCTAssertEqual(app.staticTexts["memory.progress"].label, "0 of \(pairCount) pairs matched")
      XCTAssertFalse(app.buttons["memory.tile.\(pairCount * 2)"].exists)
      let first = app.buttons["memory.tile.0"]
      XCTAssertFalse(first.isEnabled)
      reveal(start, app: app)
      start.tap()
      XCTAssertEqual(first.label, "Hidden card 1", "Starting must not flip a card.")
      tap(0, app: app)
      let originalFirstFace = first.label
      XCTAssertTrue(originalFirstFace.hasPrefix("Revealed "))
      app.nextFeedCard()
      app.previousFeedCard()
      reveal(start, app: app)
      XCTAssertFalse(first.isEnabled)
      start.tap()
      XCTAssertEqual(first.label, "Hidden card 1")
      XCTAssertEqual(app.staticTexts["memory.progress"].label, "0 of \(pairCount) pairs matched")
      tap(0, app: app)
      XCTAssertEqual(
        first.label, originalFirstFace, "Skip/reset must preserve the frozen challenge.")

      // Learn through real flips, retaining visible discoveries after each actual mismatch.
      var known: [Int: String] = [0: face(first)]
      var matched = Set<Int>()
      var choosing: Int? = 0
      while matched.count < pairCount * 2 {
        let left: Int
        if let choosing {
          left = choosing
        } else {
          guard let next = (0..<(pairCount * 2)).first(where: { !matched.contains($0) }) else {
            XCTFail("An incomplete board needs an unmatched tile.")
            return
          }
          left = next
          tap(left, app: app)
          known[left] = face(app.buttons["memory.tile.\(left)"])
        }
        let candidates = (0..<(pairCount * 2)).filter { $0 != left && !matched.contains($0) }
        guard
          let right = candidates.first(where: { known[$0] == known[left] })
            ?? candidates.first(where: { known[$0] == nil })
        else {
          XCTFail("Every original symbol must have its matching partner.")
          return
        }
        tap(right, app: app)
        let rightTile = app.buttons["memory.tile.\(right)"]
        known[right] = face(rightTile)
        if known[left] == known[right] {
          matched.formUnion([left, right])
          choosing = nil
          XCTAssertFalse(rightTile.isEnabled)
        } else {
          let hidden = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", "Hidden card \(left + 1)"),
            object: app.buttons["memory.tile.\(left)"])
          XCTAssertEqual(XCTWaiter.wait(for: [hidden], timeout: 5), .completed)
          choosing = nil
        }
      }
      XCTAssertTrue(app.staticTexts["memory.completed"].waitForExistence(timeout: 5))
      XCTAssertEqual(
        app.staticTexts["memory.progress"].label, "\(pairCount) of \(pairCount) pairs matched")
      let screenshot = XCTAttachment(screenshot: app.screenshot())
      screenshot.name = "memory-\(pairCount)-pairs-completed"
      screenshot.lifetime = .keepAlways
      add(screenshot)
      app.nextFeedCard()
      app.previousFeedCard()
      XCTAssertTrue(app.staticTexts["memory.completed"].exists)
      XCTAssertFalse(start.exists)
      for index in 0..<(pairCount * 2) {
        XCTAssertTrue(app.buttons["memory.tile.\(index)"].label.hasPrefix("Matched "))
        XCTAssertFalse(app.buttons["memory.tile.\(index)"].isEnabled)
      }
      app.terminate()
    }
  }

  private func face(_ tile: XCUIElement) -> String {
    let prefix = tile.label.hasPrefix("Matched ") ? "Matched " : "Revealed "
    XCTAssertTrue(tile.label.hasPrefix(prefix), "A real flip must disclose its original face.")
    return String(tile.label.dropFirst(prefix.count).split(separator: ",")[0])
  }

  private func tap(_ index: Int, app: XCUIApplication) {
    let tile = app.buttons["memory.tile.\(index)"]
    reveal(tile, app: app)
    XCTAssertTrue(tile.isHittable)
    XCTAssertGreaterThanOrEqual(tile.frame.width, 44)
    XCTAssertGreaterThanOrEqual(tile.frame.height, 72)
    tile.tap()
  }

  private func reveal(_ element: XCUIElement, app: XCUIApplication) {
    let scroll = app.scrollViews["feed.cardScroll"]
    for _ in 0..<18 {
      if element.exists && element.isHittable && scroll.frame.contains(element.frame) { return }
      let origin = scroll.coordinate(withNormalizedOffset: .zero)
      let above = element.exists && element.frame.minY < scroll.frame.minY
      let start = origin.withOffset(CGVector(dx: 8, dy: scroll.frame.height * (above ? 0.4 : 0.7)))
      let end = origin.withOffset(CGVector(dx: 8, dy: scroll.frame.height * (above ? 0.7 : 0.4)))
      start.press(forDuration: 0.1, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.1)
    }
    XCTAssertTrue(scroll.frame.contains(element.frame), "The entire control must be reachable.")
  }
}
