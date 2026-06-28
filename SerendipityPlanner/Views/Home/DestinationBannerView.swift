import SwiftUI

/// ホーム画面上部に表示する目的地バナー。
/// - 未設定: 「目的地を決める」カード
/// - 設定済み（フル）: 目的地名・補足・提案中スポット数・変更ボタン
/// - 設定済み（コンパクト）: 1行表示（予定を受け入れた後など省スペース時）
struct DestinationBannerView: View {
    let destination: TodayDestination?
    let spotCount: Int
    let isCompact: Bool
    /// タップ時（検索シートを開く）
    let onTap: () -> Void

    private let accent = Color.theme.walk

    var body: some View {
        if let destination {
            if isCompact {
                compactBanner(destination)
            } else {
                fullBanner(destination)
            }
        } else {
            unsetBanner
        }
    }

    // MARK: - 未設定

    private var unsetBanner: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.title2)
                    .foregroundColor(accent)
                    .frame(width: 44, height: 44)
                    .background(accent.opacity(0.15))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text("目的地を決める")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("行き先を選ぶと、その街での小さな偶然をご提案します")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.theme.cardBackground)
            .cornerRadius(20)
            .shadow(color: accent.opacity(0.08), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("目的地を決める。行き先を選ぶと、その街での提案が表示されます")
        .accessibilityHint("タップで目的地を検索")
    }

    // MARK: - 設定済み（フル）

    private func fullBanner(_ destination: TodayDestination) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "mappin.circle.fill")
                .font(.title)
                .foregroundColor(accent)

            VStack(alignment: .leading, spacing: 3) {
                Text("目的地")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(destination.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Text(subtitleText(for: destination))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            changeButton
        }
        .padding()
        .background(Color.theme.cardBackground)
        .cornerRadius(20)
        .shadow(color: accent.opacity(0.08), radius: 8, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("目的地、\(destination.name)、\(subtitleText(for: destination))")
        .accessibilityHint("変更ボタンで目的地を選び直せます")
    }

    // MARK: - 設定済み（コンパクト）

    private func compactBanner(_ destination: TodayDestination) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "mappin.circle.fill")
                .font(.body)
                .foregroundColor(accent)

            Text("目的地")
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(destination.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(1)

            Spacer()

            changeButton
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.theme.cardBackground)
        .cornerRadius(12)
        .shadow(color: accent.opacity(0.06), radius: 4, x: 0, y: 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("目的地、\(destination.name)")
        .accessibilityHint("変更ボタンで目的地を選び直せます")
    }

    // MARK: - Parts

    private var changeButton: some View {
        Button(action: onTap) {
            Text("変更")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(accent.opacity(0.15))
                .cornerRadius(14)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("目的地を変更")
    }

    private func subtitleText(for destination: TodayDestination) -> String {
        if spotCount > 0 {
            return "\(destination.subtitle)・\(spotCount)スポットを提案中"
        }
        return destination.subtitle
    }
}
