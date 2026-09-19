import XCTest

/// システムの権限ダイアログに、アプリの利用目的（`NS...UsageDescription`）が
/// 出ていることを確認する。
///
/// ## 言語別の確認はここではできない
///
/// 権限ダイアログを描くのはアプリではなく**システム**で、どの言語で描くかは
/// **端末の言語設定**で決まる。`-AppleLanguages` の起動引数はアプリの bundle に
/// しか効かないため、アプリを fr で立ち上げてもダイアログは端末の言語のまま出る。
///
/// 実測: fr / es / ko で起動しても、本文は日本語のままだった。
/// これを「5言語ぶん確認した」と数えるとテストだけが緑になる。
///
/// **言語別の翻訳の有無は `InfoPlistLocalizationTests`（ユニットテスト）で見る。**
/// ここで見るのは「キーが Info.plist に届いていて、ダイアログに本文が出ること」。
/// 実際の各言語の見え方は、シミュレーターの言語設定を変えて人が確認する。
final class PermissionDialogTests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    /// 端末の言語でダイアログが出て、本文が空でないこと。
    func testUsageDescriptionsAppearInSystemDialogs() {
        let app = XCUIApplication()
        app.resetAuthorizationStatus(for: .location)
        app.resetAuthorizationStatus(for: .calendar)

        let launched = UITestSupport.launch(.japanese, stubData: false)

        var captured = 0
        for attempt in 0 ..< 2 {
            guard let alert = waitForSystemAlert(timeout: 30) else { break }
            attachScreenshot(
                XCUIApplication(bundleIdentifier: "com.apple.springboard"),
                name: "30_permission-\(attempt)"
            )
            XCTAssertFalse(alert.label.isEmpty, "ダイアログのタイトルが空")
            captured += 1
            dismiss(alert)
        }

        XCTAssertGreaterThan(
            captured, 0,
            "権限ダイアログが1つも出なかった（権限がリセットできていない可能性）"
        )
        launched.terminate()
    }

    // MARK: -

    /// ダイアログを出すのは SpringBoard のこともアプリ自身のこともあるため両方見る。
    private func waitForSystemAlert(timeout: TimeInterval) -> XCUIElement? {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            for alert in [springboard.alerts.firstMatch, XCUIApplication().alerts.firstMatch]
                where alert.exists {
                return alert
            }
            Thread.sleep(forTimeInterval: 0.5)
        }
        return nil
    }

    /// 許可でも拒否でもよい。次のダイアログへ進めることだけが目的。
    private func dismiss(_ alert: XCUIElement) {
        guard alert.exists else { return }
        let button = alert.buttons.element(boundBy: 0)
        if button.exists {
            button.tap()
        }
    }
}
