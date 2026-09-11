import Foundation

/// 言語コードごとの検索キーワード。未対応言語は英語にフォールバックする。
///
/// ユーザーに見せる文言ではなく検索ロジックの一部なので、String Catalog ではなく
/// コードで管理する。ko / es / fr の追加は #36。
struct LocalizedQuerySet {
    /// 言語コード → キーワード。`en` は未対応言語のフォールバックとして必須。
    let byLanguage: [String: [String]]

    func queries(for languageCode: String) -> [String] {
        byLanguage[languageCode] ?? byLanguage["en"] ?? []
    }

    /// 端末言語のキーワードに英語を加えたもの（重複は除く、端末言語が先）。
    ///
    /// キーワードは端末の言語に従うが、**旅行先では現地の POI 名に当たらない**。
    /// 実測で、韓国語端末のままパリ／マドリードに行くと music が0件になった
    /// （"레코드샵" はフランスの店名に一致しない）。
    ///
    /// 英語は主要都市で広く通じることを実測で確認しているため
    /// （record store: ソウル1 / マドリード1 / パリ3 / 東京3件）、
    /// 端末言語に英語を足して取りこぼしを減らす。
    func queriesWithEnglishFallback(for languageCode: String) -> [String] {
        let primary = queries(for: languageCode)
        let english = byLanguage["en"] ?? []
        return primary + english.filter { !primary.contains($0) }
    }
}
