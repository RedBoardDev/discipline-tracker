import Foundation
import SwiftData

@Model
final class ObjectiveDayStatusModel {
    var date: Date = Date.now
    var objectiveId: String = ""
    var isScheduled: Bool = true
    var isCompleted: Bool = false
    /// Raw progress: 0.0/1.0 for binary, quantity for counter, seconds for timer.
    var progress: Double = 0.0
    var completionSourceRaw: String? = nil
    var lastUpdatedAt: Date = Date.now

    var dayRecord: DayRecordModel?

    var completionSource: CompletionSource? {
        get {
            guard let raw = completionSourceRaw else { return nil }
            return CompletionSource(rawValue: raw)
        }
        set { completionSourceRaw = newValue?.rawValue }
    }

    init(date: Date, objectiveId: String, isScheduled: Bool) {
        let calendar = Calendar.current
        self.date = calendar.startOfDay(for: date)
        self.objectiveId = objectiveId
        self.isScheduled = isScheduled
        self.lastUpdatedAt = .now
    }
}
