import UIKit
import CoreHaptics

/// Manages haptic feedback with CoreHaptics support and fallback to UIImpactFeedbackGenerator.
///
/// Provides a singleton interface for different types of haptic feedback:
/// - Impact feedback: light, medium, heavy
/// - Notification feedback: success, error, warning
///
/// Haptics can be enabled/disabled via the `isEnabled` property, which is persisted in UserDefaults.
@MainActor
@Observable
final class HapticManager {

    // MARK: - Singleton

    static let shared = HapticManager()

    private init() {
        self.isEnabled = UserDefaults.standard.object(forKey: Keys.hapticsEnabled) == nil
            ? true
            : UserDefaults.standard.bool(forKey: Keys.hapticsEnabled)
    }

    // MARK: - Configuration

    /// Whether haptic feedback is enabled.
    var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: Keys.hapticsEnabled)
        }
    }

    // MARK: - CoreHaptics Engine

    private var hapticEngine: CHHapticEngine?
    private var engineCreated = false

    private func createEngine() {
        guard !engineCreated else { return }

        do {
            hapticEngine = try CHHapticEngine()
            engineCreated = true

            // Handle engine stops (e.g., system audio session interruption)
            hapticEngine?.stoppedHandler = { [weak self] _ in
                self?.engineCreated = false
                self?.hapticEngine = nil
            }

            try hapticEngine?.start()
        } catch {
            engineCreated = false
        }
    }

    // MARK: - Impact Feedback

    /// Triggers a light impact haptic.
    func light() {
        guard isEnabled else { return }
        playImpact(style: .light)
    }

    /// Triggers a medium impact haptic.
    func medium() {
        guard isEnabled else { return }
        playImpact(style: .medium)
    }

    /// Triggers a heavy impact haptic.
    func heavy() {
        guard isEnabled else { return }
        playImpact(style: .heavy)
    }

    private func playImpact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        // Try CoreHaptics first
        if #available(iOS 15.0, *), playCoreHapticsImpact(style) {
            return
        }
        // Fallback to UIImpactFeedbackGenerator
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    @available(iOS 15.0, *)
    private func playCoreHapticsImpact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) -> Bool {
        createEngine()
        guard let engine = hapticEngine else { return false }

        let intensity: Float
        let sharpness: Float

        switch style {
        case .light:
            intensity = 0.5
            sharpness = 0.5
        case .medium:
            intensity = 0.7
            sharpness = 0.7
        case .heavy:
            intensity = 1.0
            sharpness = 1.0
        case .soft:
            intensity = 0.4
            sharpness = 0.3
        case .rigid:
            intensity = 0.9
            sharpness = 1.0
        @unknown default:
            intensity = 0.5
            sharpness = 0.5
        }

        do {
            let event = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                ],
                relativeTime: 0
            )
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            try engine.makePlayer(with: pattern).start(atTime: 0)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Notification Feedback

    /// Triggers a success notification haptic.
    func success() {
        guard isEnabled else { return }
        playNotification(style: .success)
    }

    /// Triggers an error notification haptic.
    func error() {
        guard isEnabled else { return }
        playNotification(style: .error)
    }

    /// Triggers a warning notification haptic.
    func warning() {
        guard isEnabled else { return }
        playNotification(style: .warning)
    }

    /// Triggers a special haptic for perfect day achievement.
    static func perfectDay() {
        shared.success()
        shared.heavy()
    }

    private func playNotification(style: UINotificationFeedbackGenerator.FeedbackType) {
        // Try CoreHaptics first
        if #available(iOS 15.0, *), playCoreHapticsNotification(style) {
            return
        }
        // Fallback to UINotificationFeedbackGenerator
        UINotificationFeedbackGenerator().notificationOccurred(style)
    }

    @available(iOS 15.0, *)
    private func playCoreHapticsNotification(_ style: UINotificationFeedbackGenerator.FeedbackType) -> Bool {
        createEngine()
        guard let engine = hapticEngine else { return false }

        let intensity: Float
        let sharpness: Float

        switch style {
        case .success:
            intensity = 1.0
            sharpness = 0.8
        case .error:
            intensity = 1.0
            sharpness = 1.0
        case .warning:
            intensity = 0.8
            sharpness = 0.8
        @unknown default:
            intensity = 0.5
            sharpness = 0.5
        }

        do {
            let event = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                ],
                relativeTime: 0
            )
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            try engine.makePlayer(with: pattern).start(atTime: 0)
            return true
        } catch {
            return false
        }
    }
}

// MARK: - UserDefaults Keys

private extension HapticManager {
    enum Keys {
        static let hapticsEnabled = "haptics.enabled"
    }
}
