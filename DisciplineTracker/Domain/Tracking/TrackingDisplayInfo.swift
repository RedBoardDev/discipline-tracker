import Foundation

/// Display metadata for a tracking provider, used by the UI layer.
struct TrackingDisplayInfo: Sendable {
    /// The tracking mode identifier (e.g., "binary", "counter", "timer").
    let mode: String
    /// Human-readable label for the current progress (e.g., "1.5 / 2.0 L").
    let progressLabel: @Sendable (Double) -> String
    /// Optional unit label (e.g., "L", "min").
    let unit: String?
    /// Whether this mode shows a progress bar.
    let showsProgressBar: Bool
    /// The default increment/decrement step for counter modes (nil for non-counter modes).
    let step: Double?
    /// The target value (e.g., targetSeconds for timer, target for counter, 1.0 for binary).
    let target: Double
}
