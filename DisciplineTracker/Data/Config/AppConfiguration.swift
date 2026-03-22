import Foundation

/// Root configuration loaded from the JSON file.
struct AppConfiguration: Decodable, Sendable {
    let objectives: [ObjectiveDefinition]
    let notifications: NotificationConfiguration
}

/// Notification settings from the JSON configuration.
struct NotificationConfiguration: Codable, Sendable {
    let enabled: Bool
    let defaultHour: Int
    let defaultMinute: Int
}
