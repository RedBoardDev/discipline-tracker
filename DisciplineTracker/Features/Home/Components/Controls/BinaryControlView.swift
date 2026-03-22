import SwiftUI

/// Control view for binary (done/not done) objectives.
struct BinaryControlView: View {
    let isCompleted: Bool
    let accentColor: Color
    let onAction: (TrackingAction) -> Void

    @State private var animateCheck = false

    var body: some View {
        Button {
            HapticManager.shared.medium()
            withAnimation(.spring(duration: 0.3, bounce: 0.4)) {
                animateCheck.toggle()
            }
            onAction(.toggle)
        } label: {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(isCompleted ? accentColor : .secondary)
                .symbolEffect(.bounce, value: animateCheck)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(isCompleted ? "binary.mark_undone" : "binary.mark_done"))
    }
}
