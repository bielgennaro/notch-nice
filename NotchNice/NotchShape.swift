import SwiftUI

/// The notch silhouette. Bottom corners are convex (rounded outward); the top
/// corners flare *outward* with a concave curve so the panel looks like it is
/// growing out of the physical notch / top edge of the screen.
struct NotchShape: Shape {
    var topRadius: CGFloat = 0
    var bottomRadius: CGFloat = 12

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(topRadius, bottomRadius) }
        set { topRadius = newValue.first; bottomRadius = newValue.second }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let topR = max(0, min(topRadius, rect.height / 2))
        let botR = max(0, min(bottomRadius, rect.height / 2, rect.width / 2))

        // Top-left ear: start out to the left, curve down into the body.
        path.move(to: CGPoint(x: rect.minX - topR, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.minY + topR),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )

        // Left edge down to the bottom-left convex corner.
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - botR))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + botR, y: rect.maxY),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )

        // Bottom edge to the bottom-right convex corner.
        path.addLine(to: CGPoint(x: rect.maxX - botR, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY - botR),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )

        // Right edge up to the top-right ear.
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + topR))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX + topR, y: rect.minY),
            control: CGPoint(x: rect.maxX, y: rect.minY)
        )

        path.closeSubpath()
        return path
    }
}
