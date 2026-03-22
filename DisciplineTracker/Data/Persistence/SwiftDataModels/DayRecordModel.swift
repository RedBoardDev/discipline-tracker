import Foundation
import SwiftData

/// Persistent model representing the state of a single day.
@Model
final class DayRecordModel {
    /// The date for this record, stored as the start of the day.
    var date: Date = Date.now
    /// The overall completion state of the day.
    var completionStateRaw: String = DayCompletionState.empty.rawValue
    /// Whether this was a perfect day (all scheduled objectives completed).
    var isPerfectDay: Bool = false
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    /// The objective statuses for this day.
    @Relationship(deleteRule: .cascade, inverse: \ObjectiveDayStatusModel.dayRecord)
    var objectiveStatuses: [ObjectiveDayStatusModel]? = []

    var completionState: DayCompletionState {
        get { DayCompletionState(rawValue: completionStateRaw) ?? .empty }
        set { completionStateRaw = newValue.rawValue }
    }

    init(date: Date) {
        let calendar = Calendar.current
        self.date = calendar.startOfDay(for: date)
        self.createdAt = .now
        self.updatedAt = .now
    }
}
