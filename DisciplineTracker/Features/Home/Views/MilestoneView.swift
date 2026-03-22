import SwiftUI

struct MilestoneView: View {
    let streakCount: Int
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text(milestoneEmoji)
                .font(.system(size: 48))

            Text("milestone.days \(streakCount)")
                .font(.title2)
                .bold()

            Text(milestoneMessageKey)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .glassEffect(.regular.tint(.orange), in: .rect(cornerRadius: 24))
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Milestone Check

    static func isMilestone(_ count: Int) -> Bool {
        milestoneValues.contains(count)
    }

    // MARK: - Private

    private static let milestoneValues: Set<Int> = [7, 14, 21, 30, 50, 75, 100, 150, 200, 365]

    private var milestoneEmoji: String {
        switch streakCount {
        case 100...: "🏆"
        case 50...: "⭐"
        case 30...: "🔥"
        case 14...: "💪"
        default: "🎯"
        }
    }

    private var milestoneMessageKey: LocalizedStringKey {
        switch streakCount {
        case 100...: "milestone.message.100"
        case 50...: "milestone.message.50"
        case 30...: "milestone.message.30"
        case 14...: "milestone.message.14"
        default: "milestone.message.7"
        }
    }
}

// MARK: - Auto-dismiss modifier

extension View {
    /// No-op lifecycle hook — dismiss is handled by the parent view.
    func onAppearTrigger() -> some View {
        self
    }
}

// MARK: - Preview

#Preview {
    MilestoneView(streakCount: 30, onDismiss: {})
}
