import Foundation

/// Pure functions for calculating perfect day completion state.
///
/// A perfect day requires all scheduled objectives to be completed.
/// Empty = no objectives scheduled for the day
/// Partial = some objectives scheduled but not all completed
/// Perfect = all scheduled objectives completed
struct PerfectDayCalculator: Sendable {
    /// Calculates the completion state for a given set of objective results.
    ///
    /// - Parameter results: Array of objective results for the day.
    /// - Returns: DayCompletionState (empty, partial, or perfect).
    func calculate(from results: [ObjectiveResult]) -> DayCompletionState {
        let scheduled = results.filter { $0.isScheduled }

        guard !scheduled.isEmpty else {
            return .empty
        }

        let allCompleted = scheduled.allSatisfy { $0.isCompleted }

        return allCompleted ? .perfect : .partial
    }

    /// Determines if a day should be considered a perfect day.
    ///
    /// - Parameter results: Array of objective results for the day.
    /// - Returns: True if all scheduled objectives are completed, false otherwise.
    func isPerfectDay(from results: [ObjectiveResult]) -> Bool {
        calculate(from: results) == .perfect
    }
}
