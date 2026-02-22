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

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

@main
struct SerendipityWidgetBundle: WidgetBundle {
    var body: some Widget {
        SerendipityWidget()
    }
}
