import XCTest

/// 土台が機能することを確かめる最小のテスト。
///
/// 主要動線の網羅は #37 で行う。ここでは「XCUITest で5言語を切り替えて
/// 要素を掴めること」だけを担保する。
final class LocalizationSmokeTests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    /// 5言語すべてでホーム画面が立ち上がること。
    ///
    /// identifier は翻訳されないので、同じコードがどの言語でも通る。
    /// これが成立しないなら #37 の全画面検証も成立しない。
    func testHomeLaunchesInEveryLanguage() {
        for locale in UITestSupport.Locale.all {
            let app = UITestSupport.launch(locale)

            // タブバーはどの画面でも出ているので、起動できたかの判定に使う
            let homeTab = app.buttons[AccessibilityID.tabHome]
            waitForElement(homeTab)

            attachScreenshot(app, name: "home_\(locale.slug)")
            app.terminate()
        }
    }

    /// タブを移動できること。座標ではなく identifier で指していることの確認も兼ねる。
    func testCanSwitchTabs() {
        let app = UITestSupport.launch(.japanese)

        for id in [AccessibilityID.tabHistory, AccessibilityID.tabFavorites, AccessibilityID.tabSettings] {
            let tab = app.buttons[id]
            waitForElement(tab)
            tab.tap()
        }

        // Form の中の個々の行はスクロールしないと掴めないため、画面ルートで判定する
        waitForElement(app.otherElements[AccessibilityID.screenSettings])
    }

    /// 翻訳が実際に画面へ出ていること。
    ///
    /// ユニットテストは `.strings` を読むだけなので、
    /// 「カタログには入っているが画面に出ていない」は検出できない。
    func testTranslatedTextAppearsOnScreen() {
        let expectations: [(UITestSupport.Locale, String)] = [
            (.english, "Pick a destination"),
            (.korean, "목적지 정하기"),
            (.spanish, "Elegir un destino"),
            (.french, "Choisir une destination")
        ]

        for (locale, expected) in expectations {
            let app = UITestSupport.launch(locale)
            let card = app.buttons[AccessibilityID.destinationCard]
            waitForElement(card)

            XCTAssertTrue(
                card.label.contains(expected),
                "\(locale.slug): 目的地カードに「\(expected)」が出ていない（実際: \(card.label)）"
            )
            app.terminate()
        }
    }
}
