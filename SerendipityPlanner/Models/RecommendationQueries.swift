import Foundation

/// 目的地検索シートの「おすすめエリア」抽出に使うクエリ。
///
/// ここだけは POI カテゴリ方式を採らない。`MKLocalPointsOfInterestRequest` は半径を広げても
/// **最寄りの十数件しか返さない**ため、東京駅で試すと 145〜304m の館内展示ばかりが並び、
/// 「行き先」として機能しなかった（実測）。離れた行き先を出すには広域のキーワード検索が要る。
///
/// そのため言語非依存にはできず、ロケール別のキーワード表で対応する。
/// ko / es / fr は #36（翻訳投入）で追加する。
enum RecommendationQueries {
    static let table = LocalizedQuerySet(byLanguage: [
        "en": ["tourist attraction", "landmark", "park"],
        "ja": ["観光スポット", "名所", "公園"]
    ])

    static var current: [String] {
        table.queries(for: Locale.currentLanguageCode)
    }
}
