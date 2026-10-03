import XCTest

@testable import Sidequest

final class BubbleShooterRulesTests: XCTestCase {
  func testActualThreeShotWinAndReproducibleChallenge() throws {
    var first = BubbleShooterGame()
    var second = BubbleShooterGame()
    for degrees in [0.0, 0, 6] {
      let angle = degrees * .pi / 180
      let shot = try first.traceShot(angleRadians: angle)
      XCTAssertEqual(shot, try second.traceShot(angleRadians: angle))
      XCTAssertEqual(try first.commitShot(shot), try second.fire(angleRadians: angle))
    }
    XCTAssertEqual(first.outcome, .won)
    XCTAssertTrue(first.board.isEmpty)
    XCTAssertEqual(first.shotsFired, 3)
    XCTAssertEqual(first, second)
    XCTAssertThrowsError(try first.traceShot(angleRadians: 0))
  }

  func testRepeatedActualAimCanLoseAndResetInvalidatesPendingShot() throws {
    var game = BubbleShooterGame()
    for _ in 0..<7 {
      _ = try game.fire(angleRadians: 0)
    }
    XCTAssertEqual(game.outcome, .lost(.dangerRow))
    game.reset()
    XCTAssertEqual(game.board, BubbleShooterGame.challenge)
    XCTAssertEqual(game.shotsFired, 0)
    let pending = try game.traceShot(angleRadians: 0)
    game.reset()
    let reset = game
    XCTAssertThrowsError(try game.commitShot(pending)) {
      XCTAssertEqual($0 as? BubbleShotError, .staleShot)
    }
    XCTAssertEqual(game, reset)
  }

  func testFirstContactCannotTunnelThroughLowerBubble() throws {
    let low = BubbleSlot(row: 2, column: 2)
    let high = BubbleSlot(row: 0, column: 2)
    let occupied: [BubbleSlot: BubbleColor] = [low: .blue, high: .red]
    let trajectory = try BubbleGeometry.trace(angleRadians: 0, occupied: occupied)
    XCTAssertEqual(trajectory.contact, .bubble(low))
    let point = try XCTUnwrap(trajectory.points.last)
    XCTAssertEqual(point.x, 5, accuracy: 0.000_001)
    XCTAssertEqual(point.y, BubbleGeometry.center(of: low).y + 2, accuracy: 0.000_001)
    XCTAssertEqual(trajectory.points.count, 2)
    let slot = try XCTUnwrap(BubbleGeometry.attachment(for: trajectory, occupied: occupied))
    XCTAssertEqual(slot, BubbleSlot(row: 3, column: 1))
    XCTAssertGreaterThan(BubbleGeometry.center(of: slot).y, BubbleGeometry.center(of: low).y)
  }

  func testCeilingAndWallReflectionsStayInsideBounds() throws {
    let straight = try BubbleGeometry.trace(angleRadians: 0, occupied: [:])
    XCTAssertEqual(straight.contact, .ceiling)
    XCTAssertEqual(
      BubbleGeometry.attachment(for: straight, occupied: [:]), BubbleSlot(row: 0, column: 2))
    for angle in [-BubbleGeometry.maximumAngle, BubbleGeometry.maximumAngle] {
      let bounced = try BubbleGeometry.trace(angleRadians: angle, occupied: [:])
      XCTAssertEqual(bounced.contact, .ceiling)
      XCTAssertEqual(bounced.points.count, 4)
      for point in bounced.points {
        XCTAssertGreaterThanOrEqual(point.x, 1 - BubbleGeometry.epsilon)
        XCTAssertLessThanOrEqual(point.x, 9 + BubbleGeometry.epsilon)
        XCTAssertGreaterThanOrEqual(point.y, 1 - BubbleGeometry.epsilon)
      }
      XCTAssertEqual(bounced.points[1].x, angle < 0 ? 1 : 9, accuracy: 0.000_001)
      XCTAssertEqual(bounced.points[2].x, angle < 0 ? 9 : 1, accuracy: 0.000_001)
      XCTAssertNotNil(BubbleGeometry.attachment(for: bounced, occupied: [:]))
    }
  }

