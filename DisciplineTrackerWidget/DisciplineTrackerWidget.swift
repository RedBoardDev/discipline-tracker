import WidgetKit
import SwiftUI

// MARK: - Timeline

struct DisciplineEntry: TimelineEntry {
    let date: Date
    let dayData: WidgetDayData?
}

struct DisciplineTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> DisciplineEntry {
        DisciplineEntry(date: .now, dayData: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (DisciplineEntry) -> Void) {
        completion(DisciplineEntry(date: .now, dayData: WidgetDataProvider.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DisciplineEntry>) -> Void) {
        let entry = DisciplineEntry(date: .now, dayData: WidgetDataProvider.load())
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

// MARK: - Root View

struct DisciplineWidgetView: View {
    let entry: DisciplineEntry

    var body: some View {
        if let data = entry.dayData {
            SmallWidgetView(data: data)
        } else {
            EmptyWidgetView()
        }
    }
}

// MARK: - Small Widget

private struct SmallWidgetView: View {
    let data: WidgetDayData

    private var progress: Double {
        guard data.totalCount > 0 else { return 0 }
        return Double(data.completedCount) / Double(data.totalCount)
    }

    private var isPerfect: Bool {
        data.totalCount > 0 && data.completedCount == data.totalCount
    }

    private var progressColor: Color {
        if isPerfect { return .green }
        if data.completedCount > 0 { return .orange }
        return .gray.opacity(0.4)
    }

    var body: some View {
        VStack(spacing: 10) {
            Spacer(minLength: 0)

            ProgressRing(
                completed: data.completedCount,
                total: data.totalCount,
                progress: progress,
                color: progressColor,
                isPerfect: isPerfect
            )

            StreakBadge(streak: data.currentStreak)

            Spacer(minLength: 0)
        }
        .padding(14)
    }
}

// MARK: - Streak Badge

private struct StreakBadge: View {
    let streak: Int

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "flame.fill")
                .font(.caption2)
                .foregroundStyle(.orange)
            Text("\(streak)")
                .font(.system(.caption, design: .rounded, weight: .bold))
            Text("widget.streak_label")
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Progress Ring

private struct ProgressRing: View {
    let completed: Int
    let total: Int
    let progress: Double
    let color: Color
    let isPerfect: Bool

    private let lineWidth: CGFloat = 7
    private let size: CGFloat = 84

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: min(progress, 1))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))

            centerLabel
        }
        .frame(width: size, height: size)
    }

    @ViewBuilder
    private var centerLabel: some View {
        if isPerfect {
            Image(systemName: "checkmark")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(.green)
        } else {
            VStack(spacing: -2) {
                Text("\(completed)")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(color)
                Text("/\(total)")
                    .font(.system(.caption2, design: .rounded, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Empty State

private struct EmptyWidgetView: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "flame")
                .font(.title2)
                .foregroundStyle(.orange.opacity(0.5))
            Text("widget.open_app")
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Widget

@main
struct DisciplineTrackerWidget: Widget {
    let kind = "DisciplineTrackerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DisciplineTimelineProvider()) { entry in
            DisciplineWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("widget.config.name")
        .description("widget.config.description")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    DisciplineTrackerWidget()
} timeline: {
    DisciplineEntry(date: .now, dayData: WidgetDayData(
        date: .now,
        currentStreak: 12,
        completedCount: 3,
        totalCount: 5,
        objectives: []
    ))
    DisciplineEntry(date: .now, dayData: WidgetDayData(
        date: .now,
        currentStreak: 7,
        completedCount: 5,
        totalCount: 5,
        objectives: []
    ))
    DisciplineEntry(date: .now, dayData: WidgetDayData(
        date: .now,
        currentStreak: 0,
        completedCount: 0,
        totalCount: 5,
        objectives: []
    ))
}
