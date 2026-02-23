import SwiftUI

/// 今月のカテゴリ別回数を表示するサマリービュー
struct HistorySummaryView: View {
    let categorySummary: [(category: SuggestionCategory, count: Int)]
    let totalCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("今月のまとめ")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                Spacer()

                Text("合計 \(totalCount)回")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if categorySummary.isEmpty {
                Text("まだ履歴がありません")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            } else {
                summaryGrid
            }
        }
        .padding(16)
        .background(Color.theme.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.theme.walk.opacity(0.06), radius: 4, x: 0, y: 1)
    }

    private var summaryGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ],
            spacing: 12
        ) {
            ForEach(categorySummary, id: \.category) { item in
                VStack(spacing: 6) {
                    Image(systemName: item.category.iconName)
                        .font(.title3)
                        .foregroundColor(Color.theme.color(for: item.category))

                    Text(item.category.displayName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    Text("\(item.count)回")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(item.category.displayName)、\(item.count)回")
            }
        }
    }
}
