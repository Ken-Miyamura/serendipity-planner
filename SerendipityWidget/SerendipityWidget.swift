import SwiftUI
import WidgetKit

struct SerendipityWidget: Widget {
    let kind: String = "SerendipityWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SerendipityTimelineProvider()) { entry in
            SerendipityWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Serendipity")
        .description("次の空き時間とおすすめのアクティビティを表示します")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct SerendipityWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: SerendipityEntry

    private var gradientColors: [Color] {
        let palette = SkyColorPalette.base(for: entry.timePeriod)
        return [palette.top.color, palette.middle.color, palette.bottom.color]
    }

    private var gradient: some View {
        LinearGradient(
            colors: gradientColors,
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var body: some View {
        let content = Group {
            switch family {
            case .systemSmall:
                SmallWidgetView(entry: entry)
            case .systemMedium:
                MediumWidgetView(entry: entry)
            default:
                SmallWidgetView(entry: entry)
            }
        }

        if #available(iOSApplicationExtension 17.0, *) {
            content
                .containerBackground(for: .widget) {
                    gradient
                }
        } else {
            ZStack {
                gradient
                content
            }
        }
    }
}

@main
struct SerendipityWidgetBundle: WidgetBundle {
    var body: some Widget {
        SerendipityWidget()
    }
}
