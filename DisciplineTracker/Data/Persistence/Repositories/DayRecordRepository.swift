import Foundation
import SwiftData

/// Protocol defining day record persistence operations.
protocol DayRecordRepositoryProtocol: Sendable {
    func fetchOrCreate(for date: Date, objectives: [ObjectiveDefinition], context: ModelContext) throws -> DayRecordModel
    func fetchAll(from startDate: Date, to endDate: Date, context: ModelContext) throws -> [DayRecordModel]
    func save(context: ModelContext) throws
}

/// Repository handling SwiftData operations for day records.
struct DayRecordRepository: DayRecordRepositoryProtocol {

    func fetchOrCreate(
        for date: Date,
        objectives: [ObjectiveDefinition],
        context: ModelContext
    ) throws -> DayRecordModel {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = #Predicate<DayRecordModel> { record in
            record.date >= startOfDay && record.date < nextDay
        }
        let descriptor = FetchDescriptor<DayRecordModel>(predicate: predicate)
        let existing = try context.fetch(descriptor)

        if let record = existing.first {
            // Reconcile: add statuses for any new objectives missing from this record
            let existingIds = Set((record.objectiveStatuses ?? []).map(\.objectiveId))
            var added = false
            for objective in objectives where !existingIds.contains(objective.id) {
                let isScheduled = objective.isActive(on: startOfDay)
                let status = ObjectiveDayStatusModel(
                    date: startOfDay,
                    objectiveId: objective.id,
                    isScheduled: isScheduled
                )
                status.dayRecord = record
                context.insert(status)
                added = true
            }
            if added {
                try context.save()
            }
            return record
        }

        let record = DayRecordModel(date: startOfDay)
        context.insert(record)

        // Create objective statuses for this day
        for objective in objectives {
            let isScheduled = objective.isActive(on: startOfDay)
            let status = ObjectiveDayStatusModel(
                date: startOfDay,
                objectiveId: objective.id,
                isScheduled: isScheduled
            )
            status.dayRecord = record
            context.insert(status)
        }

        try context.save()
        return record
    }

    func fetchAll(
        from startDate: Date,
        to endDate: Date,
        context: ModelContext
    ) throws -> [DayRecordModel] {
        let start = Calendar.current.startOfDay(for: startDate)
        let end = Calendar.current.startOfDay(for: endDate)

        let predicate = #Predicate<DayRecordModel> { record in
            record.date >= start && record.date <= end
        }
        let descriptor = FetchDescriptor<DayRecordModel>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date)]
        )
        return try context.fetch(descriptor)
    }

    func save(context: ModelContext) throws {
        try context.save()
    }
}
