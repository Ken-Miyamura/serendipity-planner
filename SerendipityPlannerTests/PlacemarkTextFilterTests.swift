@testable import SerendipityPlanner
import XCTest

/// #29: Apple のジオデータ欠損で subtitle の表記が混ざる問題のフォールバック。
///
/// 判定は「端末の言語」ではなく「その一覧の多数派」を基準にする。
/// 端末言語で絶対判定すると、ja データがほぼ無い海外で地域名が全滅する。
final class PlacemarkTextFilterTests: XCTestCase {
    // MARK: - 表記体系の判定

    func testScriptDetection() {
        XCTAssertEqual(PlacemarkTextFilter.script(of: "東京都"), .nonLatin)
        XCTAssertEqual(PlacemarkTextFilter.script(of: "서울특별시"), .nonLatin)
        XCTAssertEqual(PlacemarkTextFilter.script(of: "Tokyo"), .latin)
        XCTAssertEqual(PlacemarkTextFilter.script(of: "Île-de-France"), .latin)
        XCTAssertEqual(PlacemarkTextFilter.script(of: "Málaga"), .latin)
    }

    /// 混在表記は非ラテン扱いにすること（「東京都 港区 1丁目」等）
    func testMixedTextIsNonLatin() {
        XCTAssertEqual(PlacemarkTextFilter.script(of: "東京都 Minato"), .nonLatin)
    }

    /// 数字・記号だけは判定材料が無いので nil
    func testNonLetterTextHasNoScript() {
        XCTAssertNil(PlacemarkTextFilter.script(of: "1-2-3"))
        XCTAssertNil(PlacemarkTextFilter.script(of: ""))
    }

    // MARK: - 多数派の判定

    /// 国内: 日本語が多数派なので日本語が基準になる
    func testDominantScriptInJapan() {
        let texts = ["東京都", "東京都", "東京都", "東京都", "東京都", "Tokyo"]

        XCTAssertEqual(PlacemarkTextFilter.dominantScript(in: texts), .nonLatin)
    }

    /// 海外: ラテン文字が多数派なのでラテン文字が基準になる
    func testDominantScriptAbroad() {
        let texts = ["Île-de-France", "Île-de-France", "Paris", "Paris"]

        XCTAssertEqual(PlacemarkTextFilter.dominantScript(in: texts), .latin)
    }

    /// 同数のときは基準を決めない（落とす根拠が無い）
    func testTieHasNoDominantScript() {
        XCTAssertNil(PlacemarkTextFilter.dominantScript(in: ["東京都", "Tokyo"]))
    }

    /// 判定材料が無いときも基準を決めない
    func testNoDominantScriptWhenNoLetters() {
        XCTAssertNil(PlacemarkTextFilter.dominantScript(in: []))
        XCTAssertNil(PlacemarkTextFilter.dominantScript(in: ["123", "456"]))
    }

    // MARK: - 表示可否

    /// 国内: 多数派の日本語は残り、浮いた英語だけ落ちる（#29 の報告事象）
    func testDropsOutlierInJapaneseList() {
        let dominant = PlacemarkTextFilter.dominantScript(in: ["東京都", "東京都", "Tokyo"])

        XCTAssertTrue(PlacemarkTextFilter.isDisplayable("東京都", dominant: dominant))
        XCTAssertFalse(PlacemarkTextFilter.isDisplayable("Tokyo", dominant: dominant))
    }

    /// 海外: 全件ラテン文字なら何も落とさない。
    /// ここが端末言語での絶対判定との決定的な違いで、絶対判定だとパリで全滅していた。
    func testKeepsEverythingAbroad() {
        let texts = ["Île-de-France", "Paris", "Île-de-France", "Paris", "Paris", "Île-de-France"]
        let dominant = PlacemarkTextFilter.dominantScript(in: texts)

        for text in texts {
            XCTAssertTrue(
                PlacemarkTextFilter.isDisplayable(text, dominant: dominant),
                "海外で地域名が落ちている: \(text)"
            )
        }
    }

    /// 海外で1件だけ日本語データがある場合は、そちらが浮くので落ちる
    func testDropsJapaneseOutlierAbroad() {
        let dominant = PlacemarkTextFilter.dominantScript(in: ["Paris", "Paris", "パリ"])

        XCTAssertTrue(PlacemarkTextFilter.isDisplayable("Paris", dominant: dominant))
        XCTAssertFalse(PlacemarkTextFilter.isDisplayable("パリ", dominant: dominant))
    }

    /// 基準が決まらないときは落とさない（情報を減らすだけになるため）
    func testKeepsAllWhenNoDominant() {
        XCTAssertTrue(PlacemarkTextFilter.isDisplayable("東京都", dominant: nil))
        XCTAssertTrue(PlacemarkTextFilter.isDisplayable("Tokyo", dominant: nil))
    }

    /// 判定材料が無いテキストは基準があっても落とさない
    func testKeepsNonLetterText() {
        XCTAssertTrue(PlacemarkTextFilter.isDisplayable("1-2-3", dominant: .nonLatin))
    }
}
