import Testing
import Foundation
@testable import DisciplineTracker

@Suite("Binary Tracking Provider Tests")
struct BinaryTrackingProviderTests {

    private let provider = BinaryTrackingProvider()

    @Test("isComplete returns true for progress >= 1.0")
    func isComplete() {
        #expect(provider.isComplete(progress: 1.0) == true)
        #expect(provider.isComplete(progress: 2.0) == true)
        #expect(provider.isComplete(progress: 0.0) == false)
        #expect(provider.isComplete(progress: 0.5) == false)
    }

    @Test("toggle action toggles between 0 and 1")
    func toggleAction() {
        #expect(provider.applyAction(.toggle, to: 0.0) == 1.0)
        #expect(provider.applyAction(.toggle, to: 1.0) == 0.0)
    }

    @Test("normalizedProgress is binary")
    func normalizedProgress() {
        #expect(provider.normalizedProgress(0.0) == 0.0)
        #expect(provider.normalizedProgress(0.5) == 0.0)
        #expect(provider.normalizedProgress(1.0) == 1.0)
    }
}

@Suite("Counter Tracking Provider Tests")
struct CounterTrackingProviderTests {

    private let provider = CounterTrackingProvider(
        configuration: .init(target: 2.0, step: 0.5, unit: "L")
    )

    @Test("isComplete returns true when progress reaches target")
    func isComplete() {
        #expect(provider.isComplete(progress: 2.0) == true)
        #expect(provider.isComplete(progress: 2.5) == true)
        #expect(provider.isComplete(progress: 1.5) == false)
        #expect(provider.isComplete(progress: 0.0) == false)
    }

    @Test("increment adds step to progress")
    func increment() {
        #expect(provider.applyAction(.increment(step: 0.5), to: 1.0) == 1.5)
        #expect(provider.applyAction(.increment(step: 0.5), to: 0.0) == 0.5)
    }

    @Test("decrement subtracts step, clamped to 0")
    func decrement() {
        #expect(provider.applyAction(.decrement(step: 0.5), to: 1.0) == 0.5)
        #expect(provider.applyAction(.decrement(step: 0.5), to: 0.0) == 0.0)
    }

    @Test("normalizedProgress returns ratio to target")
    func normalizedProgress() {
        #expect(provider.normalizedProgress(1.0) == 0.5)
        #expect(provider.normalizedProgress(2.0) == 1.0)
        #expect(provider.normalizedProgress(3.0) == 1.0) // capped at 1.0
    }

    @Test("reset sets progress to 0")
    func reset() {
        #expect(provider.applyAction(.reset, to: 1.5) == 0.0)
    }
}

@Suite("Timer Tracking Provider Tests")
struct TimerTrackingProviderTests {

    private let provider = TimerTrackingProvider(
        configuration: .init(targetSeconds: 3600)
    )

    @Test("isComplete returns true when progress reaches target seconds")
    func isComplete() {
        #expect(provider.isComplete(progress: 3600) == true)
        #expect(provider.isComplete(progress: 4000) == true)
        #expect(provider.isComplete(progress: 2700) == false)
        #expect(provider.isComplete(progress: 0) == false)
    }

    @Test("increment adds seconds")
    func increment() {
        #expect(provider.applyAction(.increment(step: 900), to: 1800) == 2700)
    }

    @Test("normalizedProgress returns ratio to target")
    func normalizedProgress() {
        #expect(provider.normalizedProgress(1800) == 0.5)
        #expect(provider.normalizedProgress(3600) == 1.0)
        #expect(provider.normalizedProgress(7200) == 1.0) // capped
    }

    @Test("reset sets progress to 0")
    func reset() {
        #expect(provider.applyAction(.reset, to: 2700) == 0.0)
    }
}

@Suite("AnyTrackingProvider Tests")
struct AnyTrackingProviderTests {

    @Test("type-erased provider preserves behavior")
    func typeErasedBinary() {
        let provider = AnyTrackingProvider(BinaryTrackingProvider())
        #expect(provider.mode == "binary")
        #expect(provider.isComplete(progress: 1.0) == true)
        #expect(provider.isComplete(progress: 0.0) == false)
        #expect(provider.applyAction(.toggle, to: 0.0) == 1.0)
    }

    @Test("type-erased counter preserves configuration")
    func typeErasedCounter() {
        let provider = AnyTrackingProvider(
            CounterTrackingProvider(configuration: .init(target: 2.0, step: 0.5, unit: "L"))
        )
        #expect(provider.mode == "counter")
        #expect(provider.isComplete(progress: 2.0) == true)
        #expect(provider.displayInfo.step == 0.5)
        #expect(provider.displayInfo.unit == "L")
    }
}
