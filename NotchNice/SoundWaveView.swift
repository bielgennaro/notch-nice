import Combine
import SwiftUI

/// A faux audio visualizer. Real Spotify audio isn't accessible, so the bars
/// animate while playing and settle to a low level when paused. Tinted with the
/// album colors.
struct SoundWaveView: View {
    let isPlaying: Bool
    let colors: [Color]
    var barCount: Int = 5

    @State private var levels: [CGFloat]
    private let tick = Timer.publish(every: 0.13, on: .main, in: .common).autoconnect()

    init(isPlaying: Bool, colors: [Color], barCount: Int = 5) {
        self.isPlaying = isPlaying
        self.colors = colors
        self.barCount = barCount
        _levels = State(initialValue: Array(repeating: 0.2, count: barCount))
    }

    private var fill: LinearGradient {
        LinearGradient(
            colors: colors.isEmpty ? [.white.opacity(0.85)] : colors,
            startPoint: .bottom, endPoint: .top
        )
    }

    var body: some View {
        GeometryReader { geo in
            HStack(alignment: .center, spacing: 3) {
                ForEach(0 ..< barCount, id: \.self) { i in
                    Capsule()
                        .fill(fill)
                        .frame(width: 3, height: max(3, geo.size.height * levels[i]))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .onReceive(tick) { _ in
            withAnimation(.easeInOut(duration: 0.13)) {
                levels = levels.map { _ in isPlaying ? CGFloat.random(in: 0.3 ... 1.0) : 0.18 }
            }
        }
    }
}
