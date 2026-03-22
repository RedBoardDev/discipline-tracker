import SwiftUI

/// Control view for counter-based objectives (e.g., water intake).
struct CounterControlView: View {
    let progress: Double
    let provider: AnyTrackingProvider
    let accentColor: Color
    let onAction: (TrackingAction) -> Void

    private var step: Double {
        provider.displayInfo.step ?? 1.0
    }

    private var isComplete: Bool {
        provider.isComplete(progress: progress)
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(provider.displayInfo.progressLabel(progress))
                .font(.system(.caption, design: .monospaced, weight: .semibold))
                .foregroundStyle(isComplete ? accentColor : .primary)

            Button {
                HapticManager.shared.light()
                onAction(.decrement(step: step))
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .disabled(progress <= 0)

            Button {
                HapticManager.shared.medium()
                onAction(.increment(step: step))
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(accentColor)
            }
            .buttonStyle(.plain)
        }
    }
}
