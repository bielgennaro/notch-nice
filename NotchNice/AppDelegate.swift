import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: NSPanel?
    private var collapsedRect: NSRect = .zero
    private var compactRect: NSRect = .zero
    private var expandedRect: NSRect = .zero
    private var collapseWork: DispatchWorkItem?

    func applicationDidFinishLaunching(_: Notification) {
        setupNotchPanel()
    }

    private func notchFrame(for screen: NSScreen) -> NSRect {
        let full = screen.frame
        let notchHeight = screen.safeAreaInsets.top

        guard notchHeight > 0,
              let left = screen.auxiliaryTopLeftArea,
              let right = screen.auxiliaryTopRightArea
        else {
            let w: CGFloat = 600
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

        // Collapsed: window matches the physical notch exactly, so it doesn't
        // block clicks on the menu bar. Compact: a wider pill with the album and
        // visualizer peeking out. Expanded: a large panel that hangs below.
        collapsedRect = notch

        let compactW = NotchView.compactWidth(notchWidth: notch.width) + 24 // room for top ears
        compactRect = NSRect(
            x: notch.midX - compactW / 2,
            y: notch.maxY - notch.height,
            width: compactW,
            height: notch.height
        )

        let margin: CGFloat = 40 // room for the top "ears" and album glow blur
        expandedRect = NSRect(
            x: notch.midX - (NotchView.expandedWidth + margin) / 2,
            y: notch.maxY - NotchView.expandedHeight,
            width: NotchView.expandedWidth + margin,
            height: NotchView.expandedHeight
        )

        let panel = NSPanel(
            contentRect: collapsedRect,
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

        let hosting = NSHostingView(rootView: NotchView(notchSize: notch.size) { [weak self] presentation in
            self?.present(presentation)
        })

        panel.contentView = hosting
        panel.orderFrontRegardless()

        self.panel = panel
    }

    private func rect(for presentation: NotchPresentation) -> NSRect {
        switch presentation {
        case .idle: return collapsedRect
        case .compact: return compactRect
        case .expanded: return expandedRect
        }
    }

    /// Grows the window immediately; shrinks it shortly after so the collapse
    /// animation isn't clipped by the smaller frame.
    private func present(_ presentation: NotchPresentation) {
        guard let panel else { return }
        collapseWork?.cancel()

        let target = rect(for: presentation)
        if target.width >= panel.frame.width {
            // Defer to the next runloop so SwiftUI commits its animated transaction
            // first — otherwise the synchronous resize renders the final (big) state
            // for one frame, which reads as a flicker.
            DispatchQueue.main.async { [weak self] in
                self?.panel?.setFrame(target, display: true)
            }
        } else {
            let work = DispatchWorkItem { [weak self] in
                self?.panel?.setFrame(target, display: true)
            }
            collapseWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45, execute: work)
        }
    }
}

// private struct DebugNotchNiceView: View {
//    var body: some View {
//        Rectangle()
//            .fill(Color.red.opacity(0.5))
//    }
// }
