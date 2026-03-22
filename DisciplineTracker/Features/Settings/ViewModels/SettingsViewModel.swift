import Foundation
import UserNotifications

/// View model for the Settings screen.
/// Manages notification preferences and coordinates with `NotificationScheduler`.
@MainActor
@Observable
final class SettingsViewModel {

    // MARK: - Notification State

    /// Whether notifications are enabled by the user.
    var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: Keys.notificationsEnabled)
        }
    }

    /// The scheduled notification time, derived from hour and minute components.
    var notificationTime: Date {
        get {
            var components = DateComponents()
            components.hour = notificationHour
            components.minute = notificationMinute
            return Calendar.current.date(from: components) ?? .now
        }
        set {
            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            notificationHour = components.hour ?? 20
            notificationMinute = components.minute ?? 0
            UserDefaults.standard.set(notificationHour, forKey: Keys.notificationHour)
            UserDefaults.standard.set(notificationMinute, forKey: Keys.notificationMinute)
        }
    }

    /// The hour component for notifications.
    private(set) var notificationHour: Int

    /// The minute component for notifications.
    private(set) var notificationMinute: Int

    // MARK: - Permission State

    /// Whether the system has granted notification permission.
    private(set) var notificationPermissionGranted: Bool = false

    // MARK: - Dependencies

    private let scheduler: NotificationScheduler

    // MARK: - Init

    init(
        scheduler: NotificationScheduler = NotificationScheduler(),
        defaultHour: Int = 20,
        defaultMinute: Int = 0
    ) {
        self.scheduler = scheduler

        let defaults = UserDefaults.standard

        // Load persisted preferences, falling back to provided defaults
        if defaults.object(forKey: Keys.notificationsEnabled) != nil {
            self.notificationsEnabled = defaults.bool(forKey: Keys.notificationsEnabled)
        } else {
            self.notificationsEnabled = true
        }

        if defaults.object(forKey: Keys.notificationHour) != nil {
            self.notificationHour = defaults.integer(forKey: Keys.notificationHour)
        } else {
            self.notificationHour = defaultHour
        }

        if defaults.object(forKey: Keys.notificationMinute) != nil {
            self.notificationMinute = defaults.integer(forKey: Keys.notificationMinute)
        } else {
            self.notificationMinute = defaultMinute
        }
    }

    // MARK: - Notification Permission

    /// Requests notification authorization from the system.
    func requestNotificationPermission() async {
        do {
            let granted = try await scheduler.requestAuthorization()
            notificationPermissionGranted = granted
        } catch {
            notificationPermissionGranted = false
        }
    }

    /// Checks the current notification authorization status.
    func checkNotificationPermission() async {
        notificationPermissionGranted = await scheduler.isAuthorized()
    }

    // MARK: - Schedule Management

    /// Updates the notification schedule based on the current day state.
    func updateNotificationSchedule(
        dayState: DayCompletionState,
        completedCount: Int,
        totalCount: Int,
        currentStreak: Int
    ) async {
        guard notificationsEnabled else {
            await scheduler.cancelAll()
            return
        }

        await scheduler.scheduleDailyReminder(
            hour: notificationHour,
            minute: notificationMinute,
            completedCount: completedCount,
            totalCount: totalCount,
            currentStreak: currentStreak,
            dayState: dayState
        )
    }
}

// MARK: - UserDefaults Keys

private extension SettingsViewModel {
    enum Keys {
        static let notificationsEnabled = "notifications.enabled"
        static let notificationHour = "notifications.hour"
        static let notificationMinute = "notifications.minute"
    }
}
