import SwiftUI

struct ObjectiveStatsRowView: View {
    let objective: ObjectiveDefinition
    let currentStreak: Int
    let bestStreak: Int
    let completionRate7Days: Double
    let completionRate30Days: Double
    let actualProgress: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HeaderRow(objective: objective)

            HStack(spacing: 16) {
                StreakPill(
                    label: "stats.row.current",
                    value: currentStreak,
                    icon: "flame.fill"
                )
                StreakPill(
                    label: "stats.row.record",
                    value: bestStreak,
                    icon: "trophy.fill"
                )
            }

            CompletionRateBar(
                label: "stats.row.7days",
                rate: completionRate7Days,
                tint: objective.accent.color
            )

            CompletionRateBar(
                label: "stats.row.30days",
                rate: completionRate30Days,
                tint: objective.accent.color.opacity(0.7)
            )

            if let progress = actualProgress, progress > 0 {
                ActualProgressLabel(
                    progress: progress,
                    objective: objective
                )
            }
        }
        .padding()
        .background(objective.accent.color.opacity(0.08))
        .clipShape(.rect(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(objectiveAccessibilityLabel)
    }

    private var objectiveAccessibilityLabel: String {
        var parts = [objective.title]
        parts.append(String(localized: "accessibility.current_streak \(currentStreak)"))
        parts.append(String(localized: "accessibility.best_streak \(bestStreak)"))
        parts.append(String(localized: "accessibility.rate_7days \(Int(completionRate7Days * 100))"))
        parts.append(String(localized: "accessibility.rate_30days \(Int(completionRate30Days * 100))"))
        if let progress = actualProgress, progress > 0 {
            let progressLabel = objective.tracking.displayInfo.progressLabel(progress)
            parts.append(String(localized: "accessibility.progress \(progressLabel)"))
        }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Subviews

private struct HeaderRow: View {
    let objective: ObjectiveDefinition

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: objective.icon)
                .font(.title3)
                .foregroundStyle(objective.accent.color)

            Text(verbatim: objective.title)
                .font(.headline)
        }
    }
}

private struct StreakPill: View {
    let label: LocalizedStringKey
    let value: Int
    let icon: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text("stats.streak_short \(value)")
                .font(.subheadline)
                .bold()

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

private struct CompletionRateBar: View {
    let label: LocalizedStringKey
    let rate: Double
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(rate, format: .percent.precision(.fractionLength(0)))
                    .font(.caption)
                    .bold()
            }

            ProgressView(value: rate)
                .tint(tint)
        }
    }
}

private struct ActualProgressLabel: View {
    let progress: Double
    let objective: ObjectiveDefinition

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock")
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text(verbatim: formattedProgress)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var formattedProgress: String {
        switch objective.tracking.mode {
        case TimerTrackingProvider.mode:
            DurationFormatter.formatCompact(progress)
        default:
            objective.tracking.displayInfo.progressLabel(progress)
        }
    }
}
