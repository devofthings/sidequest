import Foundation

/// Replace the complete original document atomically, or leave its prior bytes unchanged.
protocol NewsSnapshotStorage: Sendable {
  func load() async throws -> [NewsSnapshot]?

  /// Success means durable replacement. Never throw cancellation after the write succeeds.
  func save(_ data: Data) async throws
}
