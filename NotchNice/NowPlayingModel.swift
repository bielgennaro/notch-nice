import SwiftUI

@MainActor
@Observable
final class NowPlayingModel {
    var track: SpotifyTrack?

    private var timer: Timer?
    private let queue = DispatchQueue(label: "spotify.applescript") // serial

    func start() {
        poll()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.poll()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func poll() {
        queue.async {
            let t = SpotifyReader.fetch()
            Task { @MainActor [weak self] in
                self?.track = t
            }
        }
    }
}
