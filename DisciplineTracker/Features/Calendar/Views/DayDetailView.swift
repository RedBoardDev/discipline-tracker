import SwiftUI
import SwiftData

struct DayDetailView: View {
    let date: Date
    let objectives: [ObjectiveDefinition]
    let onAction: (String, TrackingAction) -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale

    @State private var statuses: [String: Bool] = [:]
    @State private var progressValues: [String: Double] = [:]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(activeObjectives) { objective in
                        DayDetailRow(
                            objective: objective,
                            isCompleted: statuses[objective.id] ?? false,
                            progress: progressValues[objective.id] ?? 0.0,
                            onToggle: {
                                onAction(objective.id, .toggle)
                                let wasCompleted = statuses[objective.id] ?? false
                                statuses[objective.id] = !wasCompleted
                                if !wasCompleted {
                                    progressValues[objective.id] = objective.tracking.displayInfo.target
                                } else {
                                    progressValues[objective.id] = 0.0
                                }
                            }
                        )
                    }
                } header: {
                    Text(verbatim: date.formatted(
                        .dateTime.weekday(.wide).day().month(.wide).locale(locale)
                    ))
                    .textCase(nil)
                }
            }
            .navigationTitle("day_detail.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.close") { dismiss() }
                }
            }
            .task {
                loadStatuses()
            }
        }
    }

    // MARK: - Private

    private var activeObjectives: [ObjectiveDefinition] {
        objectives
            .filter { $0.isActive(on: date) }
            .sorted { $0.displayOrder < $1.displayOrder }
    }

    private func loadStatuses() {
        let repository = DayRecordRepository()
        guard let record = try? repository.fetchOrCreate(
            for: date,
            objectives: objectives,
            context: modelContext
        ) else {
            return
        }
        let objectiveStatuses = record.objectiveStatuses ?? []
        var statusMap: [String: Bool] = [:]
        var progressMap: [String: Double] = [:]
        for status in objectiveStatuses {
            statusMap[status.objectiveId] = status.isCompleted
            progressMap[status.objectiveId] = status.progress
        }
        statuses = statusMap
        progressValues = progressMap
    }
}

// MARK: - Row

private struct DayDetailRow: View {
    let objective: ObjectiveDefinition
    let isCompleted: Bool
    let progress: Double
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: objective.icon)
                .foregroundStyle(objective.accent.color)
                .frame(width: 28)

            Text(verbatim: objective.title)

            Spacer()

            toggleIndicator
        }
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var toggleIndicator: some View {
        if objective.tracking.mode == BinaryTrackingProvider.mode {
            Button(action: onToggle) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isCompleted ? objective.accent.color : .secondary)
            }
            .buttonStyle(.plain)
        } else {
            VStack(alignment: .trailing, spacing: 2) {
                Text(verbatim: objective.tracking.displayInfo.progressLabel(progress))
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Button(action: onToggle) {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isCompleted ? objective.accent.color : .secondary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    DayDetailView(
        date: .now,
        objectives: [],
        onAction: { _, _ in }
    )
    .modelContainer(
        for: [DayRecordModel.self, ObjectiveDayStatusModel.self],
        inMemory: true
    )
}
