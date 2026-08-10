import MapKit

/// 言語に依存しないスポット検索のためのカテゴリ定義。
///
/// 以前は日本語キーワード（"カフェ" / "銭湯" など）を `MKLocalSearch.naturalLanguageQuery` に
/// 渡していたが、これは日本語環境でしか成立しない。「銭湯」を翻訳してもスペインに銭湯は無いため、
/// キーワードを訳すのではなく `MKPointOfInterestCategory` という言語非依存の軸に載せ替える。
///
/// ただし deploymentTarget が iOS 15 のため、使えるカテゴリは iOS 13 世代の39種に限られる
/// （`.spa` / `.musicVenue` は iOS 18 で追加。書店に相当するカテゴリは現行 SDK に存在しない）。
/// カテゴリで表現しきれない分だけ `supplementalQueries` でキーワード検索を併用する。
extension SuggestionCategory {
    /// カテゴリ検索に使う POI カテゴリ。言語非依存で、これが主たる検索手段。
    var pointOfInterestCategories: [MKPointOfInterestCategory] {
        switch self {
        case .cafe: [.cafe]
        case .walk: [.park, .nationalPark, .beach]
        case .reading: [.library]
        case .art: [.museum]
        case .fitness: [.fitnessCenter]
        case .shopping: [.store]
        case .gourmet: [.restaurant, .brewery, .winery]
        case .movie: [.movieTheater]
        // 音楽・瞑想に対応する POI カテゴリが無い（`.musicVenue` / `.spa` は iOS 18 以降）。
        // `.nightlife` や `.theater` で近似するとバーや劇場が大量に混ざって提案の質が落ちるため、
        // 実測（丸の内で「レコードショップ巡り」に IL BAR が出た）を踏まえて使わない。
        // この2分類はキーワード検索のみで賄う。
        case .music, .meditation: []
        }
    }

    /// POI カテゴリで表現しきれない分を補うキーワード。
    ///
    /// 端末の言語設定に対応する表が無ければ英語にフォールバックする。ここはユーザーに見せる文言では
    /// なく検索ロジックの一部なので、String Catalog ではなくコードで管理する。
    var supplementalQueries: [String] {
        supplementalQueryValues(for: Locale.currentLanguageCode)
    }

    /// 指定した言語コードでの補助キーワード（テストから言語を差し替えるための入口）
    func supplementalQueryValues(for languageCode: String) -> [String] {
        Self.supplementalQueryTable[self]?.queries(for: languageCode) ?? []
    }

    /// カテゴリ検索とキーワード検索のどちらも手段が無いカテゴリは存在してはいけない。
    var hasAnySearchStrategy: Bool {
        !pointOfInterestCategories.isEmpty || !supplementalQueries.isEmpty
    }

    // MARK: - キーワード表

    /// 言語コード → 補助キーワード。`en` は未対応言語のフォールバックとして必須。
    ///
    /// ko / es / fr は #36（翻訳投入）で追加する。それまでは英語版が使われる。
    static let supplementalQueryTable: [SuggestionCategory: LocalizedQuerySet] = [
        // `.library` は図書館しか拾わないため、書店・ブックカフェを補う
        .reading: LocalizedQuerySet(byLanguage: [
            "en": ["bookstore", "book cafe"],
            "ja": ["書店", "ブックカフェ"]
        ]),
        // 対応する POI カテゴリが無いため、音楽に寄せた語で拾う
        .music: LocalizedQuerySet(byLanguage: [
            "en": ["record store", "live music"],
            "ja": ["レコードショップ", "ライブハウス"]
        ]),
        // 該当カテゴリが無いので、この分類はキーワードだけが頼り。
        // "スパ" は「Bar Español」のような無関係な店に誤マッチしたため使わない。
        .meditation: LocalizedQuerySet(byLanguage: [
            "en": ["temple", "shrine", "meditation"],
            "ja": ["お寺", "神社", "庭園"]
        ])
    ]
}

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

/// 言語コードごとの検索キーワード。未対応言語は英語にフォールバックする。
struct LocalizedQuerySet {
    let byLanguage: [String: [String]]

    func queries(for languageCode: String) -> [String] {
        byLanguage[languageCode] ?? byLanguage["en"] ?? []
    }
}

extension Locale {
    /// 端末の言語コード（"ja" / "en" など）。地域やスクリプトは含まない。
    static var currentLanguageCode: String {
        if #available(iOS 16.0, *) {
            return Locale.current.language.languageCode?.identifier ?? "en"
        }
        return Locale.current.languageCode ?? "en"
    }
}
