import SwiftUI

@MainActor
@Observable
final class NowPlayingModel {
    var track: SpotifyTrack?
    var artwork: NSImage?
    var glowColors: [Color] = []
    var lyrics: [LyricLine] = []
    var isPlaying = false

    private var timer: Timer?
    private let queue = DispatchQueue(label: "spotify.applescript") // serial

    /// Track identity of the last loaded extras, so artwork/lyrics are only
    /// (re)fetched when the song actually changes.
    private var loadedTrackKey: String?

    /// Anchor used to interpolate playback position between 1s polls so the
    /// lyrics highlight moves smoothly.
    private var positionAnchor: Double = 0
    private var anchorDate = Date()

    func start() {
        poll()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.poll() }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    /// Estimated current playback position in seconds.
    func livePosition() -> Double {
        guard isPlaying else { return positionAnchor }
        return positionAnchor + Date().timeIntervalSince(anchorDate)
    }

    // MARK: - Controls

    func togglePlayPause() {
        queue.async { SpotifyReader.playPause() }
        // Optimistic update so the lyrics keep advancing without waiting for the poll.
        positionAnchor = livePosition()
        anchorDate = Date()
        isPlaying.toggle()
    }

    func next() {
        queue.async { SpotifyReader.nextTrack() }
        refreshSoon()
    }

    func previous() {
        queue.async { SpotifyReader.previousTrack() }
        refreshSoon()
    }

    private func refreshSoon() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            Task { @MainActor in self?.poll() }
        }
    }

    // MARK: - Polling

    private func poll() {
        queue.async {
            let t = SpotifyReader.fetch()
            Task { @MainActor [weak self] in self?.apply(t) }
        }
    }

    private func apply(_ t: SpotifyTrack?) {
        track = t

        guard let t else {
            isPlaying = false
            loadedTrackKey = nil
            artwork = nil
            glowColors = []
            lyrics = []
            return
        }

        isPlaying = t.isPlaying
        positionAnchor = t.position
        anchorDate = Date()

        let key = "\(t.title)—\(t.artist)—\(t.album)"
        if key != loadedTrackKey {
            loadedTrackKey = key
            loadExtras(for: t)
        }
    }

    private func loadExtras(for t: SpotifyTrack) {
        artwork = nil
        glowColors = []
        lyrics = []

        if let url = t.artworkUrl {
            Task { [weak self] in
                guard let (data, _) = try? await URLSession.shared.data(from: url),
                      let image = NSImage(data: data) else { return }
                guard let self, self.loadedTrackKey == "\(t.title)—\(t.artist)—\(t.album)" else { return }
                self.artwork = image
                self.glowColors = ArtworkColors.extract(from: image)
            }
        }

        Task { [weak self] in
            let lines = await LyricsService.fetch(track: t.title, artist: t.artist, album: t.album, duration: t.duration)
            guard let self, self.loadedTrackKey == "\(t.title)—\(t.artist)—\(t.album)" else { return }
            self.lyrics = lines
        }
    }
}
