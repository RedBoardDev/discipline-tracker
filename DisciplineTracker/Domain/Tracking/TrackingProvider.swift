import Foundation

/// Base protocol for configuration types used by tracking providers.
protocol TrackingConfiguration: Codable, Sendable, Hashable {}

/// Each tracking mode (binary, counter, timer, etc.) is a type conforming to this protocol.
/// The provider is a pure domain object — no SwiftUI, no SwiftData.
protocol TrackingProvider: Sendable {
    /// Unique identifier for this tracking mode (used in JSON "mode" field).
    static var mode: String { get }

    associatedtype Configuration: TrackingConfiguration

    var configuration: Configuration { get }

    init(configuration: Configuration)

    func isComplete(progress: Double) -> Bool

    /// Returns progress normalized to 0.0–1.0 range (for progress bars).
    func normalizedProgress(_ progress: Double) -> Double

    var availableActions: Set<TrackingActionKind> { get }

    func applyAction(_ action: TrackingAction, to currentProgress: Double) -> Double

    var displayInfo: TrackingDisplayInfo { get }
}
