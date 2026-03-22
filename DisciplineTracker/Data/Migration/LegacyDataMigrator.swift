import Foundation
import SwiftData

enum LegacyDataMigrator {
    private static let migrationKey = "v2_tracking_migration_done"

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
                status.progress = objective.tracking.displayInfo.target
            } else {
                // Objective was removed from config — use binary target as fallback
                status.progress = 1.0
            }
        }

        try context.save()
        defaults.set(true, forKey: migrationKey)
    }
}
