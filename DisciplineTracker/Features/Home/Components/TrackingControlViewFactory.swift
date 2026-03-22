import SwiftUI

enum TrackingControlViewFactory {
    @MainActor @ViewBuilder
    static func makeControl(
        objective: ObjectiveDefinition,
        progress: Double,
        timerService: TimerSessionService,
        onAction: @escaping (TrackingAction) -> Void
    ) -> some View {
        let provider = objective.tracking
        let accentColor = objective.accent.color

        switch provider.mode {
        case BinaryTrackingProvider.mode:
            BinaryControlView(
                isCompleted: provider.isComplete(progress: progress),
                accentColor: accentColor,
                onAction: onAction
            )
        case CounterTrackingProvider.mode:
            CounterControlView(
                progress: progress,
                provider: provider,
                accentColor: accentColor,
                onAction: onAction
            )
        case TimerTrackingProvider.mode:
            TimerControlView(
                persistedProgress: progress,
                provider: provider,
                accentColor: accentColor,
                timerService: timerService,
                objectiveId: objective.id,
                onAction: onAction
            )
        default:
            // Fallback: treat as binary
            BinaryControlView(
                isCompleted: provider.isComplete(progress: progress),
                accentColor: accentColor,
                onAction: onAction
            )
        }
    }
}
