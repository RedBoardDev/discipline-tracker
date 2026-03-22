import Foundation

/// Top-level application errors.
enum AppError: LocalizedError, Sendable {
    case configuration(ConfigurationError)
    case persistence(Error)

    var errorDescription: String? {
        switch self {
        case .configuration(let error):
            error.localizedDescription
        case .persistence(let error):
            "Persistence error: \(error.localizedDescription)"
        }
    }
}
