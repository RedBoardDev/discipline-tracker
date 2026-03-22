import Foundation

/// A day of the week, used for scheduling objectives.
enum Weekday: String, Codable, Sendable, CaseIterable {
    case mon, tue, wed, thu, fri, sat, sun

    /// Returns the corresponding Calendar weekday number (1 = Sunday, 2 = Monday, etc.).
    var calendarWeekday: Int {
        switch self {
        case .sun: 1
        case .mon: 2
        case .tue: 3
        case .wed: 4
        case .thu: 5
        case .fri: 6
        case .sat: 7
        }
    }
}

/// An accent color identifier mapped from the JSON config.
enum AccentColorName: String, Codable, Sendable {
    case blue, green, orange, purple, gray, red, yellow, pink, teal
}

/// Definition of an objective loaded from the JSON configuration file.
/// This is a pure domain entity — no SwiftData dependency.
struct ObjectiveDefinition: Identifiable, Sendable, Hashable {
    let id: String
    let title: String
    let icon: String
    let accent: AccentColorName
    let activeDays: [Weekday]
    let isEnabled: Bool
    let displayOrder: Int
    let tracking: AnyTrackingProvider

    /// Whether this objective is active on a given date.
    func isActive(on date: Date, calendar: Calendar = .current) -> Bool {
        guard isEnabled else { return false }
        let weekdayNumber = calendar.component(.weekday, from: date)
        return activeDays.contains { $0.calendarWeekday == weekdayNumber }
    }
}

// MARK: - Decodable

extension ObjectiveDefinition: Decodable {
    enum CodingKeys: String, CodingKey {
        case id, title, icon, accent, activeDays, isEnabled, displayOrder, tracking
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        icon = try container.decode(String.self, forKey: .icon)
        accent = try container.decode(AccentColorName.self, forKey: .accent)
        activeDays = try container.decode([Weekday].self, forKey: .activeDays)
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        displayOrder = try container.decode(Int.self, forKey: .displayOrder)

        guard let registry = decoder.userInfo[TrackingProviderRegistry.userInfoKey] as? TrackingProviderRegistry else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "TrackingProviderRegistry not found in decoder.userInfo"
                )
            )
        }

        let trackingDecoder = try container.superDecoder(forKey: .tracking)
        tracking = try registry.decode(from: trackingDecoder)
    }
}
