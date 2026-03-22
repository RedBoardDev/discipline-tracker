import Foundation
import SwiftData

/// Recalculates a day record's completion state from its objective statuses.
///
/// Extracted from the duplicated logic in `ToggleObjectiveUseCase`,
/// `DayStateService.syncWidgetChanges`, and `GitHubSyncService.syncOnLaunch`.
struct RecalculateDayUseCase: Sendable {
    private let repository: DayRecordRepositoryProtocol

    init(repository: DayRecordRepositoryProtocol) {
        self.repository = repository
    }

    /// Recalculates the completion state for a day record and persists the change.
    func execute(dayRecord: DayRecordModel, context: ModelContext) throws {
        let statuses = dayRecord.objectiveStatuses ?? []
        let scheduledStatuses = statuses.filter(\.isScheduled)
        let completedCount = scheduledStatuses.filter(\.isCompleted).count

        if scheduledStatuses.isEmpty || completedCount == 0 {
            dayRecord.completionState = .empty
            dayRecord.isPerfectDay = false
        } else if completedCount == scheduledStatuses.count {
            dayRecord.completionState = .perfect
            dayRecord.isPerfectDay = true
        } else {
            dayRecord.completionState = .partial
            dayRecord.isPerfectDay = false
        }

        dayRecord.updatedAt = .now
        try repository.save(context: context)
    }
}
