import Foundation
import SwiftData

/// Persistent model representing the status of a single objective on a single day.
@Model
final class ObjectiveDayStatusModel {
    /// The date for this status, stored as the start of the day.
    var date: Date = Date.now
    /// The ID of the objective from the JSON configuration.
    var objectiveId: String = ""
    /// Whether this objective was scheduled on this day.
    var isScheduled: Bool = true
    /// Whether this objective was completed.
    var isCompleted: Bool = false
    /// The raw progress value (0.0 for binary not done, 1.0 for binary done,
    /// quantity for counter, seconds for timer).
    var progress: Double = 0.0
    /// How it was completed.
    var completionSourceRaw: String? = nil
    var lastUpdatedAt: Date = Date.now

    /// The parent day record.
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
