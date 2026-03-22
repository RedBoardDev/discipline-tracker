import Foundation

/// The kind of action a tracking provider can handle.
enum TrackingActionKind: String, Sendable, Hashable {
    case toggle
    case increment
    case decrement
    case setProgress
    case start
    case pause
    case reset
}

/// A concrete action to apply to a tracking provider's progress.
enum TrackingAction: Sendable {
    /// Toggle between complete/incomplete (binary).
    case toggle
    /// Increment progress by a step value.
    case increment(step: Double)
    /// Decrement progress by a step value (clamped to 0).
    case decrement(step: Double)
    /// Set progress to an absolute value.
    case setProgress(Double)
    /// Start a timer session (no direct progress change).
    case start
    /// Pause a timer session (no direct progress change).
    case pause
    /// Reset progress to zero.
    case reset

    /// The kind of this action.
    var kind: TrackingActionKind {
        switch self {
        case .toggle: .toggle
        case .increment: .increment
        case .decrement: .decrement
        case .setProgress: .setProgress
        case .start: .start
        case .pause: .pause
        case .reset: .reset
        }
    }
}
