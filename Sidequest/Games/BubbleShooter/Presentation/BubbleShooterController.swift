import Foundation
import Observation

struct BubbleAimLease: Equatable {
  fileprivate let id = UUID()
  fileprivate let attempt: GameAttemptID
}

struct BubbleFlight: Equatable {
  let color: BubbleColor
  let position: BubblePoint
}

@MainActor
@Observable
final class BubbleShooterController {
  let runtime: GameRuntime
  private(set) var game: BubbleShooterGame
  private(set) var aimDegrees = 0.0
  private(set) var flight: BubbleFlight?
  private(set) var feedback = "Clear matching groups of three."
  @ObservationIgnored private var attempt: GameAttemptID?
  @ObservationIgnored private var aimLease: BubbleAimLease?
  @ObservationIgnored private var shotTask: Task<Void, Never>?
  @ObservationIgnored private let pause: @MainActor () async throws -> Void

  init(
    runtime: GameRuntime, game: BubbleShooterGame = BubbleShooterGame(),
    completedAim: Double = 0, completedFeedback: String? = nil,
    pause: @escaping @MainActor () async throws -> Void = {
      try await Task.sleep(for: .milliseconds(20))
    }
  ) {
    self.runtime = runtime
    self.game = game
    aimDegrees = completedAim
    if let completedFeedback { feedback = completedFeedback }
    self.pause = pause
    runtime.installEffectHandler { [weak self] effect in self?.apply(effect) }
  }

  deinit { shotTask?.cancel() }

  var canFire: Bool {
    guard let attempt else { return false }
    return runtime.acceptsInput(from: attempt) && flight == nil && game.outcome == .playing
  }

  var canAimOrFire: Bool {
    canFire || (runtime.canBeginInteraction && flight == nil && game.outcome == .playing)
  }

  func aim(degrees: Double, visibility: UUID? = nil) {
    guard degrees.isFinite, canAimOrFire, runtime.prepareInteraction(visibility: visibility),
      canFire
    else { return }
    aimLease = nil
    aimDegrees = min(60, max(-60, degrees))
  }

  /// The guide is a fresh nonmutating trace, never a plan retained for a later commit.
  var aimTrajectory: BubbleTrajectory? {
    guard canFire else { return nil }
    return try? game.traceShot(angleRadians: aimDegrees * .pi / 180).trajectory
  }

  func beginAimDrag(visibility: UUID? = nil) -> BubbleAimLease? {
    guard canAimOrFire, runtime.prepareInteraction(visibility: visibility), canFire, let attempt
    else { return nil }
    let lease = BubbleAimLease(attempt: attempt)
    aimLease = lease
    return lease
  }

  @discardableResult
  func updateAimDrag(_ lease: BubbleAimLease, degrees: Double) -> Bool {
    guard aimLease == lease, runtime.acceptsInput(from: lease.attempt), canFire,
      degrees.isFinite
    else { return false }
    aimDegrees = min(60, max(-60, degrees))
    return true
  }

  func endAimDrag(_ lease: BubbleAimLease) {
    if aimLease == lease { aimLease = nil }
  }

  @discardableResult
  func fire(visibility: UUID? = nil) -> Bool {
    guard canAimOrFire, runtime.prepareInteraction(visibility: visibility), canFire, let attempt
    else { return false }
    do {
      let shot = try game.traceShot(angleRadians: aimDegrees * .pi / 180)
      aimLease = nil
      flight = BubbleFlight(color: shot.color, position: BubbleGeometry.launcher)
      feedback = "Shot in flight."
      shotTask = Task { [weak self, pause] in
        do {
          for step in 1...24 {
            try await pause()
            try Task.checkCancellation()
            guard let self, runtime.acceptsInput(from: attempt) else { return }
            flight = BubbleFlight(
              color: shot.color,
              position: Self.position(on: shot.trajectory, fraction: Double(step) / 24))
          }
          guard let self, runtime.acceptsInput(from: attempt) else { return }
          let result = try game.commitShot(shot)
          flight = nil
          shotTask = nil
          switch result.outcome {
          case .playing:
            if !result.matched.isEmpty || !result.detached.isEmpty {
              runtime.feedbackForInteraction(attempt: attempt)
            }
            feedback =
              result.matched.isEmpty
              ? "Bubble attached. Try a matching group."
              : "Cleared \(result.matched.count) matching and \(result.detached.count) detached bubbles."
          case .won:
            feedback = "Board cleared!"
            runtime.complete(attempt: attempt, successful: true)
          case .lost:
            feedback = "Challenge ended. Try again."
            runtime.complete(attempt: attempt)
          }
        } catch is CancellationError {
          // Reset/stop already cleared or preserved state; canceled work cannot touch a new attempt.
        } catch {
          guard let self, runtime.acceptsInput(from: attempt) else { return }
          flight = nil
          shotTask = nil
          feedback = "Could not fire this shot. Adjust your aim and try again."
        }
      }
      return true
    } catch {
      feedback = "Could not trace this shot. Adjust your aim and try again."
      return false
    }
  }

  @discardableResult
  func replay() -> Bool { runtime.replay() }

  private func apply(_ effect: GameLifecycleEffect) {
    aimLease = nil
    shotTask?.cancel()
    shotTask = nil
    flight = nil
    switch effect {
    case .start(let attempt):
      self.attempt = attempt
      game.reset()
      aimDegrees = 0
      feedback = "Clear matching groups of three."
    case .reset:
      attempt = nil
      game.reset()
      aimDegrees = 0
      feedback = "Clear matching groups of three."
    case .stop:
      attempt = nil
    }
  }

  private static func position(on trajectory: BubbleTrajectory, fraction: Double) -> BubblePoint {
    let segments = zip(trajectory.points, trajectory.points.dropFirst()).map { start, end in
      (start, end, start.distanceSquared(to: end).squareRoot())
    }
    var remaining = segments.reduce(0) { $0 + $1.2 } * fraction
    for (start, end, length) in segments {
      if remaining <= length, length > 0 {
        let ratio = remaining / length
        return BubblePoint(
          x: start.x + (end.x - start.x) * ratio, y: start.y + (end.y - start.y) * ratio)
      }
      remaining -= length
    }
    return trajectory.points.last ?? BubbleGeometry.launcher
  }
}
