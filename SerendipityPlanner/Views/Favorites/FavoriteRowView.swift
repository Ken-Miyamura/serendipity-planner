import SwiftUI

/// お気に入り一覧の各行を表示するビュー
struct FavoriteRowView: View {
    let favorite: FavoriteSuggestion
    let formattedDate: String

    var body: some View {
        HStack(spacing: 12) {
            // カテゴリアイコン
            Image(systemName: favorite.category.iconName)
                .font(.title3)
                .foregroundColor(Color.theme.color(for: favorite.category))
                .frame(width: 44, height: 44)
                .background(
                    Color.theme.color(for: favorite.category).opacity(0.1)
                )
                .cornerRadius(10)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(favorite.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(favorite.category.displayName)
                        .font(.caption)
                        .foregroundColor(Color.theme.color(for: favorite.category))

                    if let placeName = favorite.placeName {
                        Text(placeName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Text(formattedDate)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(favorite.title)、\(favorite.category.displayName)、\(formattedDate)に追加")
    }
}
