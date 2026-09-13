@testable import SerendipityPlanner
import XCTest

/// #32: String Catalog 化の検証。
final class StringCatalogTests: XCTestCase {
    /// 配信対象の5言語がバンドルに宣言されていること。
    /// ここが欠けると、その言語の端末では翻訳を入れても選ばれない。
    func testBundleDeclaresTargetLocalizations() {
        let declared = Set(Bundle.main.localizations)

        for code in ["ja", "en", "ko", "es", "fr"] {
            XCTAssertTrue(declared.contains(code), "\(code) が CFBundleLocalizations に無い: \(declared)")
        }
    }

    /// 開発言語が ja のままであること
    func testDevelopmentLocalizationIsJapanese() {
        XCTAssertEqual(Bundle.main.developmentLocalization, "ja")
    }

    /// String Catalog が実際に引けること（ja の値が返ること）。
    /// カタログがビルドに含まれていないと、キーがそのまま返るのではなく
    /// 参照している文字列が壊れる形で表面化するため、代表キーで疎通を見る。
    func testCatalogResolvesJapaneseValues() throws {
        // プロセスのロケールに依存しないよう ja.lproj を明示して引く。
        // String(localized:) は端末設定に従うため、en で実行すると英語が返る。
        let path = try XCTUnwrap(Bundle.main.path(forResource: "ja", ofType: "lproj"))
        let ja = try XCTUnwrap(Bundle(path: path))

        XCTAssertEqual(ja.localizedString(forKey: "今日", value: nil, table: nil), "今日")
        XCTAssertEqual(ja.localizedString(forKey: "明日", value: nil, table: nil), "明日")
        XCTAssertEqual(ja.localizedString(forKey: "カフェ", value: nil, table: nil), "カフェ")
        XCTAssertEqual(ja.localizedString(forKey: "晴れ", value: nil, table: nil), "晴れ")
        XCTAssertEqual(ja.localizedString(forKey: "Apple マップ", value: nil, table: nil), "Apple マップ")
    }

    // MARK: - 英語翻訳（#36）

    /// 代表的なキーが英語で解決されること。
    /// カタログに en が入っていないとキー（＝日本語）がそのまま返る。
    func testEnglishTranslationsResolve() throws {
        let path = try XCTUnwrap(Bundle.main.path(forResource: "en", ofType: "lproj"))
        let englishBundle = try XCTUnwrap(Bundle(path: path))

        XCTAssertEqual(englishBundle.localizedString(forKey: "今日", value: nil, table: nil), "Today")
        XCTAssertEqual(englishBundle.localizedString(forKey: "設定", value: nil, table: nil), "Settings")
        XCTAssertEqual(englishBundle.localizedString(forKey: "お気に入り", value: nil, table: nil), "Favorites")
    }

    /// 韓国語が解決されること（#36）
    func testKoreanTranslationsResolve() throws {
        let path = try XCTUnwrap(Bundle.main.path(forResource: "ko", ofType: "lproj"))
        let ko = try XCTUnwrap(Bundle(path: path))

        XCTAssertEqual(ko.localizedString(forKey: "今日", value: nil, table: nil), "오늘")
        XCTAssertEqual(ko.localizedString(forKey: "設定", value: nil, table: nil), "설정")
        XCTAssertEqual(ko.localizedString(forKey: "お気に入り", value: nil, table: nil), "즐겨찾기")
    }

    /// 訳に日本語が残っていないこと（訳し忘れの検出）。
    /// 固有名詞（Serendipity など）は原文と同じでよいので、日本語文字の有無で見る。
    func testNoJapaneseLeftInTranslations() throws {
        // 固有名詞（Serendipity など）は原文と同じでよいので、日本語文字の有無で見る
        let japanese = try NSRegularExpression(pattern: "[\\p{Hiragana}\\p{Katakana}\\p{Han}]")

        for lang in translatedLanguages {
            let url = try XCTUnwrap(
                Bundle.main.url(forResource: "Localizable", withExtension: "strings", subdirectory: "\(lang).lproj"),
                "\(lang).lproj が無い"
            )
            let dict = try XCTUnwrap(NSDictionary(contentsOf: url) as? [String: String])

            let leftovers = dict.filter { _, value in
                japanese.firstMatch(in: value, range: NSRange(value.startIndex..., in: value)) != nil
            }
            XCTAssertTrue(leftovers.isEmpty, "\(lang) の訳に日本語が残っている: \(leftovers.keys.sorted())")
        }
    }

