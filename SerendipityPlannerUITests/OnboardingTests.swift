import XCTest

/// オンボーディングの通し確認。
///
/// 通常のテストは `-uiTestSkipOnboarding` で飛ばしているため、ここだけは
/// 実際に5ステップを踏む。
final class OnboardingTests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    /// 権限が既に決まっている状態でも最終ページから進めること。
    ///
    /// ## 直したバグ
    ///
    /// `requestPermission()` は権限が `.notDetermined` のときしかダイアログを
    /// 出さない。既に許可/拒否が決まっているとダイアログもデリゲート呼び出しも
    /// 起きないため、`locationAuthorizationResolved` の変化を待つだけの実装では
    /// **ボタンを押しても何も起きず、永久に進めなくなっていた**。
    ///
    /// アプリを削除して入れ直したときに起きる。アプリのデータ（オンボーディング
    /// 完了フラグ）は消えるが、iOS 側が権限の記録を保持していることがあるため。
    /// スキップ導線が無いので、踏むとアプリを消す以外に脱出できない。
    ///
    /// このテストは権限が付与済みのシミュレーターで走る前提。CI では
    /// まっさらなので `.notDetermined` 側の経路を通る。どちらでも完了できることを見る。
    func testCanFinishOnboardingWhenPermissionsAlreadyDecided() {
        let app = UITestSupport.launch(.japanese, skipOnboarding: false, stubData: false)

        // 1ページ目（ようこそ）
        let nextButton = app.buttons[AccessibilityID.onboardingNextButton]
        waitForElement(nextButton, timeout: 20)

        // 興味選択は3つ以上選ばないと進めない
        nextButton.tap()
        selectInterestsIfNeeded(in: app)

        // 残りのページを順に進める。権限ダイアログが出た場合は許可する
        for _ in 0 ..< 4 {
            guard nextButton.exists, nextButton.isEnabled else { break }
            nextButton.tap()
            allowPermissionDialogIfPresent(in: app)
        }

        // 完了してメイン画面に着いていること
        let homeTab = app.buttons[AccessibilityID.tabHome]
        XCTAssertTrue(
            homeTab.waitForExistence(timeout: 20),
            "オンボーディングが完了しなかった（最終ページで止まっている可能性）"
        )
        attachScreenshot(app, name: "onboarding_completed")
    }

    // MARK: -

    /// 興味選択ページなら3つ選ぶ。他のページなら何もしない。
    private func selectInterestsIfNeeded(in app: XCUIApplication) {
        let page = app.otherElements[AccessibilityID.onboardingPage(1)]
        guard page.waitForExistence(timeout: 10) else { return }

        // カテゴリのボタンを先頭から3つ選ぶ
        let candidates = app.buttons.allElementsBoundByIndex.filter {
            $0.identifier != AccessibilityID.onboardingNextButton && $0.isHittable
        }
        for button in candidates.prefix(3) {
            button.tap()
        }
    }

    /// システムの権限ダイアログが出ていたら許可する。
    /// 既に決着済みなら出ないので、その場合は何もしない。
    private func allowPermissionDialogIfPresent(in app: XCUIApplication) {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        // 権限の種類でボタンの並びが違う。位置情報は3択（1度だけ / 使用中 / 許可しない）で、
        // カレンダーは「フルアクセスを許可」。表示言語は端末設定に従う。
        let allowLabels = [
            "アプリの使用中は許可", "Allow While Using App",
            "フルアクセスを許可", "Allow Full Access",
            "許可", "Allow"
        ]
        for label in allowLabels {
            let button = springboard.buttons[label]
            if button.waitForExistence(timeout: 3) {
                button.tap()
                return
            }
        }
        _ = app.wait(for: .runningForeground, timeout: 2)
    }
}
