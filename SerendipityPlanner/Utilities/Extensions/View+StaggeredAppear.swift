import SwiftUI

/// カードの出現アニメーション（フェードイン＋スライドイン）
struct StaggeredAppearModifier: ViewModifier {
    let index: Int
    let delay: Double

    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .onAppear {
                withAnimation(
                    .easeOut(duration: 0.4)
                        .delay(Double(index) * delay)
                ) {
                    isVisible = true
                }
            }
    }
}

extension View {
    func staggeredAppear(index: Int, delay: Double = 0.08) -> some View {
        modifier(StaggeredAppearModifier(index: index, delay: delay))
    }
}
