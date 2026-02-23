import SwiftUI
import WidgetKit

struct MediumWidgetView: View {
    let entry: SerendipityEntry

    private var useLightText: Bool {
        entry.timePeriod.prefersLightText
    }

    private var primaryTextColor: Color {
        useLightText ? .white : .primary
    }

    private var secondaryTextColor: Color {
        useLightText ? .white.opacity(0.85) : .secondary
    }

    private var tertiaryTextColor: Color {
        useLightText ? .white.opacity(0.7) : Color(red: 0.5, green: 0.5, blue: 0.55)
    }

    var body: some View {
        if let slot = entry.nextFreeTimeSlot, let suggestion = entry.suggestion {
            HStack(spacing: 12) {
                // 左: アイコン
                VStack {
                    Image(systemName: suggestion.category.iconName)
                        .font(.largeTitle)
                        .foregroundColor(Color.theme.color(for: suggestion.category))
                }
                .frame(width: 60)

                // 右: 詳細
                VStack(alignment: .leading, spacing: 4) {
                    Text(suggestion.category.displayName)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(primaryTextColor)
                        .shadow(
                            color: useLightText ? .black.opacity(0.3) : .clear,
                            radius: 2, y: 1
                        )

                    Text(suggestion.title)
                        .font(.subheadline)
                        .foregroundColor(secondaryTextColor)
                        .lineLimit(1)

                    Spacer().frame(height: 2)

                    HStack(spacing: 8) {
                        // 時間
                        Label(slot.timeRangeText, systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(secondaryTextColor)

                        // 場所
                        if let place = suggestion.nearbyPlace {
                            Label(place.name, systemImage: "mappin")
                                .font(.caption)
                                .foregroundColor(secondaryTextColor)
                                .lineLimit(1)
                        }
                    }

                    // 天気
                    if let weather = entry.weather {
                        Label(weather.summary, systemImage: weather.condition.iconName)
                            .font(.caption2)
                            .foregroundColor(tertiaryTextColor)
                    }
                }

                Spacer()
            }
            .padding()
        } else {
            HStack(spacing: 12) {
                Image(systemName: "calendar.badge.checkmark")
                    .font(.largeTitle)
                    .foregroundColor(secondaryTextColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text("今日の空き時間はありません")
                        .font(.headline)
                        .foregroundColor(primaryTextColor)

                    Text("カレンダーに空きができたらお知らせします")
                        .font(.caption)
                        .foregroundColor(secondaryTextColor)
                }

                Spacer()
            }
            .padding()
        }
    }
}
