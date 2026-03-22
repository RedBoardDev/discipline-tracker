import SwiftUI

struct ObjectiveCardView: View {
    let objective: ObjectiveDefinition
    let progress: Double
    let currentStreak: Int
    let timerService: TimerSessionService
    let onAction: (TrackingAction) -> Void

    private var isCompleted: Bool {
        objective.tracking.isComplete(progress: effectiveProgress)
    }

    private var effectiveProgress: Double {
        if objective.tracking.mode == TimerTrackingProvider.mode {
            return progress + timerService.elapsedSeconds(for: objective.id)
        }
        return progress
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: objective.icon)
                .font(.title2)
                .foregroundStyle(objective.accent.color)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(objective.title)
                    .font(.body)
                    .fontWeight(.medium)

                if currentStreak > 0 {
                    Text("\(currentStreak)j")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            TrackingControlViewFactory.makeControl(
                objective: objective,
                progress: progress,
                timerService: timerService,
                onAction: onAction
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassEffect(
            isCompleted
                ? .regular.tint(objective.accent.color.opacity(0.15))
                : .regular,
            in: .rect(cornerRadius: 16)
        )
        .accessibilityElement(children: .combine)
    }
}
