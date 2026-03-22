import SwiftUI

/// Settings screen for notifications and language preferences.
struct SettingsView: View {
    @Environment(DayStateService.self) private var dayStateService
    @State private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationStack {
            Form {
                NotificationSection(
                    viewModel: viewModel,
                    dayStateService: dayStateService
                )
                LanguageSection()
                AppInfoSection(dayStateService: dayStateService, viewModel: viewModel)
            }
            .navigationTitle("tab.settings")
            .task {
                initializeFromConfiguration()
                await viewModel.checkNotificationPermission()
                await updateSchedule()
            }
        }
    }

    private func initializeFromConfiguration() {
        guard let config = dayStateService.configuration else { return }
        let defaults = UserDefaults.standard

        if defaults.object(forKey: "notifications.enabled") == nil {
            viewModel.notificationsEnabled = config.notifications.enabled
        }
        if defaults.object(forKey: "notifications.hour") == nil {
            var components = DateComponents()
            components.hour = config.notifications.defaultHour
            components.minute = config.notifications.defaultMinute
            if let date = Calendar.current.date(from: components) {
                viewModel.notificationTime = date
            }
        }
    }

    private func updateSchedule() async {
        await viewModel.updateNotificationSchedule(
            dayState: dayStateService.dayCompletionState,
            completedCount: dayStateService.completedCount,
            totalCount: dayStateService.totalCount,
            currentStreak: dayStateService.streakSnapshot.currentPerfectDayStreak
        )
    }
}

// MARK: - Notification Section

private struct NotificationSection: View {
    @Bindable var viewModel: SettingsViewModel
    let dayStateService: DayStateService

    var body: some View {
        Section {
            Toggle("settings.enable_notifications", isOn: $viewModel.notificationsEnabled)
                .onChange(of: viewModel.notificationsEnabled) { _, isEnabled in
                    Task {
                        if isEnabled {
                            await viewModel.requestNotificationPermission()
                        }
                        await viewModel.updateNotificationSchedule(
                            dayState: dayStateService.dayCompletionState,
                            completedCount: dayStateService.completedCount,
                            totalCount: dayStateService.totalCount,
                            currentStreak: dayStateService.streakSnapshot.currentPerfectDayStreak
                        )
                    }
                }

            if viewModel.notificationsEnabled {
                DatePicker(
                    "settings.notification_time",
                    selection: $viewModel.notificationTime,
                    displayedComponents: .hourAndMinute
                )
                .onChange(of: viewModel.notificationTime) { _, _ in
                    Task {
                        await viewModel.updateNotificationSchedule(
                            dayState: dayStateService.dayCompletionState,
                            completedCount: dayStateService.completedCount,
                            totalCount: dayStateService.totalCount,
                            currentStreak: dayStateService.streakSnapshot.currentPerfectDayStreak
                        )
                    }
                }

                if !viewModel.notificationPermissionGranted {
                    PermissionWarningView {
                        Task {
                            await viewModel.requestNotificationPermission()
                        }
                    }
                }
            }
        } header: {
            Text("settings.section.notifications")
        } footer: {
            Text("settings.notifications_footer")
        }
    }
}

// MARK: - Permission Warning

private struct PermissionWarningView: View {
    let onRequestPermission: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(.orange)
            Text("settings.notifications_unauthorized")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button("settings.authorize", action: onRequestPermission)
                .font(.caption)
                .bold()
        }
    }
}

// MARK: - Language Section

private struct LanguageSection: View {
    @AppStorage("app.language") private var languageCode: String = ""

    var body: some View {
        Section {
            Picker(selection: $languageCode) {
                Text("settings.language.system").tag("")
                Text(verbatim: "Français").tag("fr")
                Text(verbatim: "English").tag("en")
                Text(verbatim: "Suomi").tag("fi")
            } label: {
                Text("settings.section.language")
            }
            .pickerStyle(.menu)
        } header: {
            Text("settings.section.language")
        }
    }
}

// MARK: - App Info Section

private struct AppInfoSection: View {
    let dayStateService: DayStateService
    let viewModel: SettingsViewModel

    var body: some View {
        Section {
            HStack {
                Text("settings.version")
                Spacer()
                Text(verbatim: appVersion)
                    .foregroundStyle(.secondary)
            }

            Button("settings.refresh_data", systemImage: "arrow.clockwise") {
                // Debug action — triggers a state refresh if needed.
            }
        } header: {
            Text("settings.section.app")
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environment(DayStateService())
}
