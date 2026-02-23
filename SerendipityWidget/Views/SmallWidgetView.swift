import SwiftUI
import WidgetKit

struct SmallWidgetView: View {
    let entry: SerendipityEntry

    private var useLightText: Bool {
        entry.timePeriod.prefersLightText
    }

    private var primaryTextColor: Color {
        useLightText ? .white : .primary
    }

    private var secondaryTextColor: Color {
        useLightText ? .white.opacity(0.8) : .secondary
    }

    var body: some View {
        if let slot = entry.nextFreeTimeSlot, let suggestion = entry.suggestion {
            VStack(alignment: .leading, spacing: 6) {
                // カテゴリアイコン
                Image(systemName: suggestion.category.iconName)
                    .font(.title2)
                    .foregroundColor(Color.theme.color(for: suggestion.category))

                Spacer()

                // カテゴリ名
                Text(suggestion.category.displayName)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(primaryTextColor)
                    .shadow(
                        color: useLightText ? .black.opacity(0.3) : .clear,
                        radius: 2, y: 1
                    )

                // 時間
                Text(slot.timeRangeText)
                    .font(.caption)
                    .foregroundColor(secondaryTextColor)
            }
            .padding()
        } else {
            VStack(spacing: 8) {
                Image(systemName: "calendar.badge.checkmark")
                    .font(.title2)
                    .foregroundColor(secondaryTextColor)

                Text("空き時間なし")
                    .font(.caption)
                    .foregroundColor(secondaryTextColor)
            }
        }
    }
}
