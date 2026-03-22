import SwiftUI
import SwiftData

/// Statistics screen with streaks, heatmap, and completion rates.
struct StatsView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel: StatsViewModel?
    @State private var dayStateService = DayStateService()

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel, viewModel.isLoaded {
                    StatsContent(viewModel: viewModel)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("stats.title")
            .task {
                if viewModel == nil {
                    try? await loadConfiguration()
                }
            }
        }
    }

    private func loadConfiguration() async throws {
        try dayStateService.load(context: modelContext)
        if let config = dayStateService.configuration {
            await MainActor.run {
                viewModel = StatsViewModel(
                    computeStatsUseCase: ComputeStatsUseCase(
                        repository: DayRecordRepository(),
                        objectives: config.objectives
                    ),
                    objectives: config.objectives
                )
            }
        }
        viewModel?.load(context: modelContext)
    }
}

// MARK: - Content

private struct StatsContent: View {
    let viewModel: StatsViewModel

    private var stats: StatsResult {
        viewModel.stats ?? .empty
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                StreakSection(streaks: stats.streaks)

                WeeklySummarySection(
                    perfectDaysLast7: stats.perfectDaysLast7,
                    perfectDaysLast30: stats.perfectDaysLast30
                )

                TotalActualTimeSection(
                    totalSeconds: viewModel.totalActualSeconds
                )

                ObjectivesSection(
                    objectives: viewModel.objectives,
                    stats: stats
                )

                HeatmapSection(data: viewModel.heatmapData)
            }
            .padding()
        }
    }
}

// MARK: - Streak Section

private struct StreakSection: View {
    let streaks: StreakSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "stats.section.streaks", icon: "flame.fill")

            HStack(spacing: 12) {
                StreakCardView(
                    value: "\(streaks.currentPerfectDayStreak)",
                    label: "stats.current_streak",
                    icon: "flame.fill",
                    tint: .orange
                )

                StreakCardView(
                    value: "\(streaks.bestPerfectDayStreak)",
                    label: "stats.best_streak",
                    icon: "trophy.fill",
                    tint: .yellow
                )
            }
        }
    }
}

// MARK: - Weekly/Monthly Summary

private struct WeeklySummarySection: View {
    let perfectDaysLast7: Int
    let perfectDaysLast30: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "stats.section.perfect_days", icon: "star.fill")

            HStack(spacing: 12) {
                StreakCardView(
                    value: "\(perfectDaysLast7)/7",
                    label: "stats.last_7_days",
                    icon: "calendar",
                    tint: .green
                )

                StreakCardView(
                    value: "\(perfectDaysLast30)/30",
                    label: "stats.last_30_days",
                    icon: "calendar",
                    tint: .blue
                )
            }
        }
    }
}

// MARK: - Per-Objective Section

private struct ObjectivesSection: View {
    let objectives: [ObjectiveDefinition]
    let stats: StatsResult

    var body: some View {
        if !objectives.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "stats.section.by_objective", icon: "list.bullet")

                ForEach(objectives) { objective in
                    ObjectiveStatsRowView(
                        objective: objective,
                        currentStreak: stats.streaks.perObjectiveCurrentStreak[objective.id, default: 0],
                        bestStreak: stats.streaks.perObjectiveBestStreak[objective.id, default: 0],
                        completionRate7Days: stats.completionRatePer7Days[objective.id, default: 0],
                        completionRate30Days: stats.completionRatePer30Days[objective.id, default: 0],
                        actualProgress: stats.actualProgressPerObjective[objective.id]
                    )
                }
            }
        }
    }
}

// MARK: - Total Actual Time Section

private struct TotalActualTimeSection: View {
    let totalSeconds: Double

    var body: some View {
        if totalSeconds > 0 {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "stats.section.total_time", icon: "clock.fill")

                TotalActualTimeCard(totalSeconds: totalSeconds)
            }
        }
    }
}

private struct TotalActualTimeCard: View {
    let totalSeconds: Double

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "hourglass")
                .font(.title2)
                .foregroundStyle(.indigo)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: DurationFormatter.formatCompact(totalSeconds))
                    .font(.title2)
                    .bold()
                    .foregroundStyle(.indigo)

                Text("stats.practice_footer")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(.indigo.opacity(0.1))
        .clipShape(.rect(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("stats.total_time_accessibility \(DurationFormatter.formatCompact(totalSeconds))"))
    }
}

// MARK: - Heatmap Section

private struct HeatmapSection: View {
    let data: [Date: DayCompletionState]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "stats.section.activity", icon: "square.grid.3x3.fill")

            HeatmapView(data: data)
        }
    }
}

// MARK: - Section Header

private struct SectionHeader: View {
    let title: LocalizedStringKey
    let icon: String

    var body: some View {
        Label(title, systemImage: icon)
            .font(.headline)
    }
}

#Preview {
    StatsView()
        .modelContainer(for: [
            DayRecordModel.self,
            ObjectiveDayStatusModel.self
        ], inMemory: true)
}
