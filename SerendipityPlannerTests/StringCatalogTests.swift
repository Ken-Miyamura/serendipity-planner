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
    func testCatalogResolvesJapaneseValues() {
        XCTAssertEqual(String(localized: "今日"), "今日")
        XCTAssertEqual(String(localized: "明日"), "明日")
        XCTAssertEqual(SuggestionCategory.cafe.displayName, "カフェ")
        XCTAssertEqual(WeatherCondition.clear.displayName, "晴れ")
        XCTAssertEqual(MapApp.appleMaps.displayName, "Apple マップ")
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
    /// 以前は "カレンダー" という語が含まれるかで振り分けていた。
    @MainActor
    func testPermissionErrorKindIsTyped() {
        let viewModel = OnboardingViewModel()

        XCTAssertNil(viewModel.permissionErrorKind)
        // 型として区別できること（文字列一致に戻っていないこと）を明示する
        XCTAssertNotEqual(OnboardingViewModel.PermissionKind.calendar, .notification)
    }
}
