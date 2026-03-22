import Foundation

struct TrackingDisplayInfo: Sendable {
    let mode: String
    let progressLabel: @Sendable (Double) -> String
    let unit: String?
    let showsProgressBar: Bool
    let step: Double?
    let target: Double
}
