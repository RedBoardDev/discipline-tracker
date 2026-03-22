import Foundation

enum TrackingActionKind: String, Sendable, Hashable {
    case toggle
    case increment
    case decrement
    case setProgress
    case start
    case pause
    case reset
}

enum TrackingAction: Sendable {
    case toggle
    case increment(step: Double)
    case decrement(step: Double)
    case setProgress(Double)
    case start
    case pause
    case reset

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
