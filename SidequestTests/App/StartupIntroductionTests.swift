import XCTest

@testable import Sidequest

@MainActor
final class StartupIntroductionTests: XCTestCase {
  func testOneColdPresentationUsesBoundedStagesAndCannotReplay() async {
    let gate = IntroductionPauseGate()
    let model = StartupIntroduction(pause: { try await gate.pause($0) })
    let task = Task { await model.present(reduceMotion: false) }
    await gate.waitForArrival(1)
    XCTAssertEqual(model.phase, .visible)
    await model.present(reduceMotion: false)
    XCTAssertEqual(gate.durations, [.milliseconds(80)])
    gate.resume()
    await gate.waitForArrival(2)
    XCTAssertEqual(model.phase, .fading)
    XCTAssertEqual(gate.durations, [.milliseconds(80), .milliseconds(350)])
    gate.resume()
    await task.value
    XCTAssertTrue(model.isFinished)
    await model.present(reduceMotion: false)
    XCTAssertEqual(gate.durations.count, 2)
  }

  func testBackgroundDismissalRejectsLateNoncooperativePauseAndReplay() async {
    let gate = IntroductionPauseGate()
    let model = StartupIntroduction(pause: { try await gate.pause($0) })
    let task = Task { await model.present(reduceMotion: false) }
    await gate.waitForArrival(1)
    model.dismiss()
    task.cancel()
    gate.resume()
    await task.value
    XCTAssertTrue(model.isFinished)
    await model.present(reduceMotion: false)
    XCTAssertEqual(gate.durations.count, 1)
  }

  func testCancellationDuringFadeFinishesPermanently() async {
    let gate = IntroductionPauseGate()
    let model = StartupIntroduction(pause: { try await gate.pause($0) })
    let task = Task { await model.present(reduceMotion: false) }
    await gate.waitForArrival(1)
    gate.resume()
    await gate.waitForArrival(2)
    task.cancel()
    gate.resume()
    await task.value
    XCTAssertTrue(model.isFinished)
    XCTAssertFalse(model.isShowing)
    await model.present(reduceMotion: false)
    XCTAssertEqual(gate.durations.count, 2)
  }

  func testReduceMotionOmitsAllWaitsAndRemainsConsumed() async {
    var delays = 0
    let model = StartupIntroduction(pause: { _ in delays += 1 })
    await model.present(reduceMotion: true)
    XCTAssertTrue(model.isFinished)
    XCTAssertEqual(delays, 0)
    await model.present(reduceMotion: false)
    XCTAssertEqual(delays, 0)
  }

  func testDelayFailureDismissesWithoutRetryingPresentation() async {
    struct Failure: Error {}
    var calls = 0
    let model = StartupIntroduction(pause: { _ in
      calls += 1
      throw Failure()
    })
    await model.present(reduceMotion: false)
    XCTAssertTrue(model.isFinished)
    await model.present(reduceMotion: false)
    XCTAssertEqual(calls, 1)
  }
}

/// Deliberately ignores cancellation until resumed; named arrivals avoid timing-based assertions.
@MainActor
private final class IntroductionPauseGate {
  private var pauses: [CheckedContinuation<Void, any Error>] = []
  private var arrivals: [(Int, CheckedContinuation<Void, Never>)] = []
  private(set) var durations: [Duration] = []

  func pause(_ duration: Duration) async throws {
    durations.append(duration)
    try await withCheckedThrowingContinuation { continuation in
      pauses.append(continuation)
      let ready = arrivals.filter { $0.0 <= durations.count }
      arrivals.removeAll { $0.0 <= durations.count }
      for observer in ready { observer.1.resume() }
    }
  }

  func waitForArrival(_ count: Int) async {
    guard durations.count < count else { return }
    await withCheckedContinuation { arrivals.append((count, $0)) }
  }

  func resume() { pauses.removeFirst().resume() }
}
