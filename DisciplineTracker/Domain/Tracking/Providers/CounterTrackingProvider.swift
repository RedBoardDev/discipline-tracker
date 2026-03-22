import Foundation

/// Tracking provider for counter-based objectives (e.g., "Drink 2L of water").
struct CounterTrackingProvider: TrackingProvider {
    static let mode = "counter"

    struct Configuration: TrackingConfiguration {
        let target: Double
        let step: Double
        let unit: String
    }

    let configuration: Configuration

    init(configuration: Configuration) {
        self.configuration = configuration
    }

    func isComplete(progress: Double) -> Bool {
        progress >= configuration.target
    }

    func normalizedProgress(_ progress: Double) -> Double {
        guard configuration.target > 0 else { return 0 }
        return min(progress / configuration.target, 1.0)
    }

    var availableActions: Set<TrackingActionKind> {
        [.increment, .decrement, .reset]
    }

    func applyAction(_ action: TrackingAction, to currentProgress: Double) -> Double {
        switch action {
        case .increment(let step):
            currentProgress + step
        case .decrement(let step):
            max(0, currentProgress - step)
        case .reset:
            0.0
        default:
            currentProgress
        }
    }

    var displayInfo: TrackingDisplayInfo {
        let target = configuration.target
        let unit = configuration.unit
        return TrackingDisplayInfo(
            mode: Self.mode,
            progressLabel: { progress in
                let formatted = Self.formatValue(progress)
                let targetFormatted = Self.formatValue(target)
                return "\(formatted) / \(targetFormatted) \(unit)"
            },
            unit: unit,
            showsProgressBar: true,
            step: configuration.step,
            target: target
        )
    }

    private static func formatValue(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }
}
