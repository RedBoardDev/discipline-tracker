import SwiftUI

struct HeatmapView: View {
    let data: [Date: DayCompletionState]

    private let columns = 13 // ~90 days / 7
    private let rows = 7

    var body: some View {
        let days = generateDays()

        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: columns),
            spacing: 3
        ) {
            ForEach(days, id: \.timeIntervalSince1970) { date in
                let state = data[Calendar.current.startOfDay(for: date)] ?? .empty
                RoundedRectangle(cornerRadius: 2)
                    .fill(colorFor(state: state, date: date))
                    .aspectRatio(1, contentMode: .fit)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(.rect(cornerRadius: 12))
    }

    // MARK: - Private

    private func generateDays() -> [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let totalDays = columns * rows

        return (0..<totalDays).compactMap { offset in
            calendar.date(byAdding: .day, value: -(totalDays - 1 - offset), to: today)
        }
    }

    private func colorFor(state: DayCompletionState, date: Date) -> Color {
        guard date <= .now else { return Color(.systemGray5) }
        switch state {
        case .perfect: return .green
        case .partial: return .orange.opacity(0.6)
        case .empty: return Color(.systemGray5)
        }
    }
}

// MARK: - Preview

#Preview {
    HeatmapView(data: [:])
        .padding()
}
