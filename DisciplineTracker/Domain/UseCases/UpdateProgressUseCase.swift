import Foundation
import SwiftData

/// Central use case for updating an objective's progress.
///
/// Replaces `ToggleObjectiveUseCase` with a provider-aware approach:
/// applies the tracking action via the provider, persists progress,
/// and recalculates the day's completion state.
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

    /// Applies a tracking action to an objective and persists the result.
    ///
    /// - Parameters:
    ///   - objectiveId: The objective to update.
    ///   - action: The tracking action to apply.
    ///   - provider: The type-erased tracking provider for this objective.
    ///   - date: The date to update (today or retroactive).
    ///   - context: The SwiftData model context.
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
            return
        }

        let newProgress = provider.applyAction(action, to: status.progress)
        status.progress = newProgress
        status.isCompleted = provider.isComplete(progress: newProgress)
        status.completionSource = status.isCompleted ? .manual : nil
        status.lastUpdatedAt = .now

        try recalculateDay.execute(dayRecord: dayRecord, context: context)
    }
}
