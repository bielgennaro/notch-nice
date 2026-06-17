import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: NSPanel?

    func applicationDidFinishLaunching(_: Notification) {
        setupNotchPanel()

//        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
//            let track = SpotifyReader.fetch()
//            print("🎵 Actual song:", track as Any)
//        }
    }

    private func notchFrame(for screen: NSScreen) -> NSRect {
        let full = screen.frame
        let notchHeight = screen.safeAreaInsets.top

        guard notchHeight > 0,
              let left = screen.auxiliaryTopLeftArea,
              let right = screen.auxiliaryTopRightArea
        else {
            let w: CGFloat = 220
            return NSRect(x: full.midX - w / 2, y: full.maxY - 32, width: w, height: 32)
        }

        let x = left.maxX // 751
        let notchWidth = right.minX - left.maxX // 209
        let y = full.maxY - notchHeight // 1074

        return NSRect(x: x, y: y, width: notchWidth, height: notchHeight)
    }

    private func setupNotchPanel() {
        guard let screen = NSScreen.screens.first(where: { $0.safeAreaInsets.top > 0 }) ?? NSScreen.main else { return }

        let notch = notchFrame(for: screen)

        let expandedWidth: CGFloat = 360
        let expandedHeight: CGFloat = 180
        let rect = NSRect(
            x: notch.midX - expandedWidth / 2,
            y: notch.maxY - expandedHeight,
            width: expandedWidth,
            height: expandedHeight
        )
        print(">>> notch =", notch)
        print(">>> notch.midX =", notch.midX)
        print(">>> panel rect =", rect)
        print(">>> panel midX =", rect.midX)

        let panel = NSPanel(
            contentRect: rect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.level = .statusBar
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.isMovable = false
        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .ignoresCycle,
        ]

        let hosting = NSHostingView(rootView: NotchView(notchSize: notch.size))

        panel.contentView = hosting

        panel.orderFrontRegardless()

        self.panel = panel
        print("Notch Nice created in \(rect)")
    }
}

// private struct DebugNotchNiceView: View {
//    var body: some View {
//        Rectangle()
//            .fill(Color.red.opacity(0.5))
//    }
// }
