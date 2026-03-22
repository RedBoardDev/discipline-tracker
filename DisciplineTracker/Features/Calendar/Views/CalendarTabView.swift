import SwiftUI
import SwiftData

/// Monthly calendar view showing daily completion states with color-coded cells.
struct CalendarTabView: View {
    @Environment(DayStateService.self) private var dayStateService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locale) private var locale

    @State private var viewModel = CalendarViewModel()
    @State private var selectedDate: Date?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    MonthNavigationView(
                        title: viewModel.monthTitle(locale: locale),
                        canGoForward: viewModel.canGoForward,
                        onPrevious: {
                            viewModel.goPreviousMonth(context: modelContext)
                        },
                        onNext: {
                            viewModel.goToNextMonth(context: modelContext)
                        }
                    )

                    WeekdayHeaderRow()

                    CalendarGridView(
                        days: viewModel.daysInMonth,
                        firstWeekdayOffset: viewModel.firstWeekdayOffset,
                        dayStates: viewModel.dayStates,
                        onDayTapped: { date in
                            selectedDate = date
                        }
                    )
                }
                .padding(.horizontal)
            }
            .scrollIndicators(.hidden)
            .navigationTitle("tab.calendar")
            .task {
                viewModel.loadMonth(context: modelContext)
            }
            .sheet(item: $selectedDate) { date in
                DayDetailView(
                    date: date,
                    objectives: dayStateService.configuration?.objectives ?? [],
                    onAction: { objectiveId, action in
                        viewModel.updateProgress(
                            objectiveId: objectiveId,
                            action: action,
                            date: date,
                            dayStateService: dayStateService,
                            context: modelContext
                        )
                    }
                )
                .presentationDetents([.medium, .large])
            }
        }
    }
}

// MARK: - Date Identifiable Conformance

extension Date: @retroactive Identifiable {
    public var id: TimeInterval { timeIntervalSince1970 }
}

// MARK: - Month Navigation

/// Header with previous/next month buttons and month title.
private struct MonthNavigationView: View {
    let title: String
    let canGoForward: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack {
            Button("calendar.previous_month", systemImage: "chevron.left", action: onPrevious)
                .labelStyle(.iconOnly)

            Spacer()

            Text(verbatim: title)
                .font(.title3)
                .bold()

            Spacer()

            Button("calendar.next_month", systemImage: "chevron.right", action: onNext)
                .labelStyle(.iconOnly)
                .disabled(!canGoForward)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Weekday Header

/// Row of weekday abbreviations (Mon, Tue, etc.) in the current locale.
private struct WeekdayHeaderRow: View {
    @Environment(\.locale) private var locale

    private var weekdaySymbols: [String] {
        let calendar = Calendar.current
        let knownMonday = calendar.date(from: DateComponents(year: 2025, month: 1, day: 6))!
        return (0..<7).map { offset in
            let day = calendar.date(byAdding: .day, value: offset, to: knownMonday)!
            return day.formatted(.dateTime.weekday(.abbreviated).locale(locale)).capitalized
        }
    }

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(verbatim: symbol)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Calendar Grid

/// The 7-column grid of day cells for the current month.
private struct CalendarGridView: View {
    let days: [Date]
    let firstWeekdayOffset: Int
    let dayStates: [Date: DayCompletionState]
    let onDayTapped: (Date) -> Void

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            ForEach(0..<firstWeekdayOffset, id: \.self) { _ in
                Color.clear
                    .frame(height: 40)
            }

            ForEach(days, id: \.timeIntervalSince1970) { date in
                CalendarDayCellView(
                    date: date,
                    state: dayStates[Calendar.current.startOfDay(for: date)] ?? .empty,
                    isToday: date.isToday,
                    isFuture: date > .now,
                    onTap: { onDayTapped(date) }
                )
            }
        }
    }
}

// MARK: - Day Cell

/// A single day cell in the calendar grid, colored by completion state.
private struct CalendarDayCellView: View {
    let date: Date
    let state: DayCompletionState
    let isToday: Bool
    let isFuture: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(dayNumber)
                .font(.callout)
                .bold(isToday)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .foregroundStyle(textColor)
                .background(backgroundColor, in: .rect(cornerRadius: 8))
                .overlay {
                    if isToday {
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(.primary, lineWidth: 1.5)
                    }
                }
        }
        .buttonStyle(.plain)
        .disabled(isFuture)
        .opacity(isFuture ? 0.3 : 1.0)
    }

    private var dayNumber: String {
        Calendar.current.component(.day, from: date)
            .formatted(.number)
    }

    private var backgroundColor: Color {
        guard !isFuture else { return .clear }
        switch state {
        case .perfect: return Color.green.opacity(0.3)
        case .partial: return Color.orange.opacity(0.3)
        case .empty: return Color(.systemGray6)
        }
    }

    private var textColor: Color {
        guard !isFuture else { return .secondary }
        switch state {
        case .perfect: return Color.green
        case .partial: return Color.orange
        case .empty: return Color.primary
        }
    }
}

#Preview {
    CalendarTabView()
        .environment(DayStateService())
        .modelContainer(for: [
            DayRecordModel.self,
            ObjectiveDayStatusModel.self
        ], inMemory: true)
}
