import SwiftUI
import WidgetKit

struct SmallWidgetView: View {
    let entry: SerendipityEntry

    private var gradientColors: [Color] {
        let palette = SkyColorPalette.base(for: entry.timePeriod)
        return [palette.top.color, palette.middle.color, palette.bottom.color]
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: gradientColors,
                startPoint: .top,
                endPoint: .bottom
            )

            if let slot = entry.nextFreeTimeSlot, let suggestion = entry.suggestion {
                VStack(alignment: .leading, spacing: 6) {
                    // カテゴリアイコン
                    Image(systemName: suggestion.category.iconName)
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.9))

                    Spacer()

                    // カテゴリ名
                    Text(suggestion.category.displayName)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    // 時間
                    Text(slot.timeRangeText)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding()
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.checkmark")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.7))

                    Text("空き時間なし")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }
}
