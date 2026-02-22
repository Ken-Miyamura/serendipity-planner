import SwiftUI

struct WelcomePageView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 72))
                .foregroundColor(.accentColor)

            Text("セレンディピティ\nプランナー")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("カレンダーの空き時間を見つけて\n天気に合った素敵な体験を提案します")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            VStack(spacing: 12) {
                FeatureRow(
                    icon: "calendar",
                    color: .blue,
                    text: "空き時間を自動検出"
                )
                FeatureRow(
                    icon: "cloud.sun",
                    color: .orange,
                    text: "天気に応じた提案"
                )
                FeatureRow(
                    icon: "sparkle",
                    color: .purple,
                    text: "あなた好みの体験を提案"
                )
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .padding()
    }
}

struct FeatureRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 32)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
    }
}
