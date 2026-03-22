import Foundation

/// How an objective was marked as completed.
enum CompletionSource: String, Codable, Sendable {
    /// The user manually checked the objective.
    case manual
    /// Automatically validated by an external source (e.g. GitHub).
    case automatic
    /// Manually overridden by the user for a past day.
    case override
}
