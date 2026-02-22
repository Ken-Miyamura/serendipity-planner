import SwiftUI

struct SuggestionAcceptedView: View {
    @State private var animateCheck = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)
                .scaleEffect(animateCheck ? 1.0 : 0.5)
                .opacity(animateCheck ? 1.0 : 0.0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: animateCheck)

            Text("提案を受け入れました！")
                .font(.headline)
                .opacity(animateCheck ? 1.0 : 0.0)
                .animation(.easeIn(duration: 0.3).delay(0.2), value: animateCheck)

            Text("素敵な体験をお楽しみください")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .opacity(animateCheck ? 1.0 : 0.0)
                .animation(.easeIn(duration: 0.3).delay(0.4), value: animateCheck)
        }
        .padding(.vertical, 32)
        .onAppear {
            animateCheck = true
        }
    }
}
