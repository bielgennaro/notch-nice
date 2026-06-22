import SwiftUI

struct CatView: View {
    var size: CGFloat = 28
    @State private var animator = CatAnimator()

    var body: some View {
        Group {
            if let frame = animator.currentFrame {
                Image(nsImage: frame)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
            } else {
                Color.clear
            }
        }
        .frame(width: size, height: size)
        .onAppear { animator.start() }
        .onDisappear { animator.stop() }
    }
}
