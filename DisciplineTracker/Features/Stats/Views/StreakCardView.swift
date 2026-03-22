import SwiftUI

struct StreakCardView: View {
    let value: String
    let label: LocalizedStringKey
    let icon: String
    let tint: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(tint)
                .accessibilityHidden(true)

            Text(verbatim: value)
                .font(.title)
                .bold()
                .foregroundStyle(tint)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(tint.opacity(0.1))
        .clipShape(.rect(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(label) + Text(verbatim: " : \(value)"))
    }
}

// MARK: - Preview

#Preview {
    HStack {
        StreakCardView(value: "12", label: "stats.current_streak", icon: "flame.fill", tint: .orange)
        StreakCardView(value: "24", label: "stats.best_streak", icon: "trophy.fill", tint: .yellow)
    }
    .padding()
}