    /// 翻訳済みの言語すべてで、キーの取りこぼしが無いこと
    func testNoMissingKeysInTranslations() throws {
        let jaPath = try XCTUnwrap(Bundle.main.path(forResource: "ja", ofType: "lproj"))
        let jaURL = try XCTUnwrap(URL(string: "file://" + jaPath + "/Localizable.strings"))
        let jaKeys = try Set(XCTUnwrap(NSDictionary(contentsOf: jaURL) as? [String: String]).keys)

        for lang in translatedLanguages {
            let url = try XCTUnwrap(
                Bundle.main.url(forResource: "Localizable", withExtension: "strings", subdirectory: "\(lang).lproj")
            )
            let keys = try Set(XCTUnwrap(NSDictionary(contentsOf: url) as? [String: String]).keys)
            XCTAssertTrue(jaKeys.subtracting(keys).isEmpty, "\(lang) に未訳キー: \(jaKeys.subtracting(keys).sorted())")
        }
    }

    /// 翻訳を投入済みの言語。新しい言語を入れたらここに足す。
    private var translatedLanguages: [String] {
        ["en", "ko"]
    }

    // MARK: - 翻訳後に壊れるロジックの防止

    /// 権限エラーの「設定を開く」導線が、文言ではなく状態で決まること。
    /// 以前は errorMessage に "許可" が含まれるかで判定しており、翻訳すると成立しなくなっていた。
    @MainActor
    func testSettingsPromptDrivenByStateNotText() {
        let viewModel = HomeViewModel()

        XCTAssertFalse(
            viewModel.errorRequiresSettings,
            "初期状態で「設定を開く」導線が出る判定になっている"
        )
    }

    /// オンボーディングの権限エラーが、どの権限のものかを型で持つこと。
    /// 以前は "カレンダー" / "通知" という語が含まれるかで振り分けており、
    /// 翻訳した時点でエラー表示が出なくなっていた。
    ///
    /// カレンダー側だけ直して通知側を見落とした経緯があるので、**両方**を通す。
    @MainActor
    func testCalendarPermissionDenialSetsCalendarKind() async {
        let calendar = MockCalendarService()
        calendar.requestAccessResult = false
        let viewModel = OnboardingViewModel(
            calendarService: calendar,
            notificationService: MockNotificationService()
        )

        await viewModel.requestCalendarPermission()

        XCTAssertNotNil(viewModel.permissionError)
        XCTAssertEqual(viewModel.permissionErrorKind, .calendar)
    }

    @MainActor
    func testNotificationPermissionDenialSetsNotificationKind() async {
        let notification = MockNotificationService()
        notification.requestPermissionResult = false
        let viewModel = OnboardingViewModel(
            calendarService: MockCalendarService(),
            notificationService: notification
        )

        await viewModel.requestNotificationPermission()

        XCTAssertNotNil(viewModel.permissionError)
        XCTAssertEqual(viewModel.permissionErrorKind, .notification)
    }

    /// 権限要求をやり直したら前回の種別が残らないこと
    @MainActor
    func testPermissionKindResetsOnRetry() async {
        let calendar = MockCalendarService()
        calendar.requestAccessResult = false
        let viewModel = OnboardingViewModel(
            calendarService: calendar,
            notificationService: MockNotificationService()
        )

        await viewModel.requestCalendarPermission()
        XCTAssertEqual(viewModel.permissionErrorKind, .calendar)

        calendar.requestAccessResult = true
        await viewModel.requestCalendarPermission()
        XCTAssertNil(viewModel.permissionErrorKind)
    }
}
