/// Main-actor transaction capabilities; capture origin before import I/O can suspend.
@MainActor
struct NewsReplacementRequest {
  let prepare: @MainActor ([NewsSnapshot]) async throws -> PreparedNewsReplacement
}

@MainActor
struct PreparedNewsReplacement {
  /// Validate origin and exclusively reserve the save/adoption boundary.
  let acquire: @MainActor () throws -> Void
  /// After durable save, commit never suspends, fails, or checks cancellation.
  let commit: @MainActor () -> Void
  let release: @MainActor () -> Void
}
