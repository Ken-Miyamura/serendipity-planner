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
