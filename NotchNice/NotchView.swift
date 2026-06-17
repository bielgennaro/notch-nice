import SwiftUI

struct NotchView: View {
    let notchSize: CGSize
    @State private var isHovered = false

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: isHovered ? 20 : 8)
                .fill(.black)
                .frame(
                    width: isHovered ? 320 : notchSize.width,
                    height: isHovered ? 140 : notchSize.height
                )
                .overlay {
                    if isHovered {
                        Text("Hello World do NotchNice 👋")
                            .foregroundStyle(.white)
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
    }
}
