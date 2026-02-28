import SwiftUI

struct WelcomePageView: View {
    private var appIcon: UIImage {
        if let url = Bundle.main.url(forResource: "AppIcon60x60@2x", withExtension: "png"),
           let data = try? Data(contentsOf: url),
           let image = UIImage(data: data) {
            return image
        }
        return UIImage()
    }

    var body: some View {
        VStack(spacing: 0) {
            // App Icon (coral circle)
            ZStack {
                Circle()
                    .fill(OnboardingColors.coral.opacity(0.12))
                    .frame(width: 52, height: 52)
                Image(uiImage: appIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            }
            .padding(.top, 8)

            // Hero: Illustration with orange blob behind
            ZStack {
                // Orange organic blob
                OrangeBlob()
                    .fill(OnboardingColors.orange.opacity(0.40))
                    .frame(width: 260, height: 240)

                // Framed illustration
                Image("OnboardingIllustration")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 200, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white, lineWidth: 4)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 6)
            }
            .padding(.top, 8)

            // Title
            VStack(spacing: 4) {
                Text("セレンディピティ")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(OnboardingColors.coral)
                Text("プランナー")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(OnboardingColors.textMain)
            }
            .padding(.top, 14)

            // Subtitle
            Text("いつもの何気ない空き時間を、\n偶然出会う楽しみのきっかけに。")
                .font(.subheadline)
                .foregroundColor(OnboardingColors.textSub)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)

            Spacer().frame(maxHeight: 20)

            // 2x2 Feature Grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                FeatureCard(
                    icon: "calendar",
                    label: "空き時間を自動検出",
                    iconColor: Color(red: 0.50, green: 0.65, blue: 0.90),
                    bgColor: Color(red: 0.50, green: 0.65, blue: 0.90).opacity(0.08),
                    borderColor: Color(red: 0.50, green: 0.65, blue: 0.90).opacity(0.15)
                )
                FeatureCard(
                    icon: "sun.max.fill",
                    label: "天気と時間帯に応じた提案",
                    iconColor: Color(red: 0.92, green: 0.78, blue: 0.35),
                    bgColor: Color(red: 0.92, green: 0.78, blue: 0.35).opacity(0.10),
                    borderColor: Color(red: 0.92, green: 0.78, blue: 0.35).opacity(0.18)
                )
                FeatureCard(
                    icon: "location.fill",
                    label: "あなたの現在地に応じた提案",
                    iconColor: Color(red: 0.42, green: 0.75, blue: 0.55),
                    bgColor: Color(red: 0.42, green: 0.75, blue: 0.55).opacity(0.08),
                    borderColor: Color(red: 0.42, green: 0.75, blue: 0.55).opacity(0.15)
                )
                FeatureCard(
                    icon: "person.fill",
                    label: "あなた好みの体験を学習",
                    iconColor: Color(red: 0.70, green: 0.55, blue: 0.85),
                    bgColor: Color(red: 0.70, green: 0.55, blue: 0.85).opacity(0.08),
                    borderColor: Color(red: 0.70, green: 0.55, blue: 0.85).opacity(0.15)
                )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Feature Card (2x2 grid item)

private struct FeatureCard: View {
    let icon: String
    let label: String
    let iconColor: Color
    let bgColor: Color
    let borderColor: Color

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
            }
            Text(label)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(bgColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
    }
}

// MARK: - Orange Organic Blob

private struct OrangeBlob: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()

        path.move(to: CGPoint(x: w * 0.50, y: h * 0.02))
        path.addCurve(
            to: CGPoint(x: w * 0.92, y: h * 0.25),
            control1: CGPoint(x: w * 0.72, y: h * 0.0),
            control2: CGPoint(x: w * 0.88, y: h * 0.10)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.95, y: h * 0.65),
            control1: CGPoint(x: w * 0.98, y: h * 0.38),
            control2: CGPoint(x: w * 1.0, y: h * 0.55)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.55, y: h * 0.95),
            control1: CGPoint(x: w * 0.90, y: h * 0.80),
            control2: CGPoint(x: w * 0.75, y: h * 0.95)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.10, y: h * 0.70),
            control1: CGPoint(x: w * 0.35, y: h * 0.95),
            control2: CGPoint(x: w * 0.12, y: h * 0.88)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.08, y: h * 0.30),
            control1: CGPoint(x: w * 0.08, y: h * 0.55),
            control2: CGPoint(x: w * 0.02, y: h * 0.42)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.50, y: h * 0.02),
            control1: CGPoint(x: w * 0.15, y: h * 0.15),
            control2: CGPoint(x: w * 0.30, y: h * 0.04)
        )
        path.closeSubpath()
        return path
    }
}
