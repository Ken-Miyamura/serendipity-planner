@testable import SerendipityPlanner
import XCTest

/// #37: 通知の実文言を5言語で検証する。
///
/// 通知はアプリの画面と違い、出たところをスクリーンショットで押さえるのが難しい。
/// 代わりに**配信される文字列そのもの**を言語別に取り出して見る。
/// `NotificationService` も同じ `NotificationContent` を使うため、ここが通れば
/// 実際に飛ぶ文言も同じものになる。
final class NotificationContentTests: XCTestCase {
    private let locales = ["ja", "en", "ko", "es", "fr"]

    /// 言語別の bundle。どの翻訳を引くかを決めるのは locale ではなく bundle。
    private func bundle(_ language: String) throws -> Bundle {
        let path = try XCTUnwrap(
            Bundle.main.path(forResource: language, ofType: "lproj"),
            "\(language).lproj が無い"
        )
        return try XCTUnwrap(Bundle(path: path))
    }

    private var sampleSuggestion: Suggestion {
        let slot = FreeTimeSlot(
            startDate: Date(timeIntervalSince1970: 1_700_000_000),
            endDate: Date(timeIntervalSince1970: 1_700_007_200)
        )
        return Suggestion(
            category: .cafe,
            title: "テスト",
            description: "テスト",
            duration: 60,
            freeTimeSlot: slot,
            weatherContext: ""
        )
    }

    // MARK: - 全言語で解決されること

    /// どの言語でも空文字にならないこと。
    /// カタログにキーが無いと空が返るため、翻訳漏れがここで出る。
    func testAllLocalesResolveNonEmpty() throws {
        for identifier in locales {
            let locale = Locale(identifier: identifier)
            let bundle = try bundle(identifier)
            let suggestion = NotificationContent.suggestion(sampleSuggestion, bundle: bundle, locale: locale)
            let morning = NotificationContent.morning(freeSlotCount: 3, bundle: bundle, locale: locale)

            XCTAssertFalse(suggestion.title.isEmpty, "\(identifier): 提案通知のタイトルが空")
            XCTAssertFalse(suggestion.body.isEmpty, "\(identifier): 提案通知の本文が空")
            XCTAssertFalse(morning.title.isEmpty, "\(identifier): 朝の通知のタイトルが空")
            XCTAssertFalse(morning.body.isEmpty, "\(identifier): 朝の通知の本文が空")
        }
    }

    /// 日本語以外で日本語のまま出ていないこと。
    ///
    /// 翻訳が入っていないとカタログは**キー（日本語）をそのまま返す**。
    /// 空チェックだけでは素通りするため、仮名・漢字が残っていないかで見る。
    func testNonJapaneseLocalesAreActuallyTranslated() throws {
        for identifier in locales where identifier != "ja" {
            let locale = Locale(identifier: identifier)
            let bundle = try bundle(identifier)
            let texts = [
                NotificationContent.suggestion(sampleSuggestion, bundle: bundle, locale: locale).title,
                NotificationContent.morning(freeSlotCount: 3, bundle: bundle, locale: locale).title,
                NotificationContent.morning(freeSlotCount: 3, bundle: bundle, locale: locale).body
            ]
            for text in texts {
                XCTAssertFalse(
                    containsJapaneseScript(text),
                    "\(identifier): 日本語のまま出ている: \(text)"
                )
            }
        }
    }

    /// 件数が本文に反映されること。
    /// プレースホルダを落とした翻訳が入ると、件数が消えて意味が通らなくなる。
    func testMorningBodyContainsCount() throws {
        for identifier in locales {
            let locale = Locale(identifier: identifier)
            let body = try NotificationContent.morning(freeSlotCount: 7, bundle: bundle(identifier), locale: locale).body
            XCTAssertTrue(body.contains("7"), "\(identifier): 件数が本文に無い: \(body)")
        }
    }

    /// 提案のタイトルが本文に載ること。
    func testSuggestionBodyContainsTitle() throws {
        for identifier in locales {
            let locale = Locale(identifier: identifier)
            let body = try NotificationContent.suggestion(sampleSuggestion, bundle: bundle(identifier), locale: locale).body
            XCTAssertTrue(body.contains("テスト"), "\(identifier): 提案タイトルが本文に無い: \(body)")
        }
    }

    // MARK: -

    /// 仮名・漢字を含むか。ハングルや欧文だけなら false。
    private func containsJapaneseScript(_ text: String) -> Bool {
        text.unicodeScalars.contains { scalar in
            (0x3040 ... 0x309F).contains(scalar.value) // ひらがな
                || (0x30A0 ... 0x30FF).contains(scalar.value) // カタカナ
                || (0x4E00 ... 0x9FFF).contains(scalar.value) // 漢字
        }
    }
}
