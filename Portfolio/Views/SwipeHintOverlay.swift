import SwiftUI

/// Row offset of the hint cards at `time`: hold at 0 for 35% of a 1.6s loop, then ease to -(card + gap) and jump back.
func hintOffset(at time: TimeInterval) -> CGFloat {
    let period = 1.6, hold = 0.35
    let fraction = time.truncatingRemainder(dividingBy: period) / period
    let t = max(0, fraction - hold) / (1 - hold)
    return -79 * UnitCurve.easeInOut.value(at: t)
}

/// First-visit hint that the pocket card swipes. Tap outside the copy or the close button to dismiss.
struct SwipeHintOverlay: View {
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            illustration
            VStack(spacing: 8) {
                Text("Swipe between pockets").font(.titleL)
                Text("Swipe the card left or right to switch pockets.").font(.bodyS)
            }
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
        // Swallow taps on the illustration/copy so only the backdrop dismisses.
        .contentShape(Rectangle())
        .onTapGesture {}
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            // Dim only; the 4pt backdrop blur is applied by the host to the content underneath.
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)
        }
        .overlay(alignment: .topTrailing) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .contentShape(Rectangle())
            }
        }
    }

    private var illustration: some View {
        TimelineView(.animation) { context in
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 16).fill(.white).frame(width: 74, height: 82)
                }
            }
            .fixedSize()
            .offset(x: 5 + hintOffset(at: context.date.timeIntervalSinceReferenceDate))
        }
        .frame(width: 84, height: 82, alignment: .leading)
        .clipped()
    }
}

#Preview {
    SwipeHintOverlay {}
}
