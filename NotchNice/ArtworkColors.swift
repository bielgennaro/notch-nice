import AppKit
import SwiftUI

enum ArtworkColors {
    static func extract(from image: NSImage, count: Int = 4) -> [Color] {
        guard let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return [] }

        let side = 16
        var pixels = [UInt8](repeating: 0, count: side * side * 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        guard let ctx = CGContext(
            data: &pixels,
            width: side,
            height: side,
            bitsPerComponent: 8,
            bytesPerRow: side * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return [] }

        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: side, height: side))

        struct Sample { let r, g, b, score: Double }
        var samples: [Sample] = []

        for i in stride(from: 0, to: pixels.count, by: 4) {
            let a = Double(pixels[i + 3]) / 255
            guard a > 0.4 else { continue }
            let r = Double(pixels[i]) / 255
            let g = Double(pixels[i + 1]) / 255
            let b = Double(pixels[i + 2]) / 255

            let maxC = max(r, g, b)
            let minC = min(r, g, b)
            let saturation = maxC == 0 ? 0 : (maxC - minC) / maxC
            let score = saturation * 0.7 + maxC * 0.3
            samples.append(Sample(r: r, g: g, b: b, score: score))
        }

        guard !samples.isEmpty else { return [] }
        let ranked = samples.sorted { $0.score > $1.score }

        var picked: [Sample] = []
        for s in ranked {
            if picked.count >= count { break }
            let isDistinct = picked.allSatisfy { abs($0.r - s.r) + abs($0.g - s.g) + abs($0.b - s.b) > 0.25 }
            if isDistinct { picked.append(s) }
        }
        if picked.isEmpty { picked = [ranked[0]] }

        return picked.map { Color(red: $0.r, green: $0.g, blue: $0.b) }
    }
}
