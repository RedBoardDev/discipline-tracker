import SwiftUI

struct StreakHeaderView: View {
    let currentStreak: Int
    let dayState: DayCompletionState
    let completedCount: Int
    let totalCount: Int
    let perfectDaysThisMonth: Int

    @Namespace private var streakNamespace
    @State private var showMilestone = false

    var body: some View {
        VStack(spacing: 8) {
            StreakCountView(
                currentStreak: currentStreak,
                namespace: streakNamespace,
                isMilestone: showMilestone
            )

            MotivationalMessageView(
                message: motivationalMessage,
                dayState: dayState
            )

            SecondaryStatLineView(
                dayState: dayState,
                remaining: totalCount - completedCount,
                perfectDaysThisMonth: perfectDaysThisMonth
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical)
        .onChange(of: currentStreak) {
            if MilestoneView.isMilestone(currentStreak) {
                showMilestone = true
            }
        }
        .overlay(alignment: .top) {
            if showMilestone {
                MilestoneView(
                    streakCount: currentStreak,
                    onDismiss: { showMilestone = false }
                )
                .onAppearTrigger()
            }
        }
    }

    // MARK: - Computed

    private var motivationalMessage: LocalizedStringKey {
        let category: String
        switch currentStreak {
        case 0: category = "zero"
        case 1...3: category = "building"
        case 4...6: category = "going"
        default: category = "strong"
        }
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: .now) ?? 0
        let index = (dayOfYear % 4) + 1
        return LocalizedStringKey("motivational.\(category).\(index)")
    }
}

// MARK: - Sub-views

private struct StreakCountView: View {
    let currentStreak: Int
    let namespace: Namespace.ID
    let isMilestone: Bool

    var body: some View {
        VStack(spacing: 2) {
            Text(currentStreak, format: .number)
                .font(.system(.largeTitle, design: .rounded))
                .bold()
                .contentTransition(.numericText())

            Text("streak.consecutive_days")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .glassEffect(
            isMilestone
                ? .regular.tint(.orange)
                : .regular,
            in: .rect(cornerRadius: 16)
        )
        .glassEffectID("streakCount", in: namespace)
    }
}

private struct MotivationalMessageView: View {
    let message: LocalizedStringKey
    let dayState: DayCompletionState

    var body: some View {
        Text(message)
            .font(.callout)
            .foregroundStyle(messageColor)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
    }

    private var messageColor: Color {
        switch dayState {
        case .perfect: .green
        case .partial: .orange
        case .empty: .secondary
        }
    }
}

private struct SecondaryStatLineView: View {
    let dayState: DayCompletionState
    let remaining: Int
    let perfectDaysThisMonth: Int

    var body: some View {
        Group {
            switch dayState {
            case .perfect:
                Text("streak.perfect_days_month \(perfectDaysThisMonth)")
            case .empty, .partial:
                Text("streak.remaining \(remaining)")
            }
        }
        .font(.footnote)
        .foregroundStyle(.tertiary)
    }
}

#Preview {
    StreakHeaderView(
        currentStreak: 5,
        dayState: .partial,
        completedCount: 2,
        totalCount: 4,
        perfectDaysThisMonth: 12
    )
}
