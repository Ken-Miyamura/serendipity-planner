import XCTest

/// レイアウト崩れを機械的に判定する。
///
/// スクリーンショットだけだと 5言語 × 全画面を人が目視することになり、
/// 見落としも起きる。**機械が判定できるものは機械に任せ、人は残りを見る**。
///
/// ## 何を機械で見て、何を人が見るか
///
/// | 症状 | 自動判定 | 理由 |
/// |---|---|---|
/// | 画面外へのはみ出し | **できる** | 要素の frame を実測できる |
/// | 文字の途切れ（`…`） | **できない** | 下記 |
/// | 要素の重なり | 限定的 | 同一階層の判定が難しく誤検知が多い |
///
/// ### 切り詰めが自動判定できない理由
///
/// XCUITest が返す `label` は**常に完全な文字列**で、画面上で切り詰められて
/// いるかは反映されない。実測で確認した。
///
/// ```
/// 画面表示: 「Choose where you're headed and we'll find…」（2行で折り返し）
/// label   : 「Choose where you're headed and we'll find small surprises there」
/// ```
///
/// さらに、元の文言自体に `…` を含むものがある（"取得中..." → "Locating…"）。
/// label の末尾で判定すると、これらを切り詰めと誤認する。実際に4言語 × 2画面で
/// 誤検知が出た。
///
/// **切り詰めはスクリーンショットで人が見る。** 機械には frame の実測だけ任せる。
enum LayoutInspector {
    /// 検出したレイアウトの問題
    struct Issue: CustomStringConvertible {
        enum Kind: String {
            case outOfBounds = "画面外にはみ出している"
        }

        let kind: Kind
        let identifier: String
        let detail: String

        var description: String {
            "[\(kind.rawValue)] \(identifier): \(detail)"
        }
    }

    /// 画面内の要素を走査して問題を返す。
    ///
    static func inspect(_ app: XCUIApplication) -> [Issue] {
        let window = app.windows.firstMatch
        guard window.exists else { return [] }
        let bounds = window.frame

        return outOfBoundsIssues(in: app, bounds: bounds)
    }

    // MARK: - 画面外へのはみ出し

    private static func outOfBoundsIssues(in app: XCUIApplication, bounds: CGRect) -> [Issue] {
        var issues: [Issue] = []

        for element in visibleTextElements(in: app) {
            let frame = element.frame
            // 高さ0の要素はレイアウト対象外（非表示扱い）
            guard frame.height > 0, frame.width > 0 else { continue }

            // 左右のはみ出しだけを見る。縦はスクロールで隠れているだけのことが多く、
            // それを崩れとして数えると誤検知だらけになる。
            if frame.minX < bounds.minX - 1 || frame.maxX > bounds.maxX + 1 {
                issues.append(Issue(
                    kind: .outOfBounds,
                    identifier: describe(element),
                    detail: "x=\(Int(frame.minX))...\(Int(frame.maxX)) / 画面幅 \(Int(bounds.width))"
                ))
            }
        }
        return issues
    }

    // MARK: -

    /// 判定対象にするテキスト要素。
    /// 画像やコンテナは対象外で、文字が入るものだけを見る。
    private static func visibleTextElements(in app: XCUIApplication) -> [XCUIElement] {
        var elements: [XCUIElement] = []
        for query in [app.staticTexts, app.buttons] {
            elements += query.allElementsBoundByIndex.filter(\.exists)
        }
        return elements
    }

    /// 失敗メッセージ用の表示名。identifier が無ければラベルで代用する。
    private static func describe(_ element: XCUIElement) -> String {
        let id = element.identifier
        if !id.isEmpty { return id }
        let label = element.label
        return label.isEmpty ? "(無名の要素)" : "\"\(label.prefix(30))\""
    }
}

extension XCTestCase {
    /// レイアウトを検査し、問題があればテストを失敗させる。
    func assertNoLayoutIssues(
        _ app: XCUIApplication,
        context: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let issues = LayoutInspector.inspect(app)
        guard !issues.isEmpty else { return }

        let detail = issues.map { "  \($0)" }.joined(separator: "\n")
        XCTFail("\(context) でレイアウトの問題:\n\(detail)", file: file, line: line)
    }
}
