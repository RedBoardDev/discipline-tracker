import Foundation

/// The global completion state for a given day.
enum DayCompletionState: String, Codable, Sendable {
    /// No objectives completed.
    case empty
    /// Some but not all objectives completed.
    case partial
    /// All scheduled objectives completed — a perfect day.
    case perfect
}
