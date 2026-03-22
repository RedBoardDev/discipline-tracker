import Foundation

/// Creates and configures the default tracking provider registry.
///
/// To add a new tracking mode:
/// 1. Create a provider conforming to `TrackingProvider`
/// 2. Register it here via `.registering(MyProvider.self)`
/// 3. Create a control view in `Features/Home/Components/Controls/`
/// 4. Add a case in `TrackingControlViewFactory`
enum TrackingSetup {
    static func createRegistry() -> TrackingProviderRegistry {
        TrackingProviderRegistry()
            .registering(BinaryTrackingProvider.self)
            .registering(CounterTrackingProvider.self)
            .registering(TimerTrackingProvider.self)
    }
}
