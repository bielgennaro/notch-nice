import SwiftUI

@MainActor
@Observable

final class CatAnimator {
    enum State { case day, night }

    private(set) var currentFrame: NSImage?
    private var state: State = .day
    private var walkFrames: [NSImage] = []
    private var sleepFrames: [NSImage] = []
    private var index = 0
    private var timer: Timer?

    init() {
        walkFrames = CatAnimator.load(prefix: "walk", count: 8)
        sleepFrames = CatAnimator.load(prefix: "sleep", count: 8)
    }

    private static func load(prefix: String, count: Int) -> [NSImage] {
        // Each 64x64 source frame contains two cats side by side (left cat at
        // x:1–32, right cat at x:42+), both sitting at y:37–59 from the top.
        // Crop to just the left cat so a single, larger cat is shown.
        let crop = CGRect(x: 0, y: 34, width: 34, height: 28)

        return (0 ..< count).compactMap { i in
            let name = String(format: "%@_%02d", prefix, i)

            guard let url = Bundle.main.url(forResource: name, withExtension: "png"),
                  let img = NSImage(contentsOf: url),
                  let cg = img.cgImage(forProposedRect: nil, context: nil, hints: nil),
                  let cropped = cg.cropping(to: crop)
            else {
                print("⚠️ frame not found: \(name).png")

                return nil
            }

            return NSImage(cgImage: cropped, size: NSSize(width: crop.width, height: crop.height))
        }
    }

    func start() {
        updateStateFromClock()
        scheduleTimer()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func scheduleTimer() {
        timer?.invalidate()
        let interval = (state == .day) ? 0.3 : 0.3
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    private func tick() {
        let frames = (state == .day) ? walkFrames : sleepFrames
        guard !frames.isEmpty else { return }
        index = (index + 1) % frames.count
        currentFrame = frames[index]

        let newState: State = isNight() ? .night : .day
        if newState != state {
            state = newState
            index = 0
            scheduleTimer()
        }
    }

    private func updateStateFromClock() {
        state = isNight() ? .night : .day
        let frames = (state == .day) ? walkFrames : sleepFrames
        currentFrame = frames.first
    }

    private func isNight() -> Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= 20 || hour < 6
    }
}
