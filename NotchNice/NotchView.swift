import SwiftUI

enum NotchPresentation: Equatable {
    case idle      // no music: just the notch (+ cat)
    case compact   // music playing, not hovered: album + soundwave peeking out
    case expanded  // hovered: full now-playing panel
}

struct NotchView: View {
    let notchSize: CGSize
    /// Reports the desired presentation so the window can resize to match.
    var onPresentationChange: (NotchPresentation) -> Void = { _ in }

    static let expandedWidth: CGFloat = 600
    static let expandedHeight: CGFloat = 300
    static let compactPeek: CGFloat = 76

    static func compactWidth(notchWidth: CGFloat) -> CGFloat { notchWidth + 2 * compactPeek }

    @State private var isHovered = false
    @State private var model = NowPlayingModel()

    private var presentation: NotchPresentation {
        if isHovered { return .expanded }
        if model.track != nil { return .compact }
        return .idle
    }

    private var shapeSize: CGSize {
        switch presentation {
        case .idle:
            return notchSize
        case .compact:
            return CGSize(width: Self.compactWidth(notchWidth: notchSize.width), height: notchSize.height)
        case .expanded:
            return CGSize(width: Self.expandedWidth, height: Self.expandedHeight)
        }
    }

    private var topRadius: CGFloat {
        switch presentation {
        case .idle: return 0
        case .compact: return 6
        case .expanded: return 12
        }
    }

    private var bottomRadius: CGFloat {
        switch presentation {
        case .idle: return 8
        case .compact: return 14
        case .expanded: return 22
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            NotchShape(topRadius: topRadius, bottomRadius: bottomRadius)
                .fill(Color.black)
                .frame(width: shapeSize.width, height: shapeSize.height)
                .overlay {
                    if presentation == .expanded {
                        expandedContent
                            .clipShape(NotchShape(topRadius: 12, bottomRadius: 22))
                            .transition(.opacity)
                    }
                }
                .overlay {
                    if presentation == .compact {
                        compactContent
                            .clipShape(NotchShape(topRadius: 6, bottomRadius: 14))
                            .transition(.opacity)
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    if presentation == .idle {
                        CatView(size: max(notchSize.height, 20))
                            .padding(.trailing, 14)
                            .padding(.bottom, 2)
                            .transition(.opacity)
                    }
                }
                .onHover { hovering in isHovered = hovering }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(.spring(response: 0.4, dampingFraction: 0.84), value: presentation)
        .task { model.start() }
        .onChange(of: presentation, initial: true) { _, _ in
            onPresentationChange(presentation)
        }
    }

    // MARK: - Compact (peeking) content

    private var compactContent: some View {
        HStack(spacing: 0) {
            AlbumArtView(image: model.artwork, glowColors: model.glowColors, size: notchSize.height - 8)
                .padding(.leading, 12)

            Spacer(minLength: notchSize.width)

            SoundWaveView(isPlaying: model.isPlaying, colors: model.glowColors)
                .frame(width: 44, height: notchSize.height - 16)
                .padding(.trailing, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Expanded panel

    @ViewBuilder
    private var expandedContent: some View {
        if let track = model.track {
            HStack(alignment: .top, spacing: 34) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .center, spacing: 16) {
                        AlbumArtView(image: model.artwork, glowColors: model.glowColors, size: 96)

                        VStack(alignment: .leading, spacing: 5) {
                            Text(track.title)
                                .font(.system(size: 21, weight: .bold))
                                .foregroundStyle(.white)
                                .lineLimit(2)
                            Text(track.artist)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.white.opacity(0.75))
                                .lineLimit(1)
                            Text(track.album)
                                .font(.system(size: 13))
                                .foregroundStyle(.white.opacity(0.5))
                                .lineLimit(1)
                        }
                        Spacer(minLength: 0)
                    }

                    ProgressBarView(
                        position: { model.livePosition() },
                        duration: track.duration,
                        colors: model.glowColors
                    )

                    controls
                        .frame(maxWidth: .infinity, alignment: .center)

                    Spacer(minLength: 0)
                }
                .frame(width: 280, alignment: .leading)

                LyricsView(lines: model.lyrics, position: { model.livePosition() })
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal, 26)
            .padding(.top, 38)
            .padding(.bottom, 12)
        } else {
            Text("Nada tocando")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.5))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var controls: some View {
        HStack(spacing: 30) {
            controlButton("backward.fill", size: 18) { model.previous() }
            controlButton(model.isPlaying ? "pause.fill" : "play.fill", size: 26) { model.togglePlayPause() }
            controlButton("forward.fill", size: 18) { model.next() }
        }
    }

    private func controlButton(_ systemName: String, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: size + 16, height: size + 16)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
