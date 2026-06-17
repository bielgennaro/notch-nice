import SwiftUI

@main
struct NotchNiceApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("NotchNice", systemImage: "rectangle.topthird.inset.filled") {
            Button("Exit") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
        }
    }
}
