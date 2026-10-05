import Foundation
import Observation

/// One cold-process decoration; it never gates preparation, interaction, or feed lifecycle.
@MainActor
@Observable
final class StartupIntroduction {
  enum Phase { case waiting, visible, fading, finished }
  typealias Pause = @MainActor @Sendable (Duration) async throws -> Void
  private(set) var phase: Phase = .waiting
  private let pause: Pause

  var isFinished: Bool { phase == .finished }
  var isShowing: Bool { phase == .visible || phase == .fading }

  init(pause: @escaping Pause = { try await Task.sleep(for: $0) }) {
    self.pause = pause
  }

  func present(reduceMotion: Bool) async {
    guard phase == .waiting else { return }
    guard !reduceMotion, !Task.isCancelled else {
      dismiss()
      return
    }
    phase = .visible
    defer { dismiss() }
    do {
      try await pause(.milliseconds(80))
      guard !Task.isCancelled, phase == .visible else { return }
      phase = .fading
      try await pause(.milliseconds(350))
      guard !Task.isCancelled, phase == .fading else { return }
      dismiss()
    } catch {
      dismiss()
    }
  }

  func dismiss() { phase = .finished }
}
