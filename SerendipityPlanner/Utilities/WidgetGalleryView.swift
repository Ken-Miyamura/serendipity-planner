#if DEBUG
    import SwiftUI
    import WidgetKit

    /// ウィジェットのレイアウトを UI テストから確認するための一覧。
    ///
    /// ## なぜアプリ側で描くのか
    ///
    /// ウィジェットは別ターゲットで、ホーム画面に配置しないと実物を見られない。
    /// XCUITest から配置する手順は SpringBoard の長押し・ウィジェットギャラリーの
    /// スクロールを挟むため壊れやすく、5言語ぶん回すには不向き。
    ///
    /// 検証したいのは**文字が枠に収まるか**であって WidgetKit の配信ではないので、
    /// 同じビューを同じ寸法の枠で描けば足りる。ウィジェット本体と同じ
    /// `SmallWidgetView` / `MediumWidgetView` を使うため、文言や行数を変えれば
    /// ここにも反映される。
    ///
    /// 枠の寸法は iPhone の中で**狭い部類**に合わせている。広い端末で確認すると
    /// 溢れを見逃すため。
    struct WidgetGalleryView: View {
        /// systemSmall（幅の狭い iPhone 相当）
        private let smallSize = CGSize(width: 158, height: 158)
        /// systemMedium（同上）
        private let mediumSize = CGSize(width: 338, height: 158)

        var body: some View {
            ScrollView {
                VStack(spacing: 20) {
                    frame("small", size: smallSize) {
                        SmallWidgetView(entry: Self.filledEntry)
                    }
                    frame("small.empty", size: smallSize) {
                        SmallWidgetView(entry: Self.emptyEntry)
                    }
                    frame("medium", size: mediumSize) {
                        MediumWidgetView(entry: Self.filledEntry)
                    }
                    frame("medium.empty", size: mediumSize) {
                        MediumWidgetView(entry: Self.emptyEntry)
                    }
                }
                .padding()
            }
            .uiTestID(AccessibilityID.screenWidgetGallery)
        }

        private func frame(
            _ name: String,
            size: CGSize,
            @ViewBuilder content: () -> some View
        ) -> some View {
            content()
                .frame(width: size.width, height: size.height)
                .background(gradient)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                // 枠そのものと同じ大きさの要素を1つ公開する。
                // コンテナに直接 identifier を付けると、SwiftUI は中身のうち
                // 都合のよい要素にそれを載せてしまい、テストが受け取る frame が
                // 枠ではなくアイコン1つ分になる（実際に 43pt が返ってきた）。
                .overlay(
                    Color.clear
                        .accessibilityElement(children: .ignore)
                        .uiTestID(AccessibilityID.widgetPreview(name))
                )
        }

        private var gradient: some View {
            let palette = SkyColorPalette.base(for: Self.timePeriod)
            return LinearGradient(
                colors: [palette.top.color, palette.middle.color, palette.bottom.color],
                startPoint: .top,
                endPoint: .bottom
            )
        }

        // MARK: - 固定の表示内容

        /// 時刻で背景と文字色が変わると言語間の比較にならないため固定する
        private static let timePeriod = TimePeriod.daytime

        private static var slot: FreeTimeSlot {
            StubCalendarService.fixedSlots()[0]
        }

        /// 提案が入っている状態。いちばん文字数が多くなる組み合わせを選ぶ
        private static var filledEntry: SerendipityEntry {
            let template = SuggestionTemplates.allTemplates.max {
                $0.title.count < $1.title.count
            } ?? SuggestionTemplates.allTemplates[0]
            return SerendipityEntry(
                date: Date(),
                nextFreeTimeSlot: slot,
                suggestion: Suggestion(
                    category: template.category,
                    title: template.title,
                    description: template.description,
                    duration: 60,
                    freeTimeSlot: slot,
                    weatherContext: "",
                    nearbyPlace: UITestStubs.place(for: template.category)
                ),
                weather: nil,
                timePeriod: timePeriod
            )
        }

        /// 「空き時間なし」の状態
        private static var emptyEntry: SerendipityEntry {
            SerendipityEntry(
                date: Date(),
                nextFreeTimeSlot: nil,
                suggestion: nil,
                weather: nil,
                timePeriod: timePeriod
            )
        }
    }
#endif
