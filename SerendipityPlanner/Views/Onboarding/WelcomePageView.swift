import SwiftUI

struct WelcomePageView: View {
    private let cardBackground = Color.theme.cardBackground
    private let accentGreen = Color(red: 0.275, green: 0.608, blue: 0.459)

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // App Icon
            Image("AppIconImage")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 96, height: 96)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: Color.gray.opacity(0.15), radius: 12, x: 0, y: 6)

            Text("セレンディピティ\nプランナー")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)

            Text("カレンダーの空き時間を見つけて\n天気に合った素敵な体験を提案します")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)

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
                    color: accentGreen,
                    text: "あなた好みの体験を提案"
                )
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .padding()
    }
}

struct FeatureRow: View {
    let icon: String
    let color: Color
    let text: String

    private let cardBackground = Color.theme.cardBackground

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(color)
            }
            Text(text)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(cardBackground)
        )
        .shadow(color: Color.gray.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}
