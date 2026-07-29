import Foundation
import MapKit

/// 目的地検索の候補（座標は未解決）。
///
/// `MKLocalSearchCompletion` は座標を持たないため、検索候補の表示と座標の解決は2段構えになる。
/// 候補を選んだタイミングで `DestinationSearchViewModel.resolve(_:)` が
/// `MKLocalSearch` を通して座標を取得し、`TodayDestination` へ変換する。
struct DestinationCandidate: Identifiable {
    let id = UUID()
    /// 候補の主表示（例: "東京タワー"）
    let title: String
    /// 候補の補足（例: "東京都港区芝公園４丁目"）
    let subtitle: String
    /// 座標解決に使う元の補完結果
    let completion: MKLocalSearchCompletion

    init(completion: MKLocalSearchCompletion) {
        self.title = completion.title
        self.subtitle = Self.displaySubtitle(from: completion.subtitle)
        self.completion = completion
    }

    /// 補完結果の subtitle は「〒150-0042, 東京都渋谷区, 宇田川町15-1」のように
    /// 郵便番号から始まる。行き先の目印としては不要なので落として読みやすくする。
    ///
    /// 〒 を必須にしているのは日本以外の住所を壊さないため。数字だけを条件にすると
    /// 「12345678 Main St」のような先頭が長い番地の住所で番地を削ってしまう。
    /// 郵便番号が末尾に来る国では何も削らず、そのまま表示する。
    private static func displaySubtitle(from raw: String) -> String {
        guard let range = raw.range(of: #"^〒\s*\d{3}-?\d{4},?\s*"#, options: .regularExpression) else {
            return raw
        }
        return String(raw[range.upperBound...])
    }
}
