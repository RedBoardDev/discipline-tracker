import Foundation
import SwiftData

@MainActor
@Observable
final class CalendarViewModel {
    private(set) var currentMonth: Date = Calendar.current.startOfMonth(for: .now)
    private(set) var dayStates: [Date: DayCompletionState] = [:]
    private(set) var isLoading = false
    var errorMessage: String?

    private let repository: DayRecordRepositoryProtocol
    private let calendar = Calendar.current

    init(repository: DayRecordRepositoryProtocol = DayRecordRepository()) {
        self.repository = repository
    }

    // MARK: - Computed

    var daysInMonth: [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: currentMonth) else {
            return []
        }
        return range.compactMap { day in
            calendar.date(bySetting: .day, value: day, of: currentMonth)
        }
    }

    var firstWeekdayOffset: Int {
        guard let firstDay = daysInMonth.first else { return 0 }
        let weekday = calendar.component(.weekday, from: firstDay)
        return (weekday + 5) % 7
    }

    func monthTitle(locale: Locale = .autoupdatingCurrent) -> String {
        let raw = currentMonth.formatted(.dateTime.month(.wide).year().locale(locale))
        return raw.capitalized(with: locale)
    }

    var canGoForward: Bool {
        let currentMonthStart = calendar.startOfMonth(for: .now)
        return currentMonth < currentMonthStart
    }

    // MARK: - Actions

    func loadMonth(context: ModelContext) {
        guard let lastDay = daysInMonth.last,
              let endOfMonth = calendar.date(byAdding: .day, value: 1, to: lastDay) else {
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let records = try repository.fetchAll(
                from: currentMonth,
                to: endOfMonth,
                context: context
            )

            var states: [Date: DayCompletionState] = [:]
            for record in records {
                let dayStart = calendar.startOfDay(for: record.date)
                states[dayStart] = record.completionState
            }
            dayStates = states
        } catch {
            dayStates = [:]
        }
    }

    func goToNextMonth(context: ModelContext) {
        guard canGoForward,
              let next = calendar.date(byAdding: .month, value: 1, to: currentMonth) else {
            return
        }
        currentMonth = calendar.startOfMonth(for: next)
        loadMonth(context: context)
    }

    func goPreviousMonth(context: ModelContext) {
        guard let previous = calendar.date(byAdding: .month, value: -1, to: currentMonth) else {
            return
        }
        currentMonth = calendar.startOfMonth(for: previous)
        loadMonth(context: context)
    }

    func updateProgress(
        objectiveId: String,
        action: TrackingAction,
        date: Date,
        dayStateService: DayStateService,
        context: ModelContext
    ) {
        errorMessage = nil
        guard let objective = dayStateService.configuration?.objectives.first(where: { $0.id == objectiveId }) else {
            return
        }

        // Translate toggle to a meaningful action for non-binary providers.
        // For past dates, load the actual persisted progress rather than today's progressMap.
        let resolvedAction: TrackingAction
        if case .toggle = action, objective.tracking.mode != BinaryTrackingProvider.mode {
            let currentProgress: Double
            if let record = try? repository.fetchOrCreate(
                for: date,
                objectives: dayStateService.configuration?.objectives ?? [],
                context: context
            ), let status = (record.objectiveStatuses ?? []).first(where: { $0.objectiveId == objectiveId }) {
                currentProgress = status.progress
            } else {
                currentProgress = 0.0
            }
            let isComplete = objective.tracking.isComplete(progress: currentProgress)
            resolvedAction = isComplete ? .setProgress(0) : .setProgress(objective.tracking.displayInfo.target)
        } else {
            resolvedAction = action
        }

        do {
            try dayStateService.updateProgressRetroactive(
                objectiveId,
                action: resolvedAction,
                provider: objective.tracking,
                date: date,
                context: context
            )
            loadMonth(context: context)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Calendar Extension

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? startOfDay(for: date)
    }
}
