import Foundation

struct SpotifyTrack: Equatable {
    var title: String
    var artist: String
    var album: String
    var artworkUrl: URL?
    var isPlaying: Bool
    var position: Double // seconds
    var duration: Double // seconds
}

enum SpotifyReader {
    static func fetch() -> SpotifyTrack? {
        let src = """
        if application "Spotify" is not running then return "NOTRUNNING"
        tell application "Spotify"
            set playerStateText to player state as text
            if playerStateText is "stopped" then return "STOPPED"
            set t to current track
            set theTitle to name of t
            set theArtist to artist of t
            set theAlbum to album of t
            set theArt to artwork url of t
            set theDur to (duration of t) / 1000
            set thePos to player position
            return theTitle & "\\n" & theArtist & "\\n" & theAlbum & "\\n" & theArt & "\\n" & playerStateText & "\\n" & (thePos as text) & "\\n" & (theDur as text)
        end tell
        """

        var err: NSDictionary?
        let result = NSAppleScript(source: src)?.executeAndReturnError(&err)

        if let err = err {
            print("⚠️ AppleScript error", err)
            return nil
        }

        guard let out = result?.stringValue, out != "NOTRUNNING", out != "STOPPED" else { return nil }

        let f = out.components(separatedBy: "\n")

        guard f.count >= 7 else {
            print("⚠️ Unexpected response")
            return nil
        }

        let artString = f[3].trimmingCharacters(in: .whitespacesAndNewlines)
        let artUrl = (artString.isEmpty || artString == "missing value")
            ? nil
            : URL(string: artString)

        return SpotifyTrack(
            title: f[0],
            artist: f[1],
            album: f[2],
            artworkUrl: artUrl,
            isPlaying: f[4] == "playing",
            position: parseDouble(f[5]),
            duration: parseDouble(f[6])
        )
    }

    private static func parseDouble(_ s: String) -> Double {
        let clean = s.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        return Double(clean) ?? 0
    }

    // MARK: - Playback controls

    static func playPause() { control("playpause") }
    static func nextTrack() { control("next track") }
    static func previousTrack() { control("previous track") }

    private static func control(_ command: String) {
        let src = """
        if application "Spotify" is running then
            tell application "Spotify" to \(command)
        end if
        """
        var err: NSDictionary?
        NSAppleScript(source: src)?.executeAndReturnError(&err)
        if let err = err {
            print("⚠️ Spotify control error", err)
        }
    }
}
