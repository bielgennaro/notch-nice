import Combine
import SwiftUI

/// Playback progress bar tinted with the album's colors (matching the glow),
/// with elapsed / total time labels underneath.
struct ProgressBarView: View {
    let position: () -> Double
    let duration: Double
    let colors: [Color]

    @State private var elapsed: Double = 0
    private let tick = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()

    private var fillColors: [Color] {
        colors.isEmpty ? [.white.opacity(0.8), .white] : colors
    }

    private var progress: Double {
        duration > 0 ? min(1, max(0, elapsed / duration)) : 0
    }

    var body: some View {
        VStack(spacing: 5) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.15))

                    Capsule()
                        .fill(LinearGradient(colors: fillColors, startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(0, geo.size.width * progress))
                        .shadow(color: (fillColors.first ?? .white).opacity(0.7), radius: 5)
                }
            }
            .frame(height: 4)

            HStack {
                Text(timeString(elapsed))
                Spacer()
                Text(timeString(duration))
            }
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(.white.opacity(0.5))
        }
        .onReceive(tick) { _ in elapsed = position() }
    }

    private func timeString(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let total = Int(seconds)
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
