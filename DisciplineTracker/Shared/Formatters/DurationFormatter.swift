import Foundation

/// Formats durations in seconds into human-readable strings.
enum DurationFormatter {
    /// Formats seconds into a compact time string.
    ///
    /// Examples:
    /// - 2700 → "45:00"
    /// - 3600 → "1:00:00"
    /// - 5400 → "1:30:00"
    /// - 90 → "1:30"
    /// - 0 → "0:00"
    static func format(_ seconds: Double) -> String {
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%d:%02d", minutes, secs)
    }

    /// Formats seconds into a compact label (e.g., "45min", "1h30", "2h").
    static func formatCompact(_ seconds: Double) -> String {
        let totalMinutes = Int(seconds) / 60
        if totalMinutes >= 60 {
            let hours = totalMinutes / 60
            let remainingMinutes = totalMinutes % 60
            if remainingMinutes == 0 {
                return "\(hours)h"
            }
            return "\(hours)h\(String(format: "%02d", remainingMinutes))"
        }
        return "\(totalMinutes)min"
    }
}
