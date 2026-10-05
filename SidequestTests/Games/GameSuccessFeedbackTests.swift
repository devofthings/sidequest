import XCTest

@testable import Sidequest

@MainActor
final class GameSuccessFeedbackTests: XCTestCase {
  func testVisibleSuccessEmitsOnceAndRevisitDoesNotReplay() throws {
    var haptics = 0
    let runtime = runtime(successHaptic: { haptics += 1 })
    let attempt = try start(runtime)
    runtime.complete(attempt: attempt, successful: true)
    XCTAssertEqual(runtime.celebrationAttempt, attempt)
    XCTAssertEqual(runtime.phase, .completed(attempt))
    runtime.complete(attempt: attempt, successful: true)
    runtime.setVisible(false)
    XCTAssertNil(runtime.celebrationAttempt)
    runtime.setVisible(true)
    runtime.start()
    runtime.complete(attempt: attempt, successful: true)
    XCTAssertEqual(haptics, 1)
    XCTAssertNil(runtime.celebrationAttempt)
    XCTAssertEqual(runtime.phase, .completed(attempt))
  }

  func testFailureAndSkippedOldAttemptNeverCelebrate() throws {
    var haptics = 0
    let runtime = runtime(successHaptic: { haptics += 1 })
    let old = try start(runtime)
    runtime.setVisible(false)
    runtime.complete(attempt: old, successful: true)
    let fresh = try start(runtime)
    runtime.complete(attempt: old, successful: true)
    XCTAssertEqual(runtime.phase, .playing(fresh))
    runtime.complete(attempt: fresh, successful: false)
    XCTAssertEqual(runtime.phase, .completed(fresh))
    XCTAssertNil(runtime.celebrationAttempt)
    XCTAssertEqual(haptics, 0)
  }

  func testRehydratedCompletionIsQuietAndRetiredOwnersRejectSuccess() throws {
    var haptics = 0
    let completed = GameAttemptID()
    let restored = GameRuntime(completed: completed, successHaptic: { haptics += 1 })
    restored.installEffectHandler { _ in }
    restored.setVisible(true)
    restored.complete(attempt: completed, successful: true)
    XCTAssertNil(restored.celebrationAttempt)
    let runtime = runtime(successHaptic: { haptics += 1 })
    let attempt = try start(runtime)
    runtime.retire()
    runtime.setVisible(true)
    runtime.complete(attempt: attempt, successful: true)
    XCTAssertNil(runtime.celebrationAttempt)
    XCTAssertEqual(haptics, 0)
  }

  func testSynchronousStopThatHidesOrRetiresSuppressesFeedback() throws {
    for retire in [false, true] {
      var haptics = 0
      let runtime = GameRuntime(successHaptic: { haptics += 1 })
      runtime.installEffectHandler { [weak runtime] effect in
        guard let runtime else { return }
        if case .stop = effect {
          if retire { runtime.retire() } else { runtime.setVisible(false) }
        }
      }
      let attempt = try start(runtime)
      runtime.complete(attempt: attempt, successful: true)
      XCTAssertNil(runtime.celebrationAttempt)
      XCTAssertEqual(haptics, 0)
    }
  }

  func testExpirationOnlyRemovesDecorationNotCompletedResult() async throws {
    let gate = CelebrationDelayGate()
    let runtime = runtime(celebrationDelay: { try await gate.pause() })
    let attempt = try start(runtime)
    runtime.complete(attempt: attempt, successful: true)
    await gate.waitUntilStarted(1)
    XCTAssertEqual(runtime.celebrationAttempt, attempt)
    gate.resume(1)
    await gate.waitUntilReturned(1)
    XCTAssertNil(runtime.celebrationAttempt)
    XCTAssertEqual(runtime.phase, .completed(attempt))
  }

  func testCanceledOldExpirationCannotClearNewReplayCelebration() async throws {
    let gate = CelebrationDelayGate()
    var haptics = 0
    let runtime = runtime(
      successHaptic: { haptics += 1 }, celebrationDelay: { try await gate.pause() })
    let old = try start(runtime)
    runtime.complete(attempt: old, successful: true)
    await gate.waitUntilStarted(1)
    XCTAssertTrue(runtime.replay())
    XCTAssertNil(runtime.celebrationAttempt)
    guard case .playing(let fresh) = runtime.phase else { return XCTFail("Expected replay") }
    runtime.complete(attempt: fresh, successful: true)
    await gate.waitUntilStarted(2)
    gate.resume(1)
    await gate.waitUntilReturned(1)
    XCTAssertEqual(runtime.celebrationAttempt, fresh)
    XCTAssertEqual(haptics, 2)
    runtime.setVisible(false)
    gate.resume(2)
    await gate.waitUntilReturned(2)
    runtime.setVisible(true)
    XCTAssertNil(runtime.celebrationAttempt)
    XCTAssertEqual(runtime.phase, .completed(fresh))
    XCTAssertEqual(haptics, 2)
  }

  func testFailedDelayClearsOnlyItsEligibleDecoration() async throws {
    let gate = CelebrationDelayGate(fails: true)
    let runtime = runtime(celebrationDelay: { try await gate.pause() })
    let attempt = try start(runtime)
    runtime.complete(attempt: attempt, successful: true)
    await gate.waitUntilStarted(1)
    gate.resume(1)
    await gate.waitUntilReturned(1)
    XCTAssertNil(runtime.celebrationAttempt)
    XCTAssertEqual(runtime.phase, .completed(attempt))
  }

  private func runtime(
    successHaptic: @escaping @MainActor () -> Void = {},
    celebrationDelay: @escaping @MainActor @Sendable () async throws -> Void = {
      try await Task.sleep(for: .seconds(30))
    }
  ) -> GameRuntime {
    let runtime = GameRuntime(successHaptic: successHaptic, celebrationDelay: celebrationDelay)
    runtime.installEffectHandler { _ in }
    return runtime
  }

  private func start(_ runtime: GameRuntime) throws -> GameAttemptID {
    runtime.setVisible(true)
    runtime.start()
    guard case .playing(let attempt) = runtime.phase else {
      throw XCTUnwrapError.expectedPlaying
    }
    return attempt
  }

  private enum XCTUnwrapError: Error { case expectedPlaying }
}

/// Intentionally noncooperative delays establish stale-callback behavior; every pause is resumed.
@MainActor
private final class CelebrationDelayGate {
  private let fails: Bool
  init(fails: Bool = false) { self.fails = fails }
  private var count = 0
  private var pauses: [Int: CheckedContinuation<Void, Never>] = [:]
  private var returned = Set<Int>()
  private var starts: [Int: CheckedContinuation<Void, Never>] = [:]
  private var returns: [Int: CheckedContinuation<Void, Never>] = [:]

  func pause() async throws {
    count += 1
    let number = count
    await withCheckedContinuation { continuation in
      pauses[number] = continuation
      starts.removeValue(forKey: number)?.resume()
    }
    returned.insert(number)
    returns.removeValue(forKey: number)?.resume()
    if fails { throw CancellationError() }
  }

  func waitUntilStarted(_ number: Int) async {
    if pauses[number] != nil { return }
    await withCheckedContinuation { starts[number] = $0 }
  }

  func waitUntilReturned(_ number: Int) async {
    if returned.contains(number) { return }
    await withCheckedContinuation { returns[number] = $0 }
  }

  func resume(_ number: Int) { pauses.removeValue(forKey: number)?.resume() }
}
