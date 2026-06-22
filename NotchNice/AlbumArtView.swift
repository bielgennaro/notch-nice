import SwiftUI

/// Album cover with a soft, slowly rotating glow built from the cover's own colors.
struct AlbumArtView: View {
    let image: NSImage?
    let glowColors: [Color]
    var size: CGFloat = 96

    @State private var rotation = false

    var body: some View {
        ZStack {
            if !glowColors.isEmpty {
                AngularGradient(
                    gradient: Gradient(colors: glowColors + [glowColors[0]]),
                    center: .center,
                    angle: .degrees(rotation ? 360 : 0)
                )
                .frame(width: size * 1.35, height: size * 1.35)
                .clipShape(Circle())
                .blur(radius: 26)
                .opacity(0.9)
                .onAppear {
                    withAnimation(.linear(duration: 9).repeatForever(autoreverses: false)) {
                        rotation = true
                    }
                }
            }

            Group {
                if let image {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    RoundedRectangle(cornerRadius: size * 0.16, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .overlay(Image(systemName: "music.note").foregroundStyle(.white.opacity(0.3)))
                }
            }
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.16, style: .continuous))
            .shadow(color: .black.opacity(0.4), radius: 6, y: 3)
        }
        .frame(width: size, height: size)
    }
}
