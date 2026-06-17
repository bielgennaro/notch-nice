import SwiftUI

struct NotchView: View {
    let notchSize: CGSize
    @State private var isHovered = false
    @State private var model = NowPlayingModel()

    var body: some View {
        ZStack(alignment: .top) {
            NotchShape(bottomRadius: isHovered ? 20 : 8)
                .fill(Color.blue)
                .frame(
                    width: isHovered ? 320 : notchSize.width,
                    height: isHovered ? 160 : notchSize.height
                )
                .overlay {
                    if isHovered {
                        content
                            .padding(.horizontal, 16)
                            .transition(.opacity)
                    }
                }
                .onHover { hovering in
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        isHovered = hovering
                    }
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .task { model.start() }
    }

    @ViewBuilder
    private var content: some View {
        if let track = model.track {
            HStack(spacing: 12) {
                AsyncImage(url: track.artworkUrl) { phase in
                    if let img = phase.image {
                        img.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        Color.white.opacity(0.1)
                    }
                }
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(track.artist)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                    Text(track.album)
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(1)
                }
                Spacer()
            }
        } else {
            Text("Nada tocando")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.5))
        }
    }
}
