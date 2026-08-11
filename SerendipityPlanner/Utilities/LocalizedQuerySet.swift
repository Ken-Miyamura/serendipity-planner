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
}
