import Foundation
import UserNotifications

@MainActor
final class NotificationScheduler: Sendable {
    func requestAuthorization() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        try await center.requestAuthorization(options: [.alert, .sound, .badge])
        let settings = await center.notificationSettings()
        return settings.authorizationStatus == .authorized
    }

    func scheduleDailyReminder(
        hour: Int,
        minute: Int,
        completedCount: Int,
        totalCount: Int,
        currentStreak: Int,
        dayState: DayCompletionState
    ) async {
        let center = UNUserNotificationCenter.current()

        // Remove previous daily reminder
        center.removePendingNotificationRequests(withIdentifiers: ["daily_reminder"])

        let content = UNMutableNotificationContent()
        content.title = "Discipline"
        content.body = contextualMessage(
            dayState: dayState,
            completedCount: completedCount,
            totalCount: totalCount
        )
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_reminder", content: content, trigger: trigger)

        try? await center.add(request)
    }

    func cancelAll() async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
    }

    func isAuthorized() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        return settings.authorizationStatus == .authorized
    }

    private func contextualMessage(
        dayState: DayCompletionState,
        completedCount: Int,
        totalCount: Int
    ) -> String {
        switch dayState {
        case .perfect:
            return NotificationMessages.getMotivationalMessage(register: .valorization)
        case .partial:
            return NotificationMessages.getMotivationalMessage(register: .almostDone)
        case .empty:
            return NotificationMessages.getMotivationalMessage(register: .lightPressure)
        }
    }
}
