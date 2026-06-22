import Combine
import SwiftUI

/// Spotify-style lyrics: the active line is bright and centered, neighbors fade
/// out, and the view auto-scrolls as playback advances.
struct LyricsView: View {
    let lines: [LyricLine]
    /// Returns the live playback position in seconds.
    let position: () -> Double

    @State private var activeIndex = 0
    private let tick = Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()

    private var isSynced: Bool { lines.contains { $0.time >= 0 } }

    var body: some View {
        if lines.isEmpty {
            placeholder("Letra indisponível")
        } else {
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    // Plain VStack (not Lazy) so every line is measured up front —
                    // avoids the scroll "jump" when a new batch comes into view.
                    VStack(alignment: .leading, spacing: 13) {
                        ForEach(Array(lines.enumerated()), id: \.element.id) { index, line in
                            Text(line.text.isEmpty ? "♪" : line.text)
                                // Constant font size: only weight/opacity/scale change,
                                // so line heights never shift (no reflow).
                                .font(.system(size: 14, weight: index == activeIndex ? .bold : .medium))
                                .foregroundStyle(.white.opacity(opacity(for: index)))
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .scaleEffect(index == activeIndex ? 1.04 : 1.0, anchor: .leading)
                                .id(index)
                                .animation(.easeInOut(duration: 0.25), value: activeIndex)
                        }
                    }
                    .padding(.vertical, 70)
                }
                .mask(
                    LinearGradient(
                        colors: [.clear, .black, .black, .clear],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .onReceive(tick) { _ in
                    guard isSynced else { return }
                    let next = currentIndex(for: position())
                    if next != activeIndex {
                        activeIndex = next
                        withAnimation(.easeInOut(duration: 0.35)) {
                            proxy.scrollTo(activeIndex, anchor: .center)
                        }
                    }
                }
            }
        }
    }

    private func opacity(for index: Int) -> Double {
        guard isSynced else { return 0.75 }
        switch abs(index - activeIndex) {
        case 0: return 1
        case 1: return 0.55
        case 2: return 0.35
        default: return 0.22
        }
    }

    private func currentIndex(for pos: Double) -> Int {
        var idx = 0
        for (i, line) in lines.enumerated() where line.time >= 0 {
            if line.time <= pos { idx = i } else { break }
        }
        return idx
    }

    @ViewBuilder
    private func placeholder(_ text: String) -> some View {
        VStack {
            Spacer()
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.4))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
