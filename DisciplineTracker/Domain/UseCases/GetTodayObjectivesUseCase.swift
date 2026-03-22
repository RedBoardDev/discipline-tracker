import Foundation

struct GetTodayObjectivesUseCase: Sendable {
    private let objectives: [ObjectiveDefinition]
    private let date: Date

    init(objectives: [ObjectiveDefinition], date: Date = .now) {
        self.objectives = objectives
        self.date = date
    }

    func execute() -> [ObjectiveDefinition] {
        objectives
            .filter { $0.isActive(on: date) }
            .sorted { $0.displayOrder < $1.displayOrder }
    }
}
