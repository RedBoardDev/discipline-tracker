import Foundation

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

final class WidgetDataProvider {
    private init() {}

    nonisolated(unsafe) private static let sharedDefaults = UserDefaults(suiteName: "group.com.discipline.tracker")!
    private static let dataKey = "widgetData"

    static func save(_ data: WidgetDayData) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        guard let encoded = try? encoder.encode(data) else { return }
        sharedDefaults.set(encoded, forKey: dataKey)
    }

    static func load() -> WidgetDayData? {
        guard let data = sharedDefaults.data(forKey: dataKey) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return try? decoder.decode(WidgetDayData.self, from: data)
    }
}
