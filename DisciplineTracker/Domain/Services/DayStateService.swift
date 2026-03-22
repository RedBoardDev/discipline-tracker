import Foundation
import SwiftData

/// Single source of truth for the current day's state.
///
/// Loads configuration and day records, exposes today's objectives and their progress,
/// and provides methods to update progress. Intended to be injected via `@Environment`.
@MainActor
@Observable
final class DayStateService {
    private(set) var todayObjectives: [ObjectiveDefinition] = []
    private(set) var progressMap: [String: Double] = [:]
    private(set) var streakSnapshot: StreakSnapshot = .empty
    private(set) var dayCompletionState: DayCompletionState = .empty
    private(set) var completedCount: Int = 0
    private(set) var totalCount: Int = 0
    private(set) var configuration: AppConfiguration?
    private(set) var isLoaded: Bool = false
    private(set) var perfectDaysThisMonth: Int = 0
    private(set) var fullStats: StatsResult = .empty

    private let configLoader: ConfigurationLoader
    private let repository: DayRecordRepositoryProtocol

    init(
        configLoader: ConfigurationLoader = ConfigurationLoader(),
        repository: DayRecordRepositoryProtocol = DayRecordRepository()
    ) {
        self.configLoader = configLoader
        self.repository = repository
    }

    /// Loads the configuration and today's state from persistence.
    func load(context: ModelContext) throws {
        let config = try configLoader.load()
        self.configuration = config

        // Run data migration on first load
        try LegacyDataMigrator.migrateIfNeeded(context: context, objectives: config.objectives)

        try refreshState(with: config.objectives, context: context)
        isLoaded = true
    }

    /// Updates progress for an objective today using a tracking action.
    func updateProgress(
        _ objectiveId: String,
        action: TrackingAction,
        provider: AnyTrackingProvider,
        context: ModelContext
    ) throws {
        guard let config = configuration else {
            throw DayStateServiceError.notLoaded
        }

        let useCase = UpdateProgressUseCase(
            repository: repository,
            objectives: config.objectives
        )
        try useCase.execute(
            objectiveId: objectiveId,
            action: action,
            provider: provider,
            date: .now,
            context: context
        )
        try refreshState(with: config.objectives, context: context)
    }

    /// Updates progress for an objective on a past date (retroactive editing).
    func updateProgressRetroactive(
        _ objectiveId: String,
        action: TrackingAction,
        provider: AnyTrackingProvider,
        date: Date,
        context: ModelContext
    ) throws {
        guard let config = configuration else {
            throw DayStateServiceError.notLoaded
        }

        let useCase = UpdateProgressUseCase(
            repository: repository,
            objectives: config.objectives
        )
        try useCase.execute(
            objectiveId: objectiveId,
            action: action,
            provider: provider,
            date: date,
            context: context
        )
        try refreshState(with: config.objectives, context: context)
    }

    /// Syncs widget changes back to SwiftData on app resume.
    func syncWidgetChanges(context: ModelContext) throws {
        guard let config = configuration,
              let widgetData = WidgetDataProvider.load() else {
            return
        }

        let calendar = Calendar.current
        guard calendar.isDateInToday(widgetData.date) else { return }

        let dayRecord = try repository.fetchOrCreate(
            for: .now,
            objectives: config.objectives,
            context: context
        )

        let statuses = dayRecord.objectiveStatuses ?? []
        var changed = false

        for widgetObj in widgetData.objectives where widgetObj.isManual {
            guard let status = statuses.first(where: { $0.objectiveId == widgetObj.id }) else {
                continue
            }
            if status.isCompleted != widgetObj.isCompleted {
                status.isCompleted = widgetObj.isCompleted
                status.progress = widgetObj.isCompleted ? 1.0 : 0.0
                status.completionSource = widgetObj.isCompleted ? .manual : nil
                status.lastUpdatedAt = .now
                changed = true
            }
        }

        if changed {
            let recalculate = RecalculateDayUseCase(repository: repository)
            try recalculate.execute(dayRecord: dayRecord, context: context)
            try refreshState(with: config.objectives, context: context)
        }
    }

    /// Returns whether an objective is completed today.
    func isCompleted(_ objectiveId: String) -> Bool {
        guard let config = configuration,
              let objective = config.objectives.first(where: { $0.id == objectiveId }) else {
            return false
        }
        let progress = progressMap[objectiveId] ?? 0.0
        return objective.tracking.isComplete(progress: progress)
    }

    // MARK: - Private

    private func refreshState(with objectives: [ObjectiveDefinition], context: ModelContext) throws {
        let getTodayObjectives = GetTodayObjectivesUseCase(objectives: objectives)
        todayObjectives = getTodayObjectives.execute()

        let dayRecord = try repository.fetchOrCreate(for: .now, objectives: objectives, context: context)

        // Build progress map
        var progress: [String: Double] = [:]
        let objectiveStatuses = dayRecord.objectiveStatuses ?? []
        for status in objectiveStatuses {
            progress[status.objectiveId] = status.progress
        }
        progressMap = progress

        // Update counts
        let scheduledStatuses = objectiveStatuses.filter(\.isScheduled)
        totalCount = scheduledStatuses.count
        completedCount = scheduledStatuses.filter(\.isCompleted).count
        dayCompletionState = dayRecord.completionState

        // Compute full stats
        let statsUseCase = ComputeStatsUseCase(repository: repository, objectives: objectives)
        let stats = try statsUseCase.execute(context: context)
        streakSnapshot = stats.streaks
        perfectDaysThisMonth = stats.perfectDaysThisMonth
        fullStats = stats
    }
}

// MARK: - Errors

enum DayStateServiceError: LocalizedError, Sendable {
    case notLoaded

    var errorDescription: String? {
        switch self {
        case .notLoaded:
            "DayStateService has not been loaded yet. Call load(context:) first."
        }
    }
}
