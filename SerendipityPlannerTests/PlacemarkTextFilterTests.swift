@testable import SerendipityPlanner
import XCTest

/// #29: Apple のジオデータ欠損で subtitle の表記が混ざる問題のフォールバック。
final class PlacemarkTextFilterTests: XCTestCase {
    // MARK: - 日本語端末

    /// 日本語端末では日本語の地名をそのまま出すこと
    func testJapaneseDeviceKeepsJapaneseText() {
        XCTAssertTrue(PlacemarkTextFilter.matchesDeviceLanguage("東京都", languageCode: "ja"))
        XCTAssertTrue(PlacemarkTextFilter.matchesDeviceLanguage("東京都 港区", languageCode: "ja"))
        XCTAssertEqual(PlacemarkTextFilter.displayable("島根県", languageCode: "ja"), "島根県")
    }

    /// 日本語端末に英語データが返ってきたら落とすこと（#29 の報告事象）
    func testJapaneseDeviceDropsEnglishText() {
        XCTAssertFalse(PlacemarkTextFilter.matchesDeviceLanguage("Tokyo", languageCode: "ja"))
        XCTAssertFalse(PlacemarkTextFilter.matchesDeviceLanguage("Tokyo Chiyoda-Ku", languageCode: "ja"))
        XCTAssertFalse(PlacemarkTextFilter.matchesDeviceLanguage("Kyoto Kita-Ku, Kyoto", languageCode: "ja"))
        XCTAssertNil(PlacemarkTextFilter.displayable("Tokyo", languageCode: "ja"))
    }

    // MARK: - 英語端末（ここが「ASCII なら落とす」案との違い）

    /// 英語端末では英語の地名を残すこと。
    /// ロケール非依存に「英字を落とす」ルールにすると、ここが全滅する。
    func testEnglishDeviceKeepsEnglishText() {
        XCTAssertTrue(PlacemarkTextFilter.matchesDeviceLanguage("Tokyo", languageCode: "en"))
        XCTAssertTrue(PlacemarkTextFilter.matchesDeviceLanguage("Tokyo Chiyoda-Ku", languageCode: "en"))
        XCTAssertEqual(PlacemarkTextFilter.displayable("Kyoto Kita-Ku, Kyoto", languageCode: "en"), "Kyoto Kita-Ku, Kyoto")
    }

    /// 英語端末に日本語データが返ってきたら落とすこと（混在は逆向きにも起きる）
    func testEnglishDeviceDropsJapaneseText() {
        XCTAssertFalse(PlacemarkTextFilter.matchesDeviceLanguage("東京都 台東区", languageCode: "en"))
        XCTAssertNil(PlacemarkTextFilter.displayable("島根県 出雲市", languageCode: "en"))
    }

    // MARK: - その他の配信対象言語

    /// スペイン語・フランス語はラテン文字なので英語表記を許容すること
    func testLatinScriptLanguagesAcceptLatinText() {
        XCTAssertTrue(PlacemarkTextFilter.matchesDeviceLanguage("Tokyo", languageCode: "es"))
        XCTAssertTrue(PlacemarkTextFilter.matchesDeviceLanguage("Tokyo", languageCode: "fr"))
        XCTAssertFalse(PlacemarkTextFilter.matchesDeviceLanguage("東京都", languageCode: "fr"))
    }

    /// アクセント付き文字をラテン文字として扱うこと（Málaga などを落とさない）
    func testAccentedLatinIsTreatedAsLatin() {
        XCTAssertTrue(PlacemarkTextFilter.matchesDeviceLanguage("Málaga", languageCode: "es"))
        XCTAssertTrue(PlacemarkTextFilter.matchesDeviceLanguage("Île-de-France", languageCode: "fr"))
        XCTAssertFalse(PlacemarkTextFilter.matchesDeviceLanguage("Île-de-France", languageCode: "ja"))
    }

    /// 韓国語はラテン文字以外を期待すること
    func testKoreanExpectsNonLatin() {
        XCTAssertTrue(PlacemarkTextFilter.matchesDeviceLanguage("서울특별시", languageCode: "ko"))
        XCTAssertFalse(PlacemarkTextFilter.matchesDeviceLanguage("Seoul", languageCode: "ko"))
    }

    // MARK: - 判定材料が無いケース

    /// 数字・記号だけのテキストは判定できないので落とさないこと
    func testNonLetterTextIsKept() {
        XCTAssertTrue(PlacemarkTextFilter.matchesDeviceLanguage("1-2-3", languageCode: "ja"))
        XCTAssertTrue(PlacemarkTextFilter.matchesDeviceLanguage("100", languageCode: "en"))
    }

    /// 空・nil は表示対象にしないこと
    func testEmptyIsNotDisplayable() {
        XCTAssertNil(PlacemarkTextFilter.displayable(nil, languageCode: "ja"))
        XCTAssertNil(PlacemarkTextFilter.displayable("", languageCode: "ja"))
    }
}
