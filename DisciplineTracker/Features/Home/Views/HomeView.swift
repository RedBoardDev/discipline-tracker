import SwiftUI
import SwiftData
import WidgetKit

struct HomeView: View {
    @Environment(DayStateService.self) private var dayStateService
    @Environment(TimerSessionService.self) private var timerService
    @Environment(\.modelContext) private var modelContext

    @State private var showPerfectDayCelebration = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if dayStateService.isLoaded {
                    HomeContentView(
                        dayStateService: dayStateService,
                        timerService: timerService,
                        onAction: handleAction,
                        showPerfectDayCelebration: showPerfectDayCelebration
                    )
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("tab.today")
        }
        .onChange(of: dayStateService.dayCompletionState) { oldValue, newValue in
            if oldValue != .perfect, newValue == .perfect {
                HapticManager.perfectDay()
                withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
                    showPerfectDayCelebration = true
                }
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(3))
                    withAnimation(.easeOut(duration: 0.4)) {
                        showPerfectDayCelebration = false
                    }
                }
            }
        }
        .alert("error.title", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("common.close", role: .cancel) { errorMessage = nil }
        } message: {
            Text(verbatim: errorMessage ?? "")
        }
    }

    private func handleAction(objectiveId: String, action: TrackingAction) {
        guard let objective = dayStateService.todayObjectives.first(where: { $0.id == objectiveId }) else {
            return
        }
        do {
            try dayStateService.updateProgress(
                objectiveId,
                action: action,
                provider: objective.tracking,
                context: modelContext
            )
            syncWidgetData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func syncWidgetData() {
        let widgetData = WidgetDayData(
            date: .now,
            currentStreak: dayStateService.streakSnapshot.currentPerfectDayStreak,
            completedCount: dayStateService.completedCount,
            totalCount: dayStateService.totalCount,
            objectives: dayStateService.todayObjectives.map { objective in
                WidgetObjectiveData(
                    id: objective.id,
                    title: objective.title,
                    icon: objective.icon,
                    accentColorName: objective.accent.rawValue,
                    isCompleted: dayStateService.isCompleted(objective.id),
                    isManual: objective.tracking.mode == BinaryTrackingProvider.mode,
                    progress: dayStateService.progressMap[objective.id] ?? 0.0,
                    trackingMode: objective.tracking.mode
                )
            }
        )
        WidgetDataProvider.save(widgetData)
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - Content

private struct HomeContentView: View {
    let dayStateService: DayStateService
    let timerService: TimerSessionService
    let onAction: (String, TrackingAction) -> Void
    let showPerfectDayCelebration: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                StreakHeaderView(
                    currentStreak: dayStateService.streakSnapshot.currentPerfectDayStreak,
                    dayState: dayStateService.dayCompletionState,
                    completedCount: dayStateService.completedCount,
                    totalCount: dayStateService.totalCount,
                    perfectDaysThisMonth: perfectDaysThisMonth
                )

                ObjectivesListView(
                    objectives: dayStateService.todayObjectives,
                    progressMap: dayStateService.progressMap,
                    streaks: dayStateService.streakSnapshot.perObjectiveCurrentStreak,
                    timerService: timerService,
                    onAction: onAction
                )
            }
            .padding(.horizontal)
        }
        .scrollIndicators(.hidden)
        .overlay(alignment: .bottom) {
            if showPerfectDayCelebration {
                PerfectDayBanner()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private var perfectDaysThisMonth: Int {
        dayStateService.perfectDaysThisMonth
    }
}

// MARK: - Objectives List

private struct ObjectivesListView: View {
    let objectives: [ObjectiveDefinition]
    let progressMap: [String: Double]
    let streaks: [String: Int]
    let timerService: TimerSessionService
    let onAction: (String, TrackingAction) -> Void

    var body: some View {
        GlassEffectContainer(spacing: 10) {
            LazyVStack(spacing: 10) {
                ForEach(objectives) { objective in
                    ObjectiveCardView(
                        objective: objective,
                        progress: progressMap[objective.id] ?? 0.0,
                        currentStreak: streaks[objective.id] ?? 0,
                        timerService: timerService,
                        onAction: { action in
                            onAction(objective.id, action)
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Perfect Day Banner

private struct PerfectDayBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "star.fill")
                .foregroundStyle(.yellow)

            Text("home.perfect_day")
                .font(.headline)

            Image(systemName: "star.fill")
                .foregroundStyle(.yellow)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .glassEffect(.regular.tint(.green), in: .capsule)
        .padding(.horizontal)
        .padding(.bottom)
    }
}

#Preview {
    HomeView()
        .environment(DayStateService())
        .environment(TimerSessionService())
        .modelContainer(for: [
            DayRecordModel.self,
            ObjectiveDayStatusModel.self
        ], inMemory: true)
}
