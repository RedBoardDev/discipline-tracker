import SwiftUI

struct TimerControlView: View {
    let persistedProgress: Double
    let provider: AnyTrackingProvider
    let accentColor: Color
    let timerService: TimerSessionService
    let objectiveId: String
    let onAction: (TrackingAction) -> Void

    @State private var showManualEntry = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { _ in
            let liveElapsed = timerService.elapsedSeconds(for: objectiveId)
            let totalProgress = persistedProgress + liveElapsed
            let isRunning = timerService.isRunning(objectiveId)
            let isComplete = provider.isComplete(progress: totalProgress)

            HStack(spacing: 10) {
                Button {
                    showManualEntry = true
                } label: {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(DurationFormatter.format(totalProgress))
                            .font(.system(.caption, design: .monospaced, weight: .semibold))
                            .foregroundStyle(isComplete ? accentColor : .primary)
                            .contentTransition(.numericText())

                        Text(DurationFormatter.format(provider.displayInfo.target))
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)

                Button {
                    if isRunning {
                        let delta = timerService.pause(objectiveId: objectiveId)
                        if delta > 0 {
                            onAction(.increment(step: delta))
                        }
                    } else {
                        HapticManager.shared.medium()
                        timerService.start(objectiveId: objectiveId)
                    }
                } label: {
                    Image(systemName: isRunning ? "pause.circle.fill" : "play.circle.fill")
                        .font(.title2)
                        .foregroundStyle(accentColor)
                        .symbolEffect(.pulse, isActive: isRunning)
                }
                .buttonStyle(.plain)
            }
            .sheet(isPresented: $showManualEntry) {
                ManualTimeEntrySheet(
                    currentSeconds: totalProgress,
                    targetSeconds: provider.displayInfo.target,
                    accentColor: accentColor,
                    onSet: { newSeconds in
                        onAction(.setProgress(newSeconds))
                    }
                )
                .presentationDetents([.medium])
            }
        }
    }
}

// MARK: - Manual Time Entry

private struct ManualTimeEntrySheet: View {
    let currentSeconds: Double
    let targetSeconds: Double
    let accentColor: Color
    let onSet: (Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var hours: Int = 0
    @State private var minutes: Int = 0
    @State private var seconds: Int = 0

    private var totalSeconds: Double {
        Double(hours * 3600 + minutes * 60 + seconds)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("timer.current_time \(DurationFormatter.format(currentSeconds))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 0) {
                    wheelColumn(value: $hours, range: 0...23, label: "h")
                    wheelColumn(value: $minutes, range: 0...59, label: "m")
                    wheelColumn(value: $seconds, range: 0...59, label: "s")
                }
                .frame(height: 180)

                Button {
                    onSet(totalSeconds)
                    dismiss()
                } label: {
                    Text("timer.set \(DurationFormatter.format(totalSeconds))")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(accentColor)

                Button("timer.reset", role: .destructive) {
                    onSet(0)
                    dismiss()
                }
                .font(.subheadline)

                Spacer()
            }
            .padding()
            .navigationTitle("timer.edit_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.close") { dismiss() }
                }
            }
            .onAppear {
                let total = Int(currentSeconds)
                hours = total / 3600
                minutes = (total % 3600) / 60
                seconds = total % 60
            }
        }
    }

    private func wheelColumn(
        value: Binding<Int>,
        range: ClosedRange<Int>,
        label: String
    ) -> some View {
        HStack(spacing: 2) {
            Picker("", selection: value) {
                ForEach(range, id: \.self) { n in
                    Text("\(n)")
                        .font(.system(.title2, design: .monospaced, weight: .medium))
                        .tag(n)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 70)
            .clipped()

            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 16, alignment: .leading)
        }
    }
}
