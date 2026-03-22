import Foundation
import SwiftData

/// ViewModel for the Stats screen.
@MainActor
@Observable
final class StatsViewModel: Sendable {
    private let computeStatsUseCase: ComputeStatsUseCase
    private let configObjectives: [ObjectiveDefinition]
    private let repository: DayRecordRepositoryProtocol

    var stats: StatsResult?
    var isLoading = false
    var errorMessage: String?
    var isLoaded: Bool { stats != nil }
    private(set) var heatmapData: [Date: DayCompletionState] = [:]

    var totalActualSeconds: Double {
        stats?.totalActualSeconds ?? 0
    }

    var objectives: [ObjectiveDefinition] {
        configObjectives
    }

    init(
        computeStatsUseCase: ComputeStatsUseCase,
        objectives: [ObjectiveDefinition],
        repository: DayRecordRepositoryProtocol = DayRecordRepository()
    ) {
        self.computeStatsUseCase = computeStatsUseCase
        self.configObjectives = objectives
        self.repository = repository
    }

    func load(context: ModelContext) {
        isLoading = true
        errorMessage = nil

        do {
            stats = try computeStatsUseCase.execute(context: context)
            heatmapData = try loadHeatmapData(context: context)
        } catch {
            errorMessage = error.localizedDescription
            stats = nil
        }

        isLoading = false
    }

    // MARK: - Private

    private func loadHeatmapData(context: ModelContext) throws -> [Date: DayCompletionState] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        guard let startDate = calendar.date(byAdding: .day, value: -90, to: today) else {
            return [:]
        }

        let records = try repository.fetchAll(from: startDate, to: today, context: context)

        var data: [Date: DayCompletionState] = [:]
        for record in records {
            let dayStart = calendar.startOfDay(for: record.date)
            data[dayStart] = record.completionState
        }
        return data
    }
}
