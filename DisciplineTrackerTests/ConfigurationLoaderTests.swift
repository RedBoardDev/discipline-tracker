import Testing
import Foundation
@testable import DisciplineTracker

@Suite("Configuration Loader Tests")
struct ConfigurationLoaderTests {

    @Test("loads valid configuration from bundle")
    func loadValidConfiguration() throws {
        let loader = ConfigurationLoader()
        let config = try loader.load()

        #expect(config.objectives.count == 5)
        #expect(config.notifications.enabled == true)
        #expect(config.notifications.defaultHour == 19)
        #expect(config.notifications.defaultMinute == 30)
    }

    @Test("all objectives have unique IDs")
    func uniqueObjectiveIds() throws {
        let loader = ConfigurationLoader()
        let config = try loader.load()

        let ids = config.objectives.map(\.id)
        let uniqueIds = Set(ids)
        #expect(ids.count == uniqueIds.count)
    }

    @Test("objective active days are correctly parsed")
    func objectiveActiveDays() throws {
        let loader = ConfigurationLoader()
        let config = try loader.load()

        let sport = config.objectives.first { $0.id == "sport" }
        #expect(sport != nil)
        #expect(sport?.activeDays.count == 4)
        #expect(sport?.activeDays.contains(.mon) == true)
        #expect(sport?.activeDays.contains(.tue) == false)
    }

    @Test("timer objective has correct tracking mode")
    func timerObjectiveTracking() throws {
        let loader = ConfigurationLoader()
        let config = try loader.load()

        let english = config.objectives.first { $0.id == "english" }
        #expect(english != nil)
        #expect(english?.tracking.mode == TimerTrackingProvider.mode)
        #expect(english?.tracking.displayInfo.target == 3600)
    }

    @Test("counter objective has correct tracking mode")
    func counterObjectiveTracking() throws {
        let loader = ConfigurationLoader()
        let config = try loader.load()

        let water = config.objectives.first { $0.id == "water" }
        #expect(water != nil)
        #expect(water?.tracking.mode == CounterTrackingProvider.mode)
        #expect(water?.tracking.displayInfo.target == 2.0)
        #expect(water?.tracking.displayInfo.step == 0.5)
        #expect(water?.tracking.displayInfo.unit == "L")
    }
}
