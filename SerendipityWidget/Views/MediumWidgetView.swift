import SwiftUI
import WidgetKit

struct MediumWidgetView: View {
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
                HStack(spacing: 12) {
                    // 左: アイコン
                    VStack {
                        Image(systemName: suggestion.category.iconName)
                            .font(.largeTitle)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .frame(width: 60)

                    // 右: 詳細
                    VStack(alignment: .leading, spacing: 4) {
                        Text(suggestion.category.displayName)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text(suggestion.title)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(1)

                        Spacer().frame(height: 2)

                        HStack(spacing: 8) {
                            // 時間
                            Label(slot.timeRangeText, systemImage: "clock")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))

                            // 場所
                            if let place = suggestion.nearbyPlace {
                                Label(place.name, systemImage: "mappin")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                                    .lineLimit(1)
                            }
                        }

                        // 天気
                        if let weather = entry.weather {
                            Label(weather.summary, systemImage: weather.condition.iconName)
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }

                    Spacer()
                }
                .padding()
            } else {
                HStack(spacing: 12) {
                    Image(systemName: "calendar.badge.checkmark")
                        .font(.largeTitle)
                        .foregroundColor(.white.opacity(0.7))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("今日の空き時間はありません")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))

                        Text("カレンダーに空きができたらお知らせします")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }

                    Spacer()
                }
                .padding()
            }
        }
    }
}
