import Foundation

/// Provides localized motivational messages for notifications.
enum NotificationMessages: Sendable {
    enum Register: String, Sendable {
        case lightPressure
        case almostDone
        case valorization
    }

    /// Returns a random localized motivational message based on the register.
    static func getMotivationalMessage(register: Register = .lightPressure, milestone: Int? = nil) -> String {
        let keys: [String]
        switch register {
        case .lightPressure:
            keys = (1...5).map { "notification.light.\($0)" }
        case .almostDone:
            keys = (1...5).map { "notification.almost.\($0)" }
        case .valorization:
            keys = (1...5).map { "notification.perfect.\($0)" }
        }
        let key = keys.randomElement() ?? keys[0]
        return NSLocalizedString(key, bundle: .main, comment: "")
    }
}
