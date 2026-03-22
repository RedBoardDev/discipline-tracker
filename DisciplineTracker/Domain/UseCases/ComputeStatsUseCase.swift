import Foundation
import SwiftData

struct StatsResult: Sendable {
    let streaks: StreakSnapshot
    let perfectDaysLast7: Int
    let perfectDaysLast30: Int
    let completionRatePer7Days: [String: Double]
    let completionRatePer30Days: [String: Double]
    /// Actual tracked time/progress per objective (in the provider's native unit).
    /// For timers: seconds. For counters: quantity. For binary: count of completions.
    let actualProgressPerObjective: [String: Double]
    /// Total actual time across timer-based objectives, in seconds.
    let totalActualSeconds: Double
    let perfectDaysThisMonth: Int

    static let empty = StatsResult(
        streaks: .empty,
        perfectDaysLast7: 0,
        perfectDaysLast30: 0,
        completionRatePer7Days: [:],
        completionRatePer30Days: [:],
        actualProgressPerObjective: [:],
        totalActualSeconds: 0,
        perfectDaysThisMonth: 0
    )
}

struct ComputeStatsUseCase: Sendable {
    private let repository: DayRecordRepositoryProtocol
    private let objectives: [ObjectiveDefinition]
    private let streakCalculator = StreakCalculator()

    init(repository: DayRecordRepositoryProtocol, objectives: [ObjectiveDefinition]) {
        self.repository = repository
        self.objectives = objectives
    }

    func execute(referenceDate: Date = .now, context: ModelContext) throws -> StatsResult {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: referenceDate)

        guard let thirtyDaysAgo = calendar.date(byAdding: .day, value: -29, to: today),
              let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: today) else {
            return .empty
        }

        let allRecords = try repository.fetchAll(from: thirtyDaysAgo, to: today, context: context)

        let daySnapshots = allRecords
            .sorted { $0.date > $1.date }
            .map { record in
                let results = (record.objectiveStatuses ?? []).map { status in
                    ObjectiveResult(
                        objectiveId: status.objectiveId,
                        isScheduled: status.isScheduled,
                        isCompleted: status.isCompleted
                    )
                }
                return DaySnapshot(
                    date: record.date,
                    isPerfectDay: record.isPerfectDay,
                    objectiveResults: results
                )
            }

        let objectiveIds = objectives.map(\.id)
        let streaks = streakCalculator.calculate(from: daySnapshots, objectiveIds: objectiveIds)

        let perfectDaysLast7 = countPerfectDays(in: allRecords, from: sevenDaysAgo, calendar: calendar)
        let perfectDaysLast30 = countPerfectDays(in: allRecords, from: thirtyDaysAgo, calendar: calendar)
        let perfectDaysThisMonth = countPerfectDaysThisMonth(in: allRecords, referenceDate: today, calendar: calendar)
        let ratePer7 = computeCompletionRates(records: allRecords, from: sevenDaysAgo, calendar: calendar)
        let ratePer30 = computeCompletionRates(records: allRecords, from: thirtyDaysAgo, calendar: calendar)
        let progressPerObjective = computeActualProgress(from: allRecords)
        let totalSeconds = computeTotalTimerSeconds(progressPerObjective: progressPerObjective)

        return StatsResult(
            streaks: streaks,
            perfectDaysLast7: perfectDaysLast7,
            perfectDaysLast30: perfectDaysLast30,
            completionRatePer7Days: ratePer7,
            completionRatePer30Days: ratePer30,
            actualProgressPerObjective: progressPerObjective,
            totalActualSeconds: totalSeconds,
            perfectDaysThisMonth: perfectDaysThisMonth
        )
    }

    // MARK: - Private

    private func countPerfectDays(in records: [DayRecordModel], from startDate: Date, calendar: Calendar) -> Int {
        records
            .filter { calendar.compare($0.date, to: startDate, toGranularity: .day) != .orderedAscending }
            .filter(\.isPerfectDay)
            .count
    }

    private func countPerfectDaysThisMonth(in records: [DayRecordModel], referenceDate: Date, calendar: Calendar) -> Int {
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: referenceDate)) else {
            return 0
        }
        return records
            .filter { calendar.compare($0.date, to: startOfMonth, toGranularity: .day) != .orderedAscending }
            .filter { calendar.compare($0.date, to: referenceDate, toGranularity: .day) != .orderedDescending }
            .filter(\.isPerfectDay)
            .count
    }

    private func computeCompletionRates(
        records: [DayRecordModel],
        from startDate: Date,
        calendar: Calendar
    ) -> [String: Double] {
        let filteredRecords = records.filter {
            calendar.compare($0.date, to: startDate, toGranularity: .day) != .orderedAscending
        }

        var scheduledCounts: [String: Int] = [:]
        var completedCounts: [String: Int] = [:]

        for record in filteredRecords {
            let statuses = record.objectiveStatuses ?? []
            for status in statuses where status.isScheduled {
                scheduledCounts[status.objectiveId, default: 0] += 1
                if status.isCompleted {
                    completedCounts[status.objectiveId, default: 0] += 1
                }
            }
        }

        var rates: [String: Double] = [:]
        for (objectiveId, scheduled) in scheduledCounts {
            let completed = completedCounts[objectiveId, default: 0]
            rates[objectiveId] = scheduled > 0 ? Double(completed) / Double(scheduled) : 0
        }

        return rates
    }

    private func computeActualProgress(from records: [DayRecordModel]) -> [String: Double] {
        var result: [String: Double] = [:]
        for record in records {
            let statuses = record.objectiveStatuses ?? []
            for status in statuses where status.isScheduled {
                result[status.objectiveId, default: 0] += status.progress
            }
        }
        return result
    }

    private func computeTotalTimerSeconds(progressPerObjective: [String: Double]) -> Double {
        var total: Double = 0
        for objective in objectives where objective.tracking.mode == TimerTrackingProvider.mode {
            total += progressPerObjective[objective.id, default: 0]
        }
        return total
    }
}
