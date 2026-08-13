import MapKit
@testable import SerendipityPlanner
import XCTest

/// スポット検索のカテゴリ定義（#34: 日本語キーワード → POI カテゴリ移行）のテスト。
final class PlaceSearchCategoryTests: XCTestCase {
    // MARK: - 検索手段の網羅

    /// どのカテゴリも検索手段を持っていること。
    /// POI カテゴリもキーワードも無いカテゴリがあると、その提案は必ずスポット無しになる。
    func testEveryCategoryHasSearchStrategy() {
        for category in SuggestionCategory.allCases {
            XCTAssertTrue(
                category.hasAnySearchStrategy,
                "\(category.rawValue) に検索手段がない（POI カテゴリもキーワードも空）"
            )
        }
    }

    /// 大半のカテゴリは POI カテゴリだけで賄えること（言語非依存で動く範囲を担保する）
    func testMostCategoriesAreLanguageIndependent() {
        let keywordOnly = SuggestionCategory.allCases.filter(\.pointOfInterestCategories.isEmpty)

        // iOS 15 の SDK には `.musicVenue` / `.spa` が無いため、music と meditation だけは
        // キーワードに頼らざるを得ない。`.nightlife` / `.theater` で近似する案は、
        // 丸の内の実測で「レコードショップ巡り」にバーが出たため採らない。
        // ここが増えるなら移行方針の見直しが要る。
        XCTAssertEqual(keywordOnly, [.music, .meditation])
    }

    // MARK: - 補助キーワード

    /// POI カテゴリで表現しきれないカテゴリには補助キーワードがあること
    func testSupplementalQueriesExistWhereCategoriesAreInsufficient() {
        XCTAssertFalse(SuggestionCategory.meditation.supplementalQueries.isEmpty)
        XCTAssertFalse(SuggestionCategory.reading.supplementalQueries.isEmpty)
        XCTAssertFalse(SuggestionCategory.music.supplementalQueries.isEmpty)
    }

    /// POI カテゴリで足りているカテゴリは補助キーワードを持たないこと（無駄な検索を投げない）
    func testNoSupplementalQueriesWhereCategoriesSuffice() {
        for category in [SuggestionCategory.cafe, .walk, .art, .fitness, .shopping, .gourmet, .movie] {
            XCTAssertTrue(
                category.supplementalQueries.isEmpty,
                "\(category.rawValue) は POI カテゴリで足りるのに補助キーワードを持っている"
            )
        }
    }

    // MARK: - ロケール解決

    func testLocalizedQuerySetReturnsMatchingLanguage() {
        let set = LocalizedQuerySet(byLanguage: ["en": ["temple"], "ja": ["お寺"]])

        XCTAssertEqual(set.queries(for: "ja"), ["お寺"])
        XCTAssertEqual(set.queries(for: "en"), ["temple"])
    }

    /// 未対応言語（ko / es / fr は #36 で追加予定）は英語にフォールバックすること。
    /// 日本語にフォールバックすると、スペイン語環境で日本語クエリが飛ぶことになる。
    func testLocalizedQuerySetFallsBackToEnglish() {
        let set = LocalizedQuerySet(byLanguage: ["en": ["temple"], "ja": ["お寺"]])

        XCTAssertEqual(set.queries(for: "ko"), ["temple"])
        XCTAssertEqual(set.queries(for: "es"), ["temple"])
        XCTAssertEqual(set.queries(for: "fr"), ["temple"])
    }

    /// 英語すら無い表は空を返す（クラッシュも日本語混入もしない）
    func testLocalizedQuerySetWithoutEnglishReturnsEmpty() {
        let set = LocalizedQuerySet(byLanguage: ["ja": ["お寺"]])

        XCTAssertEqual(set.queries(for: "fr"), [])
    }

    /// 実際の補助キーワード表が、すべて英語エントリを持つこと。
    /// これが無いと未対応言語（ko / es / fr）で検索が空振りする。
    func testAllSupplementalTablesProvideEnglish() {
        for (category, set) in SuggestionCategory.supplementalQueryTable {
            XCTAssertFalse(
                set.queries(for: "en").isEmpty,
                "\(category.rawValue) の表に英語エントリが無い（未対応言語で空振りする）"
            )
            XCTAssertFalse(
                set.queries(for: "zz").isEmpty,
                "\(category.rawValue) が未知の言語コードで空を返す"
            )
        }
    }

