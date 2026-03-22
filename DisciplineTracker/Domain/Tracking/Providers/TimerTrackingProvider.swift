import Foundation

struct TimerTrackingProvider: TrackingProvider {
    static let mode = "timer"

    struct Configuration: TrackingConfiguration {
        let targetSeconds: Double
    }

    let configuration: Configuration

    init(configuration: Configuration) {
        self.configuration = configuration
    }

    func isComplete(progress: Double) -> Bool {
        progress >= configuration.targetSeconds
    }

    func normalizedProgress(_ progress: Double) -> Double {
        guard configuration.targetSeconds > 0 else { return 0 }
        return min(progress / configuration.targetSeconds, 1.0)
    }

    var availableActions: Set<TrackingActionKind> {
        [.start, .pause, .reset, .increment]
    }

    func applyAction(_ action: TrackingAction, to currentProgress: Double) -> Double {
        switch action {
        case .increment(let step):
            currentProgress + step
        case .setProgress(let value):
            max(0, value)
        case .reset:
            0.0
        default:
            currentProgress
        }
    }

    var displayInfo: TrackingDisplayInfo {
        let target = configuration.targetSeconds
        return TrackingDisplayInfo(
            mode: Self.mode,
            progressLabel: { progress in
                let progressFormatted = DurationFormatter.format(progress)
                let targetFormatted = DurationFormatter.format(target)
                return "\(progressFormatted) / \(targetFormatted)"
            },
            unit: nil,
            showsProgressBar: true,
            step: nil,
            target: target
        )
    }
}
