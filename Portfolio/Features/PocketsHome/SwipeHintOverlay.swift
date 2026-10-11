import SwiftUI

/// Row offset of the hint cards at `time`: hold at 0 for 35% of a 1.6s loop, then ease to -(card + gap) and jump back.
func hintOffset(at time: TimeInterval) -> CGFloat {
    let period = 1.6, hold = 0.35
    let fraction = time.truncatingRemainder(dividingBy: period) / period
    let t = max(0, fraction - hold) / (1 - hold)
    return -79 * UnitCurve.easeInOut.value(at: t)
}

/// First-visit hint that the pocket card swipes. A tap anywhere but the illustration/title, or the X, dismisses.
struct SwipeHintOverlay: View {
    let onClose: () -> Void

    var body: some View {
        ZStack {
            // Dim only; the 4pt blur is applied by the host to the content underneath.
            Color(hex: 0x161D35, alpha: 0.4)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)

            VStack(spacing: 36) {
                illustration
                Text("Swipe to switch between your pockets")
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .frame(width: 226)
            }
            // Swallow taps on the illustration and title so they don't dismiss.
            .contentShape(Rectangle())
            .onTapGesture {}

            VStack {
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                        .background(.black, in: .rect(cornerRadius: 16))
                }
                .padding(.bottom, 60)
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
