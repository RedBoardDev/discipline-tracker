import SwiftUI
import SwiftData
import WidgetKit

/// The root view with tab-based navigation.
struct RootView: View {
    @State private var dayStateService = DayStateService()
    @State private var timerSessionService = TimerSessionService()
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView {
            Tab("tab.today", systemImage: "checkmark.circle") {
                HomeView()
            }

            Tab("tab.calendar", systemImage: "calendar") {
                CalendarTabView()
            }

            Tab("tab.stats", systemImage: "chart.bar") {
                StatsView()
            }

            Tab("tab.settings", systemImage: "gear") {
                SettingsView()
            }
        }
        .environment(dayStateService)
        .environment(timerSessionService)
        .task {
            try? dayStateService.load(context: modelContext)
            updateWidgetData()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                // Restore timer sessions — timers kept running via startedAt timestamp
                timerSessionService.restoreSessions()
                Task {
                    try? dayStateService.syncWidgetChanges(context: modelContext)
                    try? dayStateService.load(context: modelContext)
                    updateWidgetData()
                }
            case .background:
                // Just persist sessions — DON'T pause timers.
                // They "continue" via startedAt timestamp.
                timerSessionService.persistSessions()
            default:
                break
            }
        }
    }

    private func updateWidgetData() {
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

#Preview {
    RootView()
        .modelContainer(for: [
            DayRecordModel.self,
            ObjectiveDayStatusModel.self
        ], inMemory: true)
}
