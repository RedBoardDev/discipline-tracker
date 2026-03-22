import Foundation
import SwiftData

enum UpdateProgressError: LocalizedError, Sendable {
    case objectiveStatusNotFound(String)

    var errorDescription: String? {
        switch self {
        case .objectiveStatusNotFound(let id):
            "No status record found for objective '\(id)' on the requested day."
        }
    }
}

struct UpdateProgressUseCase: Sendable {
    private let repository: DayRecordRepositoryProtocol
    private let objectives: [ObjectiveDefinition]
    private let recalculateDay: RecalculateDayUseCase

    init(
        repository: DayRecordRepositoryProtocol,
        objectives: [ObjectiveDefinition]
    ) {
        self.repository = repository
        self.objectives = objectives
        self.recalculateDay = RecalculateDayUseCase(repository: repository)
    }

    func execute(
        objectiveId: String,
        action: TrackingAction,
        provider: AnyTrackingProvider,
        date: Date,
        context: ModelContext
    ) throws {
        let dayRecord = try repository.fetchOrCreate(
            for: date,
            objectives: objectives,
            context: context
        )
        let statuses = dayRecord.objectiveStatuses ?? []

        guard let status = statuses.first(where: { $0.objectiveId == objectiveId }) else {
            throw UpdateProgressError.objectiveStatusNotFound(objectiveId)
        }

        let newProgress = provider.applyAction(action, to: status.progress)
        status.progress = newProgress
        status.isCompleted = provider.isComplete(progress: newProgress)
        status.completionSource = status.isCompleted ? .manual : nil
        status.lastUpdatedAt = .now

        try recalculateDay.execute(dayRecord: dayRecord, context: context)
    }
}
