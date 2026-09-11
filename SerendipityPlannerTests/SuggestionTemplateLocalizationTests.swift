@testable import SerendipityPlanner
import XCTest

/// #35: 提案テンプレートをロケール別に差し替え可能にした件の検証。
///
/// 翻訳そのものは #36 で入る。ここで担保するのは**構造が壊れていないこと**。
final class SuggestionTemplateLocalizationTests: XCTestCase {
    // MARK: - テンプレートの枠

    /// 全カテゴリにテンプレートがあること。
    /// 1つでも欠けるとそのカテゴリは提案が生成されない。
    func testEveryCategoryHasTemplates() {
        for category in SuggestionCategory.allCases {
            XCTAssertFalse(
                SuggestionTemplates.templates(for: category).isEmpty,
                "\(category.rawValue) のテンプレートが無い"
            )
        }
    }

    /// テンプレート総数が変わっていないこと。
    /// String Catalog 化の作業でテンプレートを取りこぼしていないかの歯止め。
    func testTemplateCountUnchanged() {
        XCTAssertEqual(SuggestionTemplates.allTemplates.count, 29)
    }

    /// 文言が空でないこと。
    /// カタログにキーが無いと空文字が返る可能性があるため。
    func testNoEmptyTemplateText() {
        for template in SuggestionTemplates.allTemplates {
            XCTAssertFalse(template.title.isEmpty, "\(template.category.rawValue) の title が空")
            XCTAssertFalse(
                template.description.isEmpty,
                "\(template.category.rawValue) / \(template.title) の description が空"
            )
        }
    }

    /// テンプレートが日本語で解決されること（ja 環境でのデグレ防止）
    func testJapaneseTemplatesResolve() {
        let titles = SuggestionTemplates.templates(for: .cafe).map(\.title)

        XCTAssertTrue(titles.contains("近くのカフェでひと息"), "\(titles)")
    }

    // MARK: - 天気文脈のプレースホルダ

    /// 全カテゴリの3パターンすべてに `%@` が1つ含まれること。
    ///
    /// ここが落ちると天気の文脈が提案文から消える。翻訳時にプレースホルダを
    /// 落とすのはよくある事故なので、テストで固定する。
    func testWeatherContextKeepsPlaceholder() {
        for category in SuggestionCategory.allCases {
            let format = category.weatherContextFormat
            for (label, text) in [
                ("outdoor", format.outdoor), ("indoor", format.indoor), ("neutral", format.neutral)
            ] {
                XCTAssertEqual(
                    text.components(separatedBy: "%@").count - 1, 1,
                    "\(category.rawValue) の \(label) に %@ が1つ含まれていない: \(text)"
                )
            }
        }
    }

    /// 天気文脈が空でないこと
    func testWeatherContextNotEmpty() {
        for category in SuggestionCategory.allCases {
            let format = category.weatherContextFormat
            XCTAssertFalse(format.outdoor.isEmpty, "\(category.rawValue) outdoor")
            XCTAssertFalse(format.indoor.isEmpty, "\(category.rawValue) indoor")
            XCTAssertFalse(format.neutral.isEmpty, "\(category.rawValue) neutral")
        }
    }

    /// 天気語を差し込んだ結果に天気語が現れること（フォーマットが機能していること）
    func testWeatherContextFormatsActuallySubstitute() {
        let format = SuggestionCategory.cafe.weatherContextFormat
        let result = String(format: format.outdoor, "晴れ")

        XCTAssertTrue(result.contains("晴れ"), result)
        XCTAssertFalse(result.contains("%@"), result)
    }
}