  func testEdgeAimsAlwaysAttachInValidUnoccupiedNonoverlappingSlots() throws {
    for degrees in -60...60 {
      let game = BubbleShooterGame()
      let shot = try game.traceShot(angleRadians: Double(degrees) * .pi / 180)
      let slot = try XCTUnwrap(shot.attachment)
      XCTAssertTrue(BubbleGeometry.slots.contains(slot))
      XCTAssertNil(game.board[slot])
      for occupied in game.board.keys {
        XCTAssertGreaterThanOrEqual(
          BubbleGeometry.center(of: slot).distanceSquared(to: BubbleGeometry.center(of: occupied)),
          4 - BubbleGeometry.epsilon)
        // Independently inspect every finite trajectory segment: no moving
        // center crosses inside the combined-radius disk before first contact.
        let center = BubbleGeometry.center(of: occupied)
        for (start, end) in zip(shot.trajectory.points, shot.trajectory.points.dropFirst()) {
          let dx = end.x - start.x
          let dy = end.y - start.y
          let lengthSquared = dx * dx + dy * dy
          let projection = ((center.x - start.x) * dx + (center.y - start.y) * dy) / lengthSquared
          let fraction = max(0, min(1, projection))
          let closest = BubblePoint(x: start.x + fraction * dx, y: start.y + fraction * dy)
          XCTAssertGreaterThanOrEqual(
            center.distanceSquared(to: closest), 4 - BubbleGeometry.epsilon)
        }
      }
    }
  }

  func testOnlyThreeConnectedColorsClearAndOtherColorsStay() throws {
    let anchor = BubbleSlot(row: 0, column: 2)
    var game = try BubbleShooterGame(board: [anchor: .red], shotColors: [.red])
    let first = try game.fire(angleRadians: 0)
    XCTAssertTrue(first.matched.isEmpty)
    XCTAssertEqual(game.board.count, 2)
    let second = try game.fire(angleRadians: 0)
    XCTAssertEqual(second.matched.count, 3)
    XCTAssertEqual(game.outcome, .won)

    let red = BubbleSlot(row: 0, column: 0)
    let blue = BubbleSlot(row: 0, column: 1)
    let separate = try BubbleShooterGame(board: [red: .red, blue: .blue], shotColors: [.green])
    XCTAssertEqual(separate.connectedColor(from: red), [red])
    XCTAssertEqual(separate.connectedColor(from: blue), [blue])
  }

  func testDetachedBubblesDropOnlyAfterTheirCeilingAnchorsClear() throws {
    let greenTop = BubbleSlot(row: 1, column: 0)
    let greenBottom = BubbleSlot(row: 2, column: 0)
    var game = try BubbleShooterGame(
      board: [
        BubbleSlot(row: 0, column: 0): .red, BubbleSlot(row: 0, column: 1): .red,
        greenTop: .green, greenBottom: .green,
      ], shotColors: [.red])
    let result = try game.fire(angleRadians: 0)
    XCTAssertEqual(result.matched.count, 3)
    XCTAssertEqual(result.detached, [greenTop, greenBottom])
    XCTAssertEqual(result.outcome, .won)
  }

  func testShotLimitProducesBoundedLossWithoutInventingAWin() throws {
    var game = try BubbleShooterGame(
      board: [BubbleSlot(row: 0, column: 0): .red], shotColors: [.blue])
    for _ in 0..<BubbleShooterGame.shotLimit {
      _ = try game.fire(angleRadians: 0)
    }
    XCTAssertEqual(game.outcome, .lost(.shotLimit))
    XCTAssertEqual(game.shotsFired, 8)
    XCTAssertEqual(game.board[BubbleSlot(row: 0, column: 0)], .red)
  }

  func testFullyBlockedBoardLosesWithoutOverlap() throws {
    let board = Dictionary(uniqueKeysWithValues: BubbleGeometry.slots.map { ($0, BubbleColor.red) })
    var game = try BubbleShooterGame(board: board, shotColors: [.blue])
    let plan = try game.traceShot(angleRadians: 0)
    XCTAssertNil(plan.attachment)
    XCTAssertEqual(try game.commitShot(plan).outcome, .lost(.blockedAttachment))
    XCTAssertEqual(game.board, board)
  }

  func testInvalidAimAndOldCommitLeaveStateUnchanged() throws {
    var game = BubbleShooterGame()
    for angle in [Double.nan, .infinity, -.infinity, BubbleGeometry.maximumAngle + 0.001] {
      let before = game
      XCTAssertThrowsError(try game.traceShot(angleRadians: angle)) {
        XCTAssertEqual($0 as? BubbleShotError, .invalidAngle)
      }
      XCTAssertEqual(game, before)
    }
    let shot = try game.traceShot(angleRadians: 0)
    _ = try game.commitShot(shot)
    let after = game
    XCTAssertThrowsError(try game.commitShot(shot)) {
      XCTAssertEqual($0 as? BubbleShotError, .staleShot)
    }
    XCTAssertEqual(game, after)
  }

  func testInvalidInjectedBoardsAndMissingColorsAreRejected() {
    XCTAssertThrowsError(
      try BubbleShooterGame(board: [BubbleSlot(row: -1, column: 0): .red], shotColors: [.red]))
    XCTAssertThrowsError(
      try BubbleShooterGame(board: [BubbleSlot(row: 1, column: 4): .red], shotColors: [.red]))
    XCTAssertThrowsError(try BubbleShooterGame(board: [:], shotColors: []))
  }
}
