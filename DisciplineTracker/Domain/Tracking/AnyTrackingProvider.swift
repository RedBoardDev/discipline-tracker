import Foundation

/// Type-erased wrapper for `TrackingProvider`, enabling storage in `ObjectiveDefinition`.
///
/// Needed because `TrackingProvider` has an `associatedtype Configuration`,
/// preventing direct storage. This wrapper erases the type while preserving behavior.
struct AnyTrackingProvider: Sendable, Hashable {
    /// The tracking mode identifier.
    let mode: String

    private let _isComplete: @Sendable (Double) -> Bool
    private let _normalizedProgress: @Sendable (Double) -> Double
    private let _availableActions: Set<TrackingActionKind>
    private let _applyAction: @Sendable (TrackingAction, Double) -> Double
    private let _displayInfo: TrackingDisplayInfo
    private let _encodableConfig: @Sendable () -> (any Encodable & Sendable)
    private let _hashValue: Int

    init<P: TrackingProvider>(_ provider: P) {
        self.mode = P.mode
        self._isComplete = { provider.isComplete(progress: $0) }
        self._normalizedProgress = { provider.normalizedProgress($0) }
        self._availableActions = provider.availableActions
        self._applyAction = { provider.applyAction($0, to: $1) }
        self._displayInfo = provider.displayInfo
        self._encodableConfig = { provider.configuration }
        self._hashValue = provider.configuration.hashValue
    }

    func isComplete(progress: Double) -> Bool {
        _isComplete(progress)
    }

    func normalizedProgress(_ progress: Double) -> Double {
        _normalizedProgress(progress)
    }

    var availableActions: Set<TrackingActionKind> {
        _availableActions
    }

    func applyAction(_ action: TrackingAction, to currentProgress: Double) -> Double {
        _applyAction(action, currentProgress)
    }

    var displayInfo: TrackingDisplayInfo {
        _displayInfo
    }

    // MARK: - Hashable

    static func == (lhs: AnyTrackingProvider, rhs: AnyTrackingProvider) -> Bool {
        lhs.mode == rhs.mode && lhs._hashValue == rhs._hashValue
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(mode)
        hasher.combine(_hashValue)
    }
}
