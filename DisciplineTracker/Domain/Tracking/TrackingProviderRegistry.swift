import Foundation

/// Registry that maps tracking mode strings to their provider factories.
///
/// Injected into `JSONDecoder.userInfo` so that `ObjectiveDefinition` can decode
/// the `tracking` field into the correct `AnyTrackingProvider`.
final class TrackingProviderRegistry: @unchecked Sendable {
    static let userInfoKey = CodingUserInfoKey(rawValue: "trackingProviderRegistry")!

    private var registrations: [String: @Sendable (Decoder) throws -> AnyTrackingProvider] = [:]

    /// Registers a tracking provider type for a given mode string.
    func register<P: TrackingProvider>(_ type: P.Type) {
        registrations[P.mode] = { decoder in
            let config = try P.Configuration(from: decoder)
            return AnyTrackingProvider(P(configuration: config))
        }
    }

    /// Decodes an `AnyTrackingProvider` from the given decoder, using the "mode" field
    /// to look up the correct provider factory.
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

/// A flexible coding key that accepts any string value.
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