    // MARK: - おすすめエリアのクエリ

    /// おすすめエリアのクエリがロケール対応になっていること（日本語ハードコードの除去）
    func testRecommendationQueriesAreLocalized() {
        XCTAssertEqual(
            RecommendationQueries.table.queries(for: "ja"),
            ["観光スポット", "名所", "公園"]
        )
        XCTAssertEqual(
            RecommendationQueries.table.queries(for: "en"),
            ["tourist attraction", "landmark", "park"]
        )
    }

    /// 対応言語はそれぞれ固有のクエリを持つこと（#45 で ko/es/fr を追加）
    func testRecommendationQueriesExistForEveryTargetLanguage() {
        for code in ["ja", "ko", "es", "fr"] {
            let queries = RecommendationQueries.table.queries(for: code)
            XCTAssertFalse(queries.isEmpty, "\(code) のクエリが無い")
            XCTAssertNotEqual(queries, RecommendationQueries.table.queries(for: "en"), "\(code) が英語のまま")
        }
    }

    /// 未対応言語は英語にフォールバックすること（日本語クエリが飛ばないこと）
    func testRecommendationQueriesFallBackToEnglishForUnsupported() {
        XCTAssertEqual(RecommendationQueries.table.queries(for: "zz"), ["tourist attraction", "landmark", "park"])
    }

    /// 旅行先での取りこぼしを減らすため、端末言語に英語を併用すること。
    /// ko 端末のままパリへ行くと "레코드샵" が現地の店名に当たらず0件になるため。
    func testQueriesIncludeEnglishAlongsideDeviceLanguage() {
        let resolved = RecommendationQueries.queries(for: "ko")

        XCTAssertTrue(resolved.contains("랜드마크"), "\(resolved)")
        XCTAssertTrue(resolved.contains("landmark"), "英語が併用されていない: \(resolved)")
        // 端末言語が先（現地語を優先して探す）
        XCTAssertLessThan(
            resolved.firstIndex(of: "랜드마크") ?? .max,
            resolved.firstIndex(of: "landmark") ?? .max
        )
    }

    /// 英語端末では英語だけが重複なく返ること
    func testEnglishDeviceGetsNoDuplicates() {
        let resolved = RecommendationQueries.queries(for: "en")

        XCTAssertEqual(resolved, ["tourist attraction", "landmark", "park"])
    }

    /// 日本語エントリが失われていないこと（移行によるデグレ防止）。
    /// 英語を併用するようになったので「含むこと」で検証する。
    func testJapaneseQueriesPreserved() {
        let meditation = SuggestionCategory.meditation.supplementalQueryValues(for: "ja")
        for word in ["お寺", "神社", "庭園"] {
            XCTAssertTrue(meditation.contains(word), "\(word) が失われている: \(meditation)")
        }

        let reading = SuggestionCategory.reading.supplementalQueryValues(for: "ja")
        for word in ["書店", "ブックカフェ"] {
            XCTAssertTrue(reading.contains(word), "\(word) が失われている: \(reading)")
        }
    }

    /// 配信対象4言語すべてに固有のキーワードがあること（#45）。
    /// 英語しか無いと、その言語圏で現地の POI 名に当たらない。
    func testEveryTargetLanguageHasOwnKeywords() {
        for category in [SuggestionCategory.reading, .music, .meditation] {
            let english = SuggestionCategory.supplementalQueryTable[category]?.queries(for: "en") ?? []
            for code in ["ja", "ko", "es", "fr"] {
                let own = SuggestionCategory.supplementalQueryTable[category]?.queries(for: code) ?? []
                XCTAssertFalse(own.isEmpty, "\(category.rawValue) の \(code) が空")
                XCTAssertNotEqual(own, english, "\(category.rawValue) の \(code) が英語のまま")
            }
        }
    }
}
