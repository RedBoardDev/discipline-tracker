import Foundation
import SwiftData

@Model
final class DayRecordModel {
    var date: Date = Date.now
    var completionStateRaw: String = DayCompletionState.empty.rawValue
    var isPerfectDay: Bool = false
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

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
