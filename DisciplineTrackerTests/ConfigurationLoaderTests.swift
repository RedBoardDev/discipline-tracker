import Testing
import Foundation
@testable import DisciplineTracker

@Suite("Configuration Loader Tests")
struct ConfigurationLoaderTests {

    // MARK: - Fixtures

    private static let validJSON: Data = Data("""
    {
        "objectives": [
            {
                "id": "meditation",
                "title": "Meditation",
                "icon": "brain.head.profile",
                "accent": "purple",
                "displayOrder": 0,
                "tracking": { "mode": "binary" }
            },
            {
                "id": "water",
                "title": "Water",
                "icon": "drop.fill",
                "accent": "blue",
                "displayOrder": 1,
                "tracking": { "mode": "counter", "target": 2.0, "step": 0.5, "unit": "L" }
            },
            {
                "id": "english",
                "title": "English",
                "icon": "book.fill",
                "accent": "green",
                "displayOrder": 2,
                "tracking": { "mode": "timer", "targetSeconds": 3600 },
                "activeDays": ["mon", "tue", "wed", "thu", "fri"]
            }
        ],
        "notifications": {
            "enabled": true,
            "defaultHour": 19,
            "defaultMinute": 30
        }
    }
    """.utf8)

    private static let duplicateIdsJSON: Data = Data("""
    {
        "objectives": [
            {
                "id": "duplicate",
                "title": "First",
                "icon": "star",
                "accent": "blue",
                "displayOrder": 0,
                "tracking": { "mode": "binary" }
            },
            {
                "id": "duplicate",
                "title": "Second",
                "icon": "star",
                "accent": "green",
                "displayOrder": 1,
                "tracking": { "mode": "binary" }
            }
        ],
        "notifications": { "enabled": false, "defaultHour": 8, "defaultMinute": 0 }
    }
    """.utf8)

    // MARK: - Tests

    @Test("decodes valid configuration from fixture")
    func decodeValidConfiguration() throws {
        let loader = ConfigurationLoader()
        let config = try loader.decode(Self.validJSON)

        #expect(config.objectives.count == 3)
        #expect(config.notifications.enabled == true)
        #expect(config.notifications.defaultHour == 19)
        #expect(config.notifications.defaultMinute == 30)
    }

    @Test("all objectives have unique IDs")
    func uniqueObjectiveIds() throws {
        let loader = ConfigurationLoader()
        let config = try loader.decode(Self.validJSON)

        let ids = config.objectives.map(\.id)
        let uniqueIds = Set(ids)
        #expect(ids.count == uniqueIds.count)
    }

    @Test("duplicate IDs throw an error")
    func duplicateIdThrows() throws {
        let loader = ConfigurationLoader()
        #expect(throws: ConfigurationError.self) {
            try loader.decode(Self.duplicateIdsJSON)
        }
    }

    @Test("active days are correctly parsed")
    func objectiveActiveDays() throws {
        let loader = ConfigurationLoader()
        let config = try loader.decode(Self.validJSON)

        let english = config.objectives.first { $0.id == "english" }
        #expect(english != nil)
        #expect(english?.activeDays.contains(.mon) == true)
        #expect(english?.activeDays.contains(.sat) == false)
    }

    @Test("timer objective has correct tracking mode and target")
    func timerObjectiveTracking() throws {
        let loader = ConfigurationLoader()
        let config = try loader.decode(Self.validJSON)

        let english = config.objectives.first { $0.id == "english" }
        #expect(english?.tracking.mode == TimerTrackingProvider.mode)
        #expect(english?.tracking.displayInfo.target == 3600)
    }

    @Test("counter objective has correct tracking mode, target, step and unit")
    func counterObjectiveTracking() throws {
        let loader = ConfigurationLoader()
        let config = try loader.decode(Self.validJSON)

        let water = config.objectives.first { $0.id == "water" }
        #expect(water?.tracking.mode == CounterTrackingProvider.mode)
        #expect(water?.tracking.displayInfo.target == 2.0)
        #expect(water?.tracking.displayInfo.step == 0.5)
        #expect(water?.tracking.displayInfo.unit == "L")
    }

    @Test("decoding invalid JSON throws decodingFailed")
    func invalidJSONThrowsDecodingError() throws {
        let loader = ConfigurationLoader()
        let badData = Data("not valid json".utf8)

        #expect(throws: ConfigurationError.self) {
            try loader.decode(badData)
        }
    }
}
