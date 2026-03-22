import Foundation

/// Represents a single day's objective results for streak calculation.
struct DaySnapshot: Sendable {
    let date: Date
    let isPerfectDay: Bool
    let objectiveResults: [ObjectiveResult]
}

/// Represents the result of a single objective for a day.
struct ObjectiveResult: Sendable {
    let objectiveId: String
    let isScheduled: Bool
    let isCompleted: Bool
}

/// Pure functions for calculating streaks from DaySnapshots.
/// This is the single source of truth for streak calculations.
struct StreakCalculator: Sendable {
    /// Calculates all streak metrics from the given day snapshots.
    ///
    /// - Parameters:
    ///   - daySnapshots: Array of day snapshots, should be sorted descending by date.
    ///   - objectiveIds: All objective IDs to consider for per-objective streaks.
    /// - Returns: StreakSnapshot with all calculated streak metrics.
    func calculate(from daySnapshots: [DaySnapshot], objectiveIds: [String]) -> StreakSnapshot {
        var currentPerfectDayStreak = 0
        var bestPerfectDayStreak = 0
        var currentPerfectStreakCount = 0

        // Calculate perfect day streaks
        for snapshot in daySnapshots {
            if snapshot.isPerfectDay {
                currentPerfectStreakCount += 1
                bestPerfectDayStreak = max(bestPerfectDayStreak, currentPerfectStreakCount)
            } else {
                // Check if day gap indicates streak break
                if let previousDate = currentPerfectStreakCount > 0 ? daySnapshots.first(where: { $0.date < snapshot.date })?.date : nil {
                    let gap = Calendar.current.dateComponents([.day], from: snapshot.date, to: previousDate).day ?? 0
                    if gap > 1 {
                        // More than 1 day gap breaks the streak
                        currentPerfectDayStreak = max(currentPerfectDayStreak, currentPerfectStreakCount)
                        currentPerfectStreakCount = 0
                    }
                } else if currentPerfectStreakCount > 0 {
                    // First non-perfect day ends current streak
                    currentPerfectDayStreak = max(currentPerfectDayStreak, currentPerfectStreakCount)
                    currentPerfectStreakCount = 0
                }
            }
        }
        currentPerfectDayStreak = max(currentPerfectDayStreak, currentPerfectStreakCount)
        bestPerfectDayStreak = max(bestPerfectDayStreak, currentPerfectDayStreak)

        // Calculate per-objective streaks
        var perObjectiveCurrentStreak: [String: Int] = [:]
        var perObjectiveBestStreak: [String: Int] = [:]

        for objectiveId in objectiveIds {
            var currentCount = 0
            var bestCount = 0

            for snapshot in daySnapshots {
                if let result = snapshot.objectiveResults.first(where: { $0.objectiveId == objectiveId }) {
                    if result.isScheduled && result.isCompleted {
                        currentCount += 1
                        bestCount = max(bestCount, currentCount)
                    } else if result.isScheduled {
                        // Scheduled but not completed breaks streak
                        currentCount = 0
                    }
                    // If not scheduled, doesn't affect streak
                }
            }

            perObjectiveCurrentStreak[objectiveId] = currentCount
            perObjectiveBestStreak[objectiveId] = bestCount
        }

        return StreakSnapshot(
            currentPerfectDayStreak: currentPerfectDayStreak,
            bestPerfectDayStreak: bestPerfectDayStreak,
            perObjectiveCurrentStreak: perObjectiveCurrentStreak,
            perObjectiveBestStreak: perObjectiveBestStreak
        )
    }
}
