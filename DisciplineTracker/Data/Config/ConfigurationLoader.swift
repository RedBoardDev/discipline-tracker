import Foundation

/// Errors that can occur when loading the JSON configuration.
enum ConfigurationError: LocalizedError, Sendable {
    case fileNotFound
    case decodingFailed(Error)
    case duplicateObjectiveIds([String])

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            "Configuration file 'objectives.json' not found in bundle."
        case .decodingFailed(let error):
            "Failed to decode configuration: \(error.localizedDescription)"
        case .duplicateObjectiveIds(let ids):
            "Duplicate objective IDs found: \(ids.joined(separator: ", "))"
        }
    }
}

/// Loads and validates the app configuration from the bundled JSON file.
struct ConfigurationLoader: Sendable {
    private let registry: TrackingProviderRegistry

    init(registry: TrackingProviderRegistry = TrackingSetup.createRegistry()) {
        self.registry = registry
    }

    /// Loads the configuration from the app bundle.
    /// - Returns: A validated `AppConfiguration`.
    /// - Throws: `ConfigurationError` if loading or validation fails.
    func load() throws -> AppConfiguration {
        guard let url = Bundle.main.url(forResource: "objectives", withExtension: "json") else {
            throw ConfigurationError.fileNotFound
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw ConfigurationError.fileNotFound
        }

        let configuration: AppConfiguration
        do {
            let decoder = JSONDecoder()
            decoder.userInfo[TrackingProviderRegistry.userInfoKey] = registry
            configuration = try decoder.decode(AppConfiguration.self, from: data)
        } catch {
            throw ConfigurationError.decodingFailed(error)
        }

        try validate(configuration)
        return configuration
    }

    // MARK: - Validation

    private func validate(_ configuration: AppConfiguration) throws {
        let ids = configuration.objectives.map(\.id)
        let duplicates = Dictionary(grouping: ids, by: { $0 })
            .filter { $0.value.count > 1 }
            .map(\.key)

        if !duplicates.isEmpty {
            throw ConfigurationError.duplicateObjectiveIds(duplicates)
        }
    }
}
