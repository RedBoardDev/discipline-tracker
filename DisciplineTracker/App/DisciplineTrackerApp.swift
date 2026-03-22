import SwiftUI
import SwiftData

@main
struct DisciplineTrackerApp: App {
    @AppStorage("app.language") private var languageCode: String = ""

    private var locale: Locale {
        languageCode.isEmpty ? .autoupdatingCurrent : Locale(identifier: languageCode)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.locale, locale)
        }
        .modelContainer(for: [
            DayRecordModel.self,
            ObjectiveDayStatusModel.self
        ])
    }
}
