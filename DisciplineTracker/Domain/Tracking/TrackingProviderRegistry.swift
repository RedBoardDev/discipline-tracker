import Foundation

/// Injected into `JSONDecoder.userInfo` so that `ObjectiveDefinition` can decode
/// the `tracking` field into the correct `AnyTrackingProvider`.
/// All registrations must be provided at init time — the registry is immutable after construction.
final class TrackingProviderRegistry: Sendable {
    static let userInfoKey = CodingUserInfoKey(rawValue: "trackingProviderRegistry")!

    private let registrations: [String: @Sendable (Decoder) throws -> AnyTrackingProvider]

    init(registrations: [String: @Sendable (Decoder) throws -> AnyTrackingProvider] = [:]) {
        self.registrations = registrations
    }

    func registering<P: TrackingProvider>(_ type: P.Type) -> TrackingProviderRegistry {
        var updated = registrations
        updated[P.mode] = { decoder in
            let config = try P.Configuration(from: decoder)
            return AnyTrackingProvider(P(configuration: config))
        }
        return TrackingProviderRegistry(registrations: updated)
    }

    func decode(from decoder: Decoder) throws -> AnyTrackingProvider {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        let mode = try container.decode(String.self, forKey: AnyCodingKey(stringValue: "mode"))

        guard let factory = registrations[mode] else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Unknown tracking mode: '\(mode)'. Registered modes: \(registrations.keys.sorted())"
                )
            )
        }

        return try factory(decoder)
    }
}

struct AnyCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int?

    init(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}
