import Foundation

extension Date {
    /// Returns the start of the day for this date using the current calendar.
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// Whether this date is today.
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// Returns a date string suitable for use as a dictionary key (yyyy-MM-dd).
    var dayKey: String {
        formatted(.iso8601.year().month().day().dateSeparator(.dash))
    }
}
