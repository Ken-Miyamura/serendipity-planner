import SwiftUI

struct WelcomePageView: View {
    private let cardBackground = Color.theme.cardBackground
    private let accentGreen = Color(red: 0.275, green: 0.608, blue: 0.459)

    private var appIcon: UIImage {
        if let url = Bundle.main.url(forResource: "AppIcon60x60@2x", withExtension: "png"),
           let data = try? Data(contentsOf: url),
           let image = UIImage(data: data) {
            return image
        }
        return UIImage()
    }

    var body: some View {
        VStack(spacing: 14) {
            Spacer()

            // App Icon
            Image(uiImage: appIcon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color.gray.opacity(0.15), radius: 12, x: 0, y: 6)

            Text("セレンディピティ\nプランナー")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Text("いつもの何気ない空き時間を、\n偶然出会う楽しみのきっかけに。")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            VStack(spacing: 8) {
                FeatureRow(
                    icon: "calendar",
                    color: .blue,
                    text: "カレンダーから空き時間を自動検出"
                )
                FeatureRow(
                    icon: "cloud.sun",
                    color: .orange,
                    text: "天気と時間帯に応じた体験を提案"
                )
                FeatureRow(
                    icon: "location",
                    color: .teal,
                    text: "あなたのいる場所に応じた体験を提案"
                )
                FeatureRow(
                    icon: "sparkle",
                    color: accentGreen,
                    text: "あなた好みの体験を学習"
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
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
            }
            Text(text)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(cardBackground)
        )
        .shadow(color: Color.gray.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}
