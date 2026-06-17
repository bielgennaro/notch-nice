import SwiftUI

struct NotchShape: Shape {
    var bottomRadius: CGFloat = 12

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius = min(bottomRadius, rect.height / 2, rect.width / 2)

        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - radius))

        path.addQuadCurve(to: CGPoint(x: rect.minX + radius, y: rect.maxY), control: CGPoint(x: rect.minX, y: rect.maxY))

        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.maxY))

        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY - radius), control: CGPoint(x: rect.maxX, y: rect.maxY))

        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))

        path.closeSubpath()

        return path
    }
}
