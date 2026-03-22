import SwiftUI

extension AccentColorName {
    /// Maps the configuration accent name to a SwiftUI Color.
    var color: Color {
        switch self {
        case .blue: .blue
        case .green: .green
        case .orange: .orange
        case .purple: .purple
        case .gray: .gray
        case .red: .red
        case .yellow: .yellow
        case .pink: .pink
        case .teal: .teal
        }
    }
}
