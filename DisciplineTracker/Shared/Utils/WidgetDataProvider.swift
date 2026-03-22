import Foundation
import WidgetKit

/// Shared data structure for widget communication via App Groups.
struct WidgetDayData: Codable, Sendable {
    let date: Date
    let currentStreak: Int
    let completedCount: Int
    let totalCount: Int
    let objectives: [WidgetObjectiveData]
}

struct WidgetObjectiveData: Codable, Identifiable, Sendable {
    let id: String
    let title: String
    let icon: String
    let accentColorName: String
    let isCompleted: Bool
    let isManual: Bool
    let progress: Double
    let trackingMode: String
}

/// Manages widget data persistence in App Group UserDefaults.
final class WidgetDataProvider {
    nonisolated(unsafe) private static let sharedDefaults = UserDefaults(suiteName: "group.com.discipline.tracker")!

    init() {}
    private static let objectivesKey = "widget_objectives"
    private static let streakKey = "widget_streak"
    private static let completedKey = "widget_completed"
    private static let totalCountKey = "widget_total"
    private static let dateKey = "widget_date"

    static func save(_ data: WidgetDayData) {
        var container: [String: Any] = [:]
        container[dateKey] = data.date.timeIntervalSince1970
        container[streakKey] = data.currentStreak
        container[completedKey] = data.completedCount
        container[totalCountKey] = data.totalCount
        container[objectivesKey] = data.objectives.map { objective in
            [
                "id": objective.id,
                "title": objective.title,
                "icon": objective.icon,
                "accentColorName": objective.accentColorName,
                "isCompleted": objective.isCompleted,
                "isManual": objective.isManual,
                "progress": objective.progress,
                "trackingMode": objective.trackingMode
            ] as [String: Any]
        }
        sharedDefaults.set(container, forKey: "widgetData")
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func load() -> WidgetDayData? {
        guard let container = sharedDefaults.dictionary(forKey: "widgetData"),
              let timestamp = container[dateKey] as? TimeInterval,
              let objectivesRaw = container[objectivesKey] as? [[String: Any]] else {
            return nil
        }

        let date = Date(timeIntervalSince1970: timestamp)
        let objectives = objectivesRaw.compactMap { dict -> WidgetObjectiveData? in
            guard let id = dict["id"] as? String,
                  let title = dict["title"] as? String,
                  let icon = dict["icon"] as? String,
                  let accentName = dict["accentColorName"] as? String,
                  let isCompleted = dict["isCompleted"] as? Bool,
                  let isManual = dict["isManual"] as? Bool else {
                return nil
            }
            return WidgetObjectiveData(
                id: id,
                title: title,
                icon: icon,
                accentColorName: accentName,
                isCompleted: isCompleted,
                isManual: isManual,
                progress: dict["progress"] as? Double ?? 0.0,
                trackingMode: dict["trackingMode"] as? String ?? "binary"
            )
        }

        return WidgetDayData(
            date: date,
            currentStreak: (container[streakKey] as? Int) ?? 0,
            completedCount: (container[completedKey] as? Int) ?? 0,
            totalCount: (container[totalCountKey] as? Int) ?? 0,
            objectives: objectives
        )
    }
}
