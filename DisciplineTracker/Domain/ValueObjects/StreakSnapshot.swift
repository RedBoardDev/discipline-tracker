import Foundation

/// A snapshot of all streak-related statistics, computed on demand.
struct StreakSnapshot: Sendable {
    let currentPerfectDayStreak: Int
    let bestPerfectDayStreak: Int
    let perObjectiveCurrentStreak: [String: Int]
    let perObjectiveBestStreak: [String: Int]

    static let empty = StreakSnapshot(
        currentPerfectDayStreak: 0,
        bestPerfectDayStreak: 0,
        perObjectiveCurrentStreak: [:],
        perObjectiveBestStreak: [:]
    )
}
