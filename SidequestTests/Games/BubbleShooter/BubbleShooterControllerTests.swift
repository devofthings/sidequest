import XCTest

@testable import Sidequest

@MainActor
final class BubbleShooterControllerTests: XCTestCase {
  func testPreviewAndStartDoNotFireAndAimIsBounded() async {
    let runtime = GameRuntime()
    var pauses = 0
    let controller = BubbleShooterController(runtime: runtime, pause: { pauses += 1 })
    let initial = controller.game
    XCTAssertFalse(controller.fire())
    controller.aim(degrees: 30)
    XCTAssertEqual(controller.aimDegrees, 0)
    runtime.setVisible(true)
    XCTAssertFalse(controller.fire())
    await Task.yield()
    XCTAssertEqual(pauses, 0)
    XCTAssertEqual(controller.game, initial)
    runtime.start()
    // Starting invalidates old shot plans, but preserves the initial playable configuration.
    XCTAssertEqual(controller.game.board, initial.board)
    XCTAssertEqual(controller.game.nextColor, initial.nextColor)
    XCTAssertEqual(controller.game.outcome, initial.outcome)
    XCTAssertEqual(controller.game.shotsFired, initial.shotsFired)
    XCTAssertEqual(pauses, 0)
    XCTAssertNil(controller.flight)
    controller.aim(degrees: .nan)
    XCTAssertEqual(controller.aimDegrees, 0)
    controller.aim(degrees: -80)
    XCTAssertEqual(controller.aimDegrees, -60)
    controller.aim(degrees: 80)
    XCTAssertEqual(controller.aimDegrees, 60)
  }

  func testThreeActualAnimatedShotsWinAndReplayRestoresFreshBoard() async {
    let gate = BubbleDelayGate()
    var haptics = 0
    var successes = 0
    var now = 0.0
    let runtime = GameRuntime(
      interactionHaptic: { haptics += 1 }, interactionTime: { now },
      successHaptic: { successes += 1 })
    let controller = BubbleShooterController(runtime: runtime, pause: { try await gate.pause() })
    runtime.setVisible(true)
    runtime.start()
    let oldPhase = runtime.phase
    for (index, angle) in [0.0, 0.0, 6.0].enumerated() {
      now += 1
      controller.aim(degrees: angle)
      XCTAssertTrue(controller.fire())
      XCTAssertFalse(controller.fire())
      let before = controller.game.board.count
      XCTAssertEqual(haptics, index)
      await finishShot(gate, firstPause: index * 24 + 1)
      XCTAssertLessThan(controller.game.board.count, before)
      XCTAssertEqual(haptics, min(index + 1, 2))
      XCTAssertEqual(successes, index == 2 ? 1 : 0)
    }
    XCTAssertEqual(controller.game.outcome, .won)
    guard case .completed(let attemptID) = runtime.phase else {
      return XCTFail("Expected won completion")
    }
    XCTAssertEqual(runtime.celebrationAttempt, attemptID)
    XCTAssertEqual(controller.game.shotsFired, 3)
    XCTAssertNil(controller.flight)
    guard case .completed = runtime.phase else { return XCTFail("Expected completion") }
    let completed = controller.game
    runtime.setVisible(false)
    XCTAssertFalse(controller.replay())
    runtime.setVisible(true)
    XCTAssertEqual(controller.game, completed)
    XCTAssertFalse(controller.fire())
    XCTAssertTrue(controller.replay())
    XCTAssertNotEqual(runtime.phase, oldPhase)
    XCTAssertEqual(controller.game.board, BubbleShooterGame.challenge)
    XCTAssertEqual(controller.game.shotsFired, 0)
    XCTAssertEqual(controller.aimDegrees, 0)
    XCTAssertNil(controller.flight)
  }

  func testSevenStraightShotsLoseAndReplayConsumesNoShot() async {
    let gate = BubbleDelayGate()
    let runtime = GameRuntime()
    let controller = BubbleShooterController(runtime: runtime, pause: { try await gate.pause() })
    runtime.setVisible(true)
    runtime.start()
    for index in 0..<7 {
      XCTAssertTrue(controller.fire())
      await finishShot(gate, firstPause: index * 24 + 1)
    }
    XCTAssertEqual(controller.game.outcome, .lost(.dangerRow))
    XCTAssertNil(runtime.celebrationAttempt)
    guard case .completed = runtime.phase else { return XCTFail("Loss must finish lifecycle") }
    XCTAssertTrue(controller.replay())
    XCTAssertEqual(controller.game.outcome, .playing)
    XCTAssertEqual(controller.game.shotsFired, 0)
  }

