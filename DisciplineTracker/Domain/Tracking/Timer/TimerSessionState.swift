import Foundation

/// Persisted state for a single running timer segment.
///
/// Only tracks the start time of the current segment. Previous segments
/// are flushed to SwiftData on pause. This avoids double-counting.
struct TimerSessionState: Codable, Sendable {
    let objectiveId: String
    /// When the current segment started (non-nil means running).
    let startedAt: Date

    /// Seconds elapsed in this running segment.
    func currentSegmentElapsed(now: Date = .now) -> Double {
        max(0, now.timeIntervalSince(startedAt))
    }
}
