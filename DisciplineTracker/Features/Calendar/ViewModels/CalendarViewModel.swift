import Foundation
import SwiftData

/// View model for the monthly calendar view.
///
/// Manages month navigation, loads day completion states from persistence,
/// and supports retroactive objective editing.
@MainActor
@Observable
final class CalendarViewModel {
    private(set) var currentMonth: Date = Calendar.current.startOfMonth(for: .now)
    private(set) var dayStates: [Date: DayCompletionState] = [:]
    private(set) var isLoading = false

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
        return raw.prefix(1).uppercased() + raw.dropFirst()
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

    /// Updates progress for an objective on a specific date (retroactive editing).
    /// For retroactive edits, we use toggle action which works for all modes.
    func updateProgress(
        objectiveId: String,
        action: TrackingAction,
        date: Date,
        dayStateService: DayStateService,
        context: ModelContext
    ) {
        guard let objective = dayStateService.configuration?.objectives.first(where: { $0.id == objectiveId }) else {
            return
        }

        do {
            try dayStateService.updateProgressRetroactive(
                objectiveId,
                action: action,
                provider: objective.tracking,
                date: date,
                context: context
            )
            loadMonth(context: context)
        } catch {
            // Error is silently handled; the UI state remains unchanged.
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