  func testSkipCancelsNoncooperativeFlightWithoutChangingNewAttempt() async {
    let gate = BubbleDelayGate()
    var haptics = 0
    let runtime = GameRuntime(interactionHaptic: { haptics += 1 }, successHaptic: {})
    let controller = BubbleShooterController(runtime: runtime, pause: { try await gate.pause() })
    runtime.setVisible(true)
    runtime.start()
    let oldPhase = runtime.phase
    XCTAssertTrue(controller.fire())
    await gate.waitUntilStarted(1)
    XCTAssertNotNil(controller.flight)
    runtime.setVisible(false)
    XCTAssertNil(controller.flight)
    XCTAssertEqual(controller.game.shotsFired, 0)
    XCTAssertEqual(controller.game.board, BubbleShooterGame.challenge)
    XCTAssertFalse(controller.fire())
    runtime.setVisible(true)
    runtime.start()
    XCTAssertNotEqual(runtime.phase, oldPhase)
    controller.aim(degrees: 6)
    XCTAssertTrue(controller.fire())
    await gate.waitUntilStarted(2)
    let pending = controller.flight
    gate.resume(1)
    await gate.waitUntilReturned(1)
    XCTAssertEqual(controller.flight, pending)
    XCTAssertEqual(controller.game.shotsFired, 0)
    XCTAssertEqual(haptics, 0, "Canceled old shot cannot emit feedback in a fresh attempt.")
    await finishShot(gate, firstPause: 2)
    XCTAssertNil(controller.flight)
    XCTAssertEqual(controller.game.shotsFired, 1)
  }

  func testShotFailureClearsFlightAndAllowsAnotherFire() async {
    let runtime = GameRuntime()
    let gate = BubbleDelayGate()
    let controller = BubbleShooterController(
      runtime: runtime, pause: { try await gate.pause(fail: true) })
    runtime.setVisible(true)
    runtime.start()
    XCTAssertTrue(controller.fire())
    await gate.waitUntilStarted(1)
    gate.resume(1)
    await gate.waitUntilReturned(1)
    XCTAssertNil(controller.flight)
    XCTAssertEqual(controller.game.shotsFired, 0)
    XCTAssertTrue(controller.canFire)
    XCTAssertTrue(controller.feedback.contains("Could not fire"))
  }

  func testOriginatingDragCannotResumeAfterFireFinishesWithinTheSameAttempt() async throws {
    let gate = BubbleDelayGate()
    let runtime = GameRuntime()
    let controller = BubbleShooterController(runtime: runtime, pause: { try await gate.pause() })
    runtime.setVisible(true)
    XCTAssertNil(controller.beginAimDrag())
    runtime.start()
    let phase = runtime.phase
    let old = try XCTUnwrap(controller.beginAimDrag())
    XCTAssertEqual(controller.aimDegrees, 0)
    XCTAssertNil(controller.flight, "Beginning a drag on an undefined launcher ray does not fire.")
    XCTAssertFalse(controller.updateAimDrag(old, degrees: .nan))
    XCTAssertTrue(controller.updateAimDrag(old, degrees: 0))
    XCTAssertEqual(controller.game.shotsFired, 0)
    XCTAssertTrue(controller.fire())
    XCTAssertFalse(controller.updateAimDrag(old, degrees: 30))
    await finishShot(gate, firstPause: 1)
    XCTAssertEqual(runtime.phase, phase)
    XCTAssertTrue(controller.canFire)
    XCTAssertFalse(controller.updateAimDrag(old, degrees: 30))
    XCTAssertEqual(controller.aimDegrees, 0)
    let fresh = try XCTUnwrap(controller.beginAimDrag())
    XCTAssertTrue(controller.updateAimDrag(fresh, degrees: -20))
    controller.endAimDrag(old)
    XCTAssertTrue(controller.updateAimDrag(fresh, degrees: -25))
    controller.endAimDrag(fresh)
    XCTAssertFalse(controller.updateAimDrag(fresh, degrees: 20))
    XCTAssertEqual(controller.game.shotsFired, 1)
  }

