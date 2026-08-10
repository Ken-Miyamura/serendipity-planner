@testable import SerendipityPlanner
import XCTest

/// #33: ロケール固定のハードコード除去の検証。
///
/// `Locale.current` 化でいちばん壊れやすいのが日付書式なので、ja / en の両方で
/// 「その言語として自然な表記になっているか」をここで担保する。
final class LocaleFormattingTests: XCTestCase {
    private let ja = Locale(identifier: "ja_JP")
    private let enUS = Locale(identifier: "en_US")
    private let frFR = Locale(identifier: "fr_FR")

    /// 2026-08-11 09:41 (火)
    private var sample: Date {
        var components = DateComponents()
        components.year = 2026
        components.month = 8
        components.day = 11
        components.hour = 9
        components.minute = 41
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return calendar.date(from: components)!
    }

    // MARK: - 日付書式

    /// 年月がロケールごとの並びになること。
    /// "yyyy年M月" を直書きしていた頃は英語ロケールでも「2026年8月」と出ていた。
    func testYearMonthFollowsLocale() {
        let jaText = DateFormatter.localized(template: "yMMMM", locale: ja).string(from: sample)
        let enText = DateFormatter.localized(template: "yMMMM", locale: enUS).string(from: sample)

        XCTAssertTrue(jaText.contains("2026"), jaText)
        XCTAssertTrue(jaText.contains("8月"), jaText)

        XCTAssertTrue(enText.contains("2026"), enText)
        XCTAssertTrue(enText.localizedCaseInsensitiveContains("august"), enText)
        // 英語表記に日本語の単位が混ざっていないこと
        XCTAssertFalse(enText.contains("年"), enText)
        XCTAssertFalse(enText.contains("月"), enText)
    }

    /// 曜日つきの日付が各ロケールで自然な表記になること
    func testMonthDayWeekdayFollowsLocale() {
        let jaText = DateFormatter.localized(template: "MMMdE", locale: ja).string(from: sample)
        let enText = DateFormatter.localized(template: "MMMdE", locale: enUS).string(from: sample)

        XCTAssertTrue(jaText.contains("8月"), jaText)
        XCTAssertFalse(enText.contains("月"), enText)
        XCTAssertFalse(enText.contains("日"), enText)
    }

    /// フランス語でも日本語の単位が混入しないこと（配信対象言語の確認）
    func testFrenchHasNoJapaneseUnits() {
        let text = DateFormatter.localized(template: "yMMMMd", locale: frFR).string(from: sample)

        XCTAssertFalse(text.contains("年"), text)
        XCTAssertFalse(text.contains("月"), text)
        XCTAssertFalse(text.contains("日"), text)
    }

    /// 時刻表記が 12/24 時間のロケール慣習に従うこと。
    /// "HH:mm" 直書きの頃は en-US でも 24 時間表記が強制されていた。
    func testTimeFormatFollowsLocaleConvention() {
        let jaText = DateFormatter.localizedTime(locale: ja).string(from: sample)
        let enText = DateFormatter.localizedTime(locale: enUS).string(from: sample)

        XCTAssertFalse(jaText.localizedCaseInsensitiveContains("am"), jaText)
        XCTAssertTrue(
            enText.localizedCaseInsensitiveContains("am") || enText.localizedCaseInsensitiveContains("pm"),
            "en-US で 12 時間表記になっていない: \(enText)"
        )
    }

    // MARK: - 単位

    /// 気温がロケールの単位系に従うこと（華氏圏で摂氏のまま出ない）
    func testTemperatureFollowsMeasurementSystem() {
        let jaText = LocalizedUnits.temperature(celsius: 24, locale: ja)
        let enText = LocalizedUnits.temperature(celsius: 24, locale: enUS)

        XCTAssertTrue(jaText.contains("24"), jaText)
        XCTAssertTrue(jaText.contains("C"), jaText)

        XCTAssertTrue(enText.contains("F"), "en-US で華氏になっていない: \(enText)")
        XCTAssertFalse(enText.contains("24"), "en-US で摂氏の数値がそのまま出ている: \(enText)")
    }

    /// 距離がロケールの単位系に従うこと
    func testDistanceFollowsMeasurementSystem() {
        let jaShort = LocalizedUnits.distance(meters: 300, locale: ja)
        let jaLong = LocalizedUnits.distance(meters: 2500, locale: ja)
        let enLong = LocalizedUnits.distance(meters: 2500, locale: enUS)

        XCTAssertTrue(jaShort.contains("300"), jaShort)
        XCTAssertTrue(jaShort.contains("m"), jaShort)
        XCTAssertTrue(jaLong.contains("km"), "1km 超でも km にならない: \(jaLong)")

        XCTAssertTrue(enLong.localizedCaseInsensitiveContains("mi"), "en-US でマイルにならない: \(enLong)")
    }

    // MARK: - 天気 API の言語

    /// OpenWeatherMap の独自コードに変換されること
    func testWeatherRequestLanguageMapsVendorCodes() {
        XCTAssertEqual(Constants.Weather.requestLanguage(for: "ko"), "kr")
        XCTAssertEqual(Constants.Weather.requestLanguage(for: "es"), "sp")
    }

    /// 対応言語はそのまま通ること
    func testWeatherRequestLanguagePassesSupported() {
        XCTAssertEqual(Constants.Weather.requestLanguage(for: "ja"), "ja")
        XCTAssertEqual(Constants.Weather.requestLanguage(for: "en"), "en")
        XCTAssertEqual(Constants.Weather.requestLanguage(for: "fr"), "fr")
    }

    /// 未対応言語は英語にフォールバックすること。
    /// 日本語のまま返すと、未対応言語の端末に日本語の天気説明が出てしまう。
    func testWeatherRequestLanguageFallsBackToEnglish() {
        XCTAssertEqual(Constants.Weather.requestLanguage(for: "zz"), "en")
        XCTAssertEqual(Constants.Weather.requestLanguage(for: ""), "en")
    }
}
