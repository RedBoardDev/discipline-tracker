import Testing
import Foundation
@testable import DisciplineTracker

@Suite("Objective Definition Tests")
struct ObjectiveDefinitionTests {

    private let objective = ObjectiveDefinition(
        id: "test",
        title: "Test Objective",
        icon: "star",
        accent: .blue,
        activeDays: [.mon, .wed, .fri],
        isEnabled: true,
        displayOrder: 1,
        tracking: AnyTrackingProvider(BinaryTrackingProvider())
    )

    @Test("objective is active on scheduled days")
    func activeOnScheduledDay() {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        let monday = calendar.date(from: DateComponents(year: 2026, month: 3, day: 16))!

        #expect(objective.isActive(on: monday, calendar: calendar) == true)
    }

    @Test("objective is inactive on non-scheduled days")
    func inactiveOnNonScheduledDay() {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        let tuesday = calendar.date(from: DateComponents(year: 2026, month: 3, day: 17))!

        #expect(objective.isActive(on: tuesday, calendar: calendar) == false)
    }

    @Test("disabled objective is never active")
    func disabledObjectiveNeverActive() {
        let disabled = ObjectiveDefinition(
            id: "disabled",
            title: "Disabled",
            icon: "star",
            accent: .gray,
            activeDays: [.mon, .tue, .wed, .thu, .fri, .sat, .sun],
            isEnabled: false,
            displayOrder: 1,
            tracking: AnyTrackingProvider(BinaryTrackingProvider())
        )

        var calendar = Calendar.current
        calendar.firstWeekday = 2
        let monday = calendar.date(from: DateComponents(year: 2026, month: 3, day: 16))!

        #expect(disabled.isActive(on: monday, calendar: calendar) == false)
    }

    @Test("weekday calendar mapping is correct")
    func weekdayMapping() {
        #expect(Weekday.sun.calendarWeekday == 1)
        #expect(Weekday.mon.calendarWeekday == 2)
        #expect(Weekday.sat.calendarWeekday == 7)
    }
}
