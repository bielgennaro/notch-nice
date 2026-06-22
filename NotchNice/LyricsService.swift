import Foundation

struct LyricLine: Identifiable, Equatable {
    let id = UUID()
    /// Seconds from the start of the track. `-1` means the lyrics are not synced.
    let time: Double
    let text: String
}

/// Fetches lyrics from the free, key-less lrclib.net API. Prefers time-synced
/// lyrics (LRC) so the UI can do the Spotify-style karaoke highlight; falls back
/// to plain lyrics when no synced version exists.
enum LyricsService {
    static func fetch(track: String, artist: String, album: String, duration: Double) async -> [LyricLine] {
        guard !track.isEmpty, !artist.isEmpty else { return [] }

        var comps = URLComponents(string: "https://lrclib.net/api/get")!
        comps.queryItems = [
            URLQueryItem(name: "track_name", value: track),
            URLQueryItem(name: "artist_name", value: artist),
            URLQueryItem(name: "album_name", value: album),
            URLQueryItem(name: "duration", value: String(Int(duration.rounded()))),
        ]
        guard let url = comps.url else { return [] }

        var req = URLRequest(url: url)
        req.setValue("NotchNice (https://github.com/bielgennaro/NotchNice)", forHTTPHeaderField: "User-Agent")

        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else { return [] }
            let body = try JSONDecoder().decode(Response.self, from: data)

            if let synced = body.syncedLyrics, !synced.isEmpty {
                return parseLRC(synced)
            }
            if let plain = body.plainLyrics, !plain.isEmpty {
                return plain
                    .split(separator: "\n", omittingEmptySubsequences: false)
                    .map { LyricLine(time: -1, text: String($0)) }
            }
            return []
        } catch {
            print("⚠️ Lyrics fetch error", error)
            return []
        }
    }

    private struct Response: Decodable {
        let syncedLyrics: String?
        let plainLyrics: String?
    }

    private static func parseLRC(_ raw: String) -> [LyricLine] {
        var lines: [LyricLine] = []

        for rawLine in raw.split(separator: "\n", omittingEmptySubsequences: false) {
            var rest = Substring(rawLine)
            var times: [Double] = []

            // A line may carry several timestamps: "[00:12.34][01:10.00] text".
            while rest.first == "[", let close = rest.firstIndex(of: "]") {
                let tag = rest[rest.index(after: rest.startIndex) ..< close]
                if let t = parseTimestamp(tag) { times.append(t) }
                rest = rest[rest.index(after: close)...]
            }

            guard !times.isEmpty else { continue }
            let text = rest.trimmingCharacters(in: .whitespaces)
            for t in times { lines.append(LyricLine(time: t, text: text)) }
        }

        return lines.sorted { $0.time < $1.time }
    }

    private static func parseTimestamp(_ tag: Substring) -> Double? {
        let parts = tag.split(separator: ":")
        guard parts.count == 2,
              let minutes = Double(parts[0]),
              let seconds = Double(parts[1].replacingOccurrences(of: ",", with: "."))
        else { return nil }
        return minutes * 60 + seconds
    }
}
