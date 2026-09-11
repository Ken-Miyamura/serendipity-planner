import Foundation

/// 目的地検索シートの「おすすめエリア」抽出に使うクエリ。
///
/// ここだけは POI カテゴリ方式を採らない。`MKLocalPointsOfInterestRequest` は半径を広げても
/// **最寄りの十数件しか返さない**ため、東京駅で試すと 145〜304m の館内展示ばかりが並び、
/// 「行き先」として機能しなかった（実測）。離れた行き先を出すには広域のキーワード検索が要る。
///
/// そのため言語非依存にはできず、ロケール別のキーワード表で対応する。
enum RecommendationQueries {
    static let table = LocalizedQuerySet(byLanguage: [
        "en": ["tourist attraction", "landmark", "park"],
        "ja": ["観光スポット", "名所", "公園"],
        // ソウル実測: 관광명소 は0件、명소 も1件。랜드마크(16) / 관광지(4) が有効
        "ko": ["랜드마크", "관광지", "공원"],
        "es": ["atracción turística", "monumento", "parque"],
        "fr": ["attraction touristique", "monument", "parc"]
    ])

    static var current: [String] {
        queries(for: Locale.currentLanguageCode)
    }

    /// 指定した言語でのクエリ（テストから言語を差し替えるための入口）。
    /// 補助キーワードと同じく、旅行先での取りこぼしを減らすため英語を併用する。
    static func queries(for languageCode: String) -> [String] {
        table.queriesWithEnglishFallback(for: languageCode)
    }
}