  func testSliderReplacementSkipAndRetirementInvalidateHeldDrags() throws {
    let runtime = GameRuntime()
    let controller = BubbleShooterController(runtime: runtime)
    runtime.setVisible(true)
    runtime.start()
    let replaced = try XCTUnwrap(controller.beginAimDrag())
    let current = try XCTUnwrap(controller.beginAimDrag())
    XCTAssertFalse(controller.updateAimDrag(replaced, degrees: 45))
    XCTAssertFalse(controller.updateAimDrag(current, degrees: .nan))
    XCTAssertTrue(controller.updateAimDrag(current, degrees: 10))
    controller.aim(degrees: -15)
    XCTAssertFalse(controller.updateAimDrag(current, degrees: 45))
    XCTAssertEqual(controller.aimDegrees, -15)
    let skipped = try XCTUnwrap(controller.beginAimDrag())
    runtime.setVisible(false)
    runtime.setVisible(true)
    runtime.start()
    XCTAssertFalse(controller.updateAimDrag(skipped, degrees: 45))
    XCTAssertEqual(controller.aimDegrees, 0)
    let retired = try XCTUnwrap(controller.beginAimDrag())
    runtime.retire()
    runtime.setVisible(true)
    runtime.start()
    XCTAssertFalse(controller.updateAimDrag(retired, degrees: 45))
    XCTAssertNil(controller.beginAimDrag())
    XCTAssertEqual(controller.game.shotsFired, 0)
  }

  func testGuideUsesRealReflectionAndContactWithoutMutatingTheGame() throws {
    let runtime = GameRuntime()
    let controller = BubbleShooterController(runtime: runtime)
    XCTAssertNil(controller.aimTrajectory)
    runtime.setVisible(true)
    runtime.start()
    controller.aim(degrees: 60)
    let game = controller.game
    let actual = try game.traceShot(angleRadians: .pi / 3).trajectory
    XCTAssertGreaterThan(
      actual.points.count, 2, "A reflected route needs an intermediate wall point.")
    XCTAssertEqual(controller.aimTrajectory, actual)
    XCTAssertEqual(controller.aimTrajectory, actual)
    XCTAssertEqual(controller.game, game)
    XCTAssertNil(controller.flight)
    XCTAssertEqual(controller.game.shotsFired, 0)
    runtime.setVisible(false)
    XCTAssertNil(controller.aimTrajectory)
  }

  private func finishShot(_ gate: BubbleDelayGate, firstPause: Int) async {
    for number in firstPause..<(firstPause + 24) {
      await gate.waitUntilStarted(number)
      gate.resume(number)
      await gate.waitUntilReturned(number)
    }
  }
}

/// Deliberately noncooperative; tests resume every delay and observe public state.
/// Same-actor return signals let the controller's post-await gate run before the test's next turn.
@MainActor
private final class BubbleDelayGate {
  private enum PauseFailure: Error { case interrupted }
  private var count = 0
  private var pauses: [Int: CheckedContinuation<Void, Never>] = [:]
  private var returned = Set<Int>()
  private var startWaiters: [Int: CheckedContinuation<Void, Never>] = [:]
  private var returnWaiters: [Int: CheckedContinuation<Void, Never>] = [:]

  func pause(fail: Bool = false) async throws {
    count += 1
    let number = count
    await withCheckedContinuation { continuation in
      pauses[number] = continuation
      startWaiters.removeValue(forKey: number)?.resume()
    }
    returned.insert(number)
    returnWaiters.removeValue(forKey: number)?.resume()
    if fail { throw PauseFailure.interrupted }
  }
  func waitUntilStarted(_ number: Int) async {
    if pauses[number] != nil { return }
    await withCheckedContinuation { startWaiters[number] = $0 }
  }
  func waitUntilReturned(_ number: Int) async {
    if returned.contains(number) { return }
    await withCheckedContinuation { returnWaiters[number] = $0 }
  }
  func resume(_ number: Int) { pauses.removeValue(forKey: number)?.resume() }
}
