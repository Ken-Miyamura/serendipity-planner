import XCTest

/// #37: 5言語 × 全画面のレイアウト検証。
///
/// 日本語は文字数あたりの情報密度が高く、同じ内容がスペイン語・フランス語では
/// 1.3〜2倍の長さになる。日本語前提で組んだレイアウトは翻訳を入れた時点で
/// 崩れる可能性が高い。
///
/// ## 方針
///
/// - 機械が判定できるもの（はみ出し・途切れ）は `LayoutInspector` に任せる
/// - スクリーンショットは全画面 × 全言語で撮り、テスト結果に添付する
/// - **確認できなかった画面は明示的に報告する**（握りつぶさない）
final class LayoutVerificationTests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = true // 1言語で落ちても残りを見たい
    }

    // MARK: - 主要動線

    /// ホーム → 提案詳細 → マップシート を5言語で辿る。
    /// #36 から引き継いだ「主要動線の確認」がこれにあたる。
    func testMainFlowInEveryLanguage() {
        for locale in UITestSupport.Locale.all {
            let app = UITestSupport.launch(locale)

            // --- ホーム ---
            // タブバーは読み込み中も出ているので、それを待つだけだと
            // ローディング画面を撮ってしまう。提案カードが出るまで待つ。
            let card = app.buttons[AccessibilityID.suggestionCard(0)]
            let contentLoaded = card.waitForExistence(timeout: 30)

            attachScreenshot(app, name: "01_home_\(locale.slug)")
            assertNoLayoutIssues(app, context: "\(locale.slug) ホーム")

            // --- 提案詳細 ---
            if contentLoaded {
                card.tap()
                if app.buttons[AccessibilityID.detailAcceptButton].waitForExistence(timeout: 10) {
                    attachScreenshot(app, name: "02_detail_\(locale.slug)")
                    assertNoLayoutIssues(app, context: "\(locale.slug) 提案詳細")

                    // --- マップアプリ選択シート ---
                    // マップボタンは周辺スポットがある時だけ出る。素通りを許すと、
                    // スポットが取れなかった言語でシートを一度も開かないまま
                    // テストが緑になる。スタブで必ず出る前提なので、無ければ失敗させる。
                    let mapButton = app.buttons[AccessibilityID.detailMapButton]
                    if mapButton.waitForExistence(timeout: 10) {
                        mapButton.tap()
                        if app.buttons[AccessibilityID.mapPickerApp(0)].waitForExistence(timeout: 10) {
                            attachScreenshot(app, name: "03_mapPicker_\(locale.slug)")
                            assertNoLayoutIssues(app, context: "\(locale.slug) マップ選択シート")
                        } else {
                            XCTFail("\(locale.slug): マップ選択シートの中身が出なかった")
                        }
                    } else {
                        XCTFail("\(locale.slug): 周辺スポットが出ずマップボタンを確認できなかった")
                    }
                } else {
                    XCTFail("\(locale.slug): 提案詳細に遷移できなかった")
                }
            } else {
                XCTFail("\(locale.slug): 提案カードが出なかった")
            }

            app.terminate()
        }
    }

    // MARK: - タブ配下の画面

    /// 履歴 / お気に入り / 設定 を5言語で確認する。
    func testTabScreensInEveryLanguage() {
        let tabs: [(String, String, String)] = [
            (AccessibilityID.tabHistory, AccessibilityID.screenHistory, "history"),
            (AccessibilityID.tabFavorites, AccessibilityID.screenFavorites, "favorites"),
            (AccessibilityID.tabSettings, AccessibilityID.screenSettings, "settings")
        ]

        for locale in UITestSupport.Locale.all {
            let app = UITestSupport.launch(locale)
            waitForElement(app.buttons[AccessibilityID.tabHome])

            for (tabID, screenID, name) in tabs {
                app.buttons[tabID].tap()
                guard app.otherElements[screenID].waitForExistence(timeout: 10) else {
                    XCTFail("\(locale.slug): \(name) に遷移できなかった")
                    continue
                }
                attachScreenshot(app, name: "04_\(name)_\(locale.slug)")
                assertNoLayoutIssues(app, context: "\(locale.slug) \(name)")
            }

            app.terminate()
        }
    }

    // MARK: - 目的地検索シート

    func testDestinationSearchInEveryLanguage() {
        for locale in UITestSupport.Locale.all {
            let app = UITestSupport.launch(locale)

            let card = app.buttons[AccessibilityID.destinationCard]
            guard card.waitForExistence(timeout: 20) else {
                XCTFail("\(locale.slug): 目的地カードが出なかった")
                app.terminate()
                continue
            }
            card.tap()

            guard app.buttons[AccessibilityID.destinationUseCurrentLocation].waitForExistence(timeout: 10) else {
                XCTFail("\(locale.slug): 目的地検索シートの中身が出なかった")
                app.terminate()
                continue
            }
            attachScreenshot(app, name: "05_destinationSearch_\(locale.slug)")
            assertNoLayoutIssues(app, context: "\(locale.slug) 目的地検索")

            app.terminate()
        }
    }

    // MARK: - タブバー

    /// タブバーは4項目が等幅で並ぶ。アイコンのみなので文字では崩れないが、
    /// 画面幅が狭い端末で見切れないことを確認する。
    func testTabBarFitsInEveryLanguage() {
        for locale in UITestSupport.Locale.all {
            let app = UITestSupport.launch(locale)
            waitForElement(app.buttons[AccessibilityID.tabHome])

            let window = app.windows.firstMatch.frame
            for index in 0 ..< 4 {
                let tab = app.buttons[AccessibilityID.tab(index)]
                XCTAssertTrue(tab.exists, "\(locale.slug): タブ \(index) が無い")
                let frame = tab.frame
                XCTAssertGreaterThanOrEqual(
                    frame.minX, window.minX - 1,
                    "\(locale.slug): タブ \(index) が左にはみ出している"
                )
                XCTAssertLessThanOrEqual(
                    frame.maxX, window.maxX + 1,
                    "\(locale.slug): タブ \(index) が右にはみ出している"
                )
            }

            app.terminate()
        }
    }
}
