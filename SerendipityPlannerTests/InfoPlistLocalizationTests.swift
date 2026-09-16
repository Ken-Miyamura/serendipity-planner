@testable import SerendipityPlanner
import XCTest

/// #37: 権限ダイアログの本文（`NS...UsageDescription`）が5言語に翻訳されていること。
///
/// ダイアログを描くのはシステムで、言語は**端末の言語設定**で決まる。
/// アプリの起動引数では切り替わらないため、UI テストで5言語ぶん出すことはできない
/// （`PermissionDialogTests` の注記を参照）。
/// 翻訳が入っているかどうかはここで見る。
final class InfoPlistLocalizationTests: XCTestCase {
    private let languages = ["ja", "en", "ko", "es", "fr"]

    /// アプリが実際に使う利用目的のキー
    private let keys = [
        "NSCalendarsUsageDescription",
        "NSCalendarsFullAccessUsageDescription",
        "NSLocationWhenInUseUsageDescription"
    ]

    /// 全言語ぶんの InfoPlist が bundle に入っていること
    func testInfoPlistStringsExistForEveryLanguage() throws {
        for language in languages {
            let path = try XCTUnwrap(
                Bundle.main.path(forResource: language, ofType: "lproj"),
                "\(language).lproj が無い"
            )
            let bundle = try XCTUnwrap(Bundle(path: path))
            XCTAssertNotNil(
                bundle.url(forResource: "InfoPlist", withExtension: "strings"),
                "\(language) の InfoPlist.strings が無い"
            )
        }
    }

    /// 各キーがどの言語でも解決され、キー名がそのまま返っていないこと
    func testEveryUsageDescriptionResolves() throws {
        for language in languages {
            let bundle = try bundle(language)
            for key in keys {
                let value = bundle.localizedString(forKey: key, value: nil, table: "InfoPlist")
                XCTAssertNotEqual(value, key, "\(language) の \(key) が未翻訳")
                XCTAssertFalse(value.isEmpty, "\(language) の \(key) が空")
            }
        }
    }

    /// 日本語以外に日本語が残っていないこと。
    /// 未翻訳のまま放置すると、海外ユーザーの権限ダイアログが日本語で出る。
    func testNonJapaneseUsageDescriptionsAreTranslated() throws {
        for language in languages where language != "ja" {
            let bundle = try bundle(language)
            for key in keys {
                let value = bundle.localizedString(forKey: key, value: nil, table: "InfoPlist")
                XCTAssertFalse(
                    containsJapaneseScript(value),
                    "\(language) の \(key) が日本語のまま: \(value)"
                )
            }
        }
    }

    // MARK: -

    private func bundle(_ language: String) throws -> Bundle {
        let path = try XCTUnwrap(
            Bundle.main.path(forResource: language, ofType: "lproj"),
            "\(language).lproj が無い"
        )
        return try XCTUnwrap(Bundle(path: path))
    }

    private func containsJapaneseScript(_ text: String) -> Bool {
        text.unicodeScalars.contains { scalar in
            (0x3040 ... 0x309F).contains(scalar.value)
                || (0x30A0 ... 0x30FF).contains(scalar.value)
                || (0x4E00 ... 0x9FFF).contains(scalar.value)
        }
    }
}
