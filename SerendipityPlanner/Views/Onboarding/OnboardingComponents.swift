import SwiftUI

// MARK: - Onboarding Colors

enum OnboardingColors {
    /// ビビッドコーラル — タイトル・ウェルカムページのアクセント
    static let coral = Color(red: 1.0, green: 0.42, blue: 0.42)
    /// くすみコーラル — ボタン・インジケーター
    static let coralMuted = Color(red: 0.95, green: 0.48, blue: 0.45)
    /// オレンジ — ブロブ背景
    static let orange = Color(red: 1.0, green: 0.62, blue: 0.26)
    /// アクセントグリーン — 許可済み表示
    static let accentGreen = Color(red: 0.275, green: 0.608, blue: 0.459)
    /// テキストメイン
    static let textMain = Color(red: 0.2, green: 0.2, blue: 0.2)
    /// テキストサブ
    static let textSub = Color(red: 0.4, green: 0.4, blue: 0.4)
    /// テキストヒント
    static let textHint = Color(red: 0.6, green: 0.6, blue: 0.6)
}

// MARK: - Permission Granted Badge

struct PermissionGrantedBadge: View {
    var label: String = "許可済み"
    var accessibilityText: String = "許可済みです"

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(OnboardingColors.accentGreen)
                .font(.title3)
            Text(label)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(OnboardingColors.accentGreen)
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(OnboardingColors.accentGreen.opacity(0.1))
        )
        .padding(.horizontal, 24)
        .accessibilityLabel(accessibilityText)
    }
}

// MARK: - Permission Action Button

struct PermissionActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                Text(label)
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(OnboardingColors.coralMuted)
            )
            .shadow(color: OnboardingColors.coralMuted.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Permission Error View

struct PermissionErrorView: View {
    let error: String

    var body: some View {
        VStack(spacing: 4) {
            Text(error)
                .font(.caption)
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
                .padding(.top, 8)

            Button("設定を開く") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(.caption)
            .foregroundColor(OnboardingColors.coralMuted)
            .padding(.top, 4)
        }
    }
}

// MARK: - Permission Description

struct PermissionDescription: View {
    let text: String
    var showSettingsHint: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            Text(text)
                .font(.subheadline)
                .foregroundColor(OnboardingColors.textSub)
                .multilineTextAlignment(.center)
                .padding(.top, 12)

            if showSettingsHint {
                Text("後から設定アプリで変更できます")
                    .font(.caption)
                    .foregroundColor(OnboardingColors.textHint)
                    .padding(.top, 6)
            }
        }
    }
}
