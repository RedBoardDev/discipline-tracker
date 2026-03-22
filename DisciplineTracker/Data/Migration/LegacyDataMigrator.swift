import Foundation
import SwiftData

/// Migrates existing data from the binary-only model to the progress-based model.
///
/// For each `ObjectiveDayStatusModel` where `isCompleted == true && progress == 0.0`,
/// sets `progress` to the appropriate target value based on the objective's tracking provider.
enum LegacyDataMigrator {
    private static let migrationKey = "v2_tracking_migration_done"

    /// Runs the migration if it hasn't been performed yet. Idempotent.
    static func migrateIfNeeded(
        context: ModelContext,
        objectives: [ObjectiveDefinition]
    ) throws {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: migrationKey) else { return }

        let descriptor = FetchDescriptor<ObjectiveDayStatusModel>()
        let allStatuses = try context.fetch(descriptor)

        let objectiveMap = Dictionary(uniqueKeysWithValues: objectives.map { ($0.id, $0) })

        for status in allStatuses where status.isCompleted && status.progress == 0.0 {
            if let objective = objectiveMap[status.objectiveId] {
                status.progress = targetProgress(for: objective.tracking)
            } else {
                // Objective was removed from config — safe fallback
                status.progress = 1.0
            }
        }

        try context.save()
        defaults.set(true, forKey: migrationKey)
    }

    private static func targetProgress(for provider: AnyTrackingProvider) -> Double {
        switch provider.mode {
        case BinaryTrackingProvider.mode:
            1.0
        case CounterTrackingProvider.mode:
            // Use the provider to determine what "complete" means
            // For counter, completing means reaching target — but we don't know the exact
            // target from the type-erased provider, so we use a simple heuristic:
            // if isComplete(1.0) returns true, use 1.0, otherwise try common values
            if provider.isComplete(progress: 1.0) {
                1.0
            } else {
                // The objective was completed, so set progress to a value that makes isComplete true
                // We iterate to find the target (provider.normalizedProgress(x) == 1.0)
                findCompletionProgress(for: provider)
            }
        case TimerTrackingProvider.mode:
            findCompletionProgress(for: provider)
        default:
            1.0
        }
    }

    /// Binary searches for the minimum progress value that makes the provider report complete.
    private static func findCompletionProgress(for provider: AnyTrackingProvider) -> Double {
        // Try common target values
        let candidates: [Double] = [1.0, 60, 300, 600, 900, 1800, 2700, 3600, 5400, 7200]
        for value in candidates {
            if provider.isComplete(progress: value) && provider.normalizedProgress(value) >= 1.0 {
                return value
            }
        }
        // Fallback: just report as 1.0
        return 1.0
    }
}
