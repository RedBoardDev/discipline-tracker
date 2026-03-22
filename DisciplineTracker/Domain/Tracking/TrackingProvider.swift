import Foundation

/// Base protocol for configuration types used by tracking providers.
protocol TrackingConfiguration: Codable, Sendable, Hashable {}

/// Protocol defining a tracking mode for objectives.
///
/// Each tracking mode (binary, counter, timer, etc.) is a type conforming to this protocol.
/// The provider is a pure domain object — no SwiftUI, no SwiftData.
protocol TrackingProvider: Sendable {
    /// Unique identifier for this tracking mode (used in JSON "mode" field).
    static var mode: String { get }

    /// The configuration type for this provider (decoded from JSON).
    associatedtype Configuration: TrackingConfiguration

    /// The decoded configuration.
    var configuration: Configuration { get }

    /// Creates a provider from a decoded configuration.
    init(configuration: Configuration)

    /// Whether the given progress value meets the completion target.
    func isComplete(progress: Double) -> Bool

    /// Returns progress normalized to 0.0–1.0 range (for progress bars).
    func normalizedProgress(_ progress: Double) -> Double

    /// The set of actions this provider supports.
    var availableActions: Set<TrackingActionKind> { get }

    /// Applies an action to the current progress and returns the new progress.
    func applyAction(_ action: TrackingAction, to currentProgress: Double) -> Double

    /// Display metadata for the UI layer.
    var displayInfo: TrackingDisplayInfo { get }
}
