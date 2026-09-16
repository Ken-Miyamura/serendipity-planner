import XCTest

/// オンボーディング5ステップのレイアウトを5言語で確認する。
///
/// 通常のテストは `-uiTestSkipOnboarding` で飛ばしているため、ここだけ実際に踏む。
/// 権限まわりはスタブに差し替えてシステムのダイアログを出さない
/// （ダイアログ自体は `PermissionDialogTests` で別に撮る）。
final class OnboardingLayoutTests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = true
    }

    /// 5ページすべてを順に撮る。
    ///
    /// 各ページで文言量が大きく違う（ようこそは短く、権限説明は長い）ため、
    /// 通しで撮らないと崩れる箇所が分からない。
    func testOnboardingPagesInEveryLanguage() {
        for locale in UITestSupport.Locale.all {
            let app = UITestSupport.launch(locale, skipOnboarding: false)

            let nextButton = app.buttons[AccessibilityID.onboardingNextButton]
            guard nextButton.waitForExistence(timeout: 30) else {
                XCTFail("\(locale.slug): オンボーディングが始まらなかった")
                app.terminate()
                continue
            }

            for page in 0 ..< 5 {
                guard element(app, AccessibilityID.onboardingPage(page)).waitForExistence(timeout: 15) else {
                    XCTFail("\(locale.slug): オンボーディング \(page) ページ目が出なかった")
                    break
                }
                attachScreenshot(app, name: "20_onboarding-\(page)_\(locale.slug)")
                assertNoLayoutIssues(app, context: "\(locale.slug) オンボーディング \(page)")

                // 興味選択（1ページ目）は3つ選ばないと次へ進めない
                if page == 1 {
                    selectInterests(in: app)
                }
                // 最終ページで押すと完了してしまうので、撮り終えたら抜ける
                guard page < 4 else { break }

                XCTAssertTrue(
                    nextButton.isEnabled,
                    "\(locale.slug): \(page) ページ目で次へ進めない"
                )
                nextButton.tap()
            }

            app.terminate()
        }
    }

    /// 興味選択で3つ選ぶ。
    private func selectInterests(in app: XCUIApplication) {
        let candidates = app.buttons.allElementsBoundByIndex.filter {
            $0.identifier != AccessibilityID.onboardingNextButton && $0.isHittable
        }
        for button in candidates.prefix(3) {
            button.tap()
        }
    }
}
