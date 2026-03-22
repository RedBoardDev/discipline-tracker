import Foundation

/// Manages active timer sessions in memory, with persistence to UserDefaults (App Group).
///
/// Each session only tracks the start time of the current running segment.
/// When paused, the elapsed delta is returned to the caller for flushing to SwiftData,
/// and the session is removed. This prevents double-counting.
///
/// Timers continue running in background because we only store `startedAt` — on foreground
/// resume, `currentSegmentElapsed()` correctly computes time including background duration.
@MainActor
@Observable
final class TimerSessionService {
    private(set) var activeSessions: [String: TimerSessionState] = [:]

    private static let persistenceKey = "timer_sessions_v2"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = UserDefaults(suiteName: "group.com.discipline.tracker") ?? .standard) {
        self.defaults = defaults
        restoreSessions()
    }

    /// Starts a timer for the given objective. If already running, does nothing.
    func start(objectiveId: String) {
        guard activeSessions[objectiveId] == nil else { return }
        activeSessions[objectiveId] = TimerSessionState(
            objectiveId: objectiveId,
            startedAt: .now
        )
        persistSessions()
    }

    /// Pauses the timer and returns the elapsed seconds since start.
    /// The caller must flush this delta to SwiftData.
    /// The session is removed after pausing.
    @discardableResult
    func pause(objectiveId: String) -> Double {
        guard let session = activeSessions[objectiveId] else { return 0 }
        let delta = session.currentSegmentElapsed()
        activeSessions.removeValue(forKey: objectiveId)
        persistSessions()
        return delta
    }

    /// Stops and removes the timer session without returning a delta.
    func reset(objectiveId: String) {
        activeSessions.removeValue(forKey: objectiveId)
        persistSessions()
    }

    /// Returns the live elapsed seconds for the current running segment.
    func elapsedSeconds(for objectiveId: String) -> Double {
        activeSessions[objectiveId]?.currentSegmentElapsed() ?? 0
    }

    /// Whether a timer is currently running for the given objective.
    func isRunning(_ objectiveId: String) -> Bool {
        activeSessions[objectiveId] != nil
    }

    /// Persists all active sessions to UserDefaults. Call on backgrounding.
    func persistSessions() {
        guard let data = try? JSONEncoder().encode(Array(activeSessions.values)) else { return }
        defaults.set(data, forKey: Self.persistenceKey)
    }

    /// Restores sessions from UserDefaults. Call on foregrounding.
    func restoreSessions() {
        guard let data = defaults.data(forKey: Self.persistenceKey),
              let sessions = try? JSONDecoder().decode([TimerSessionState].self, from: data) else {
            return
        }
        activeSessions = Dictionary(uniqueKeysWithValues: sessions.map { ($0.objectiveId, $0) })
    }
}
