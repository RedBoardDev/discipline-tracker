import Foundation

/// Tracking provider for simple done/not-done objectives.
struct BinaryTrackingProvider: TrackingProvider {
    static let mode = "binary"

    struct Configuration: TrackingConfiguration {
        // No additional configuration needed for binary tracking.
    }

    let configuration: Configuration

    init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }

    func isComplete(progress: Double) -> Bool {
        progress >= 1.0
    }

    func normalizedProgress(_ progress: Double) -> Double {
        progress >= 1.0 ? 1.0 : 0.0
    }

    var availableActions: Set<TrackingActionKind> {
        [.toggle]
    }

    func applyAction(_ action: TrackingAction, to currentProgress: Double) -> Double {
        switch action {
        case .toggle:
            currentProgress >= 1.0 ? 0.0 : 1.0
        case .reset:
            0.0
        default:
            currentProgress
        }
    }

    var displayInfo: TrackingDisplayInfo {
        TrackingDisplayInfo(
            mode: Self.mode,
            progressLabel: { $0 >= 1.0 ? "Fait" : "À faire" },
            unit: nil,
            showsProgressBar: false,
            step: nil,
            target: 1.0
        )
    }
}
