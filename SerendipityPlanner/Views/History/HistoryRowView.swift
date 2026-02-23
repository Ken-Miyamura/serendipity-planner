import SwiftUI

/// 履歴リストの各行を表示するビュー
struct HistoryRowView: View {
    let history: SuggestionHistory
    let timeText: String

    private var categoryColor: Color {
        Color.theme.color(for: history.suggestion.category)
    }

    var body: some View {
        HStack(spacing: 12) {
            // カテゴリアイコン
            Image(systemName: history.suggestion.category.iconName)
                .font(.body)
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(categoryColor)
                .clipShape(Circle())

            // 提案情報
            VStack(alignment: .leading, spacing: 3) {
                Text(history.suggestion.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Label(timeText, systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let placeName = history.placeName {
                        Label(placeName, systemImage: "mappin")
                            .font(.caption)
                            .foregroundColor(categoryColor)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            // カテゴリ名
            Text(history.suggestion.category.displayName)
                .font(.caption)
                .foregroundColor(categoryColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(categoryColor.opacity(0.12))
                .cornerRadius(8)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.theme.cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.theme.walk.opacity(0.06), radius: 4, x: 0, y: 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        var label = "\(history.suggestion.category.displayName)、\(history.suggestion.title)、\(timeText)"
        if let placeName = history.placeName {
            label += "、\(placeName)"
        }
        return label
    }
}
