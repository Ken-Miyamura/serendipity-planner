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

    // MARK: - 通常状態の画面（1言語につき1起動でまとめて歩く）

    /// 目的地検索シート / 履歴 / お気に入り / 設定 / 通知設定 と、タブバーの収まりを見る。
    ///
    /// ## なぜ1つのテストにまとめているか
    ///
    /// これらはすべて**同じ状態のアプリ**を見ている。画面ごとにテストを分けると、
    /// 同じ起動を言語の数だけ繰り返すことになる。
    /// UI テストの所要時間の7割はアプリの起動待ちで、5言語 × 4テスト = 20起動が
    /// 5起動に減る。見ている内容は分かれていたときと同じ。
    ///
    /// 途中で落ちても残りを見たいので `continueAfterFailure` は true のまま。
    func testStandardScreensInEveryLanguage() {
        for locale in UITestSupport.Locale.all {
            let app = UITestSupport.launch(locale)

            let destinationCard = app.buttons[AccessibilityID.destinationCard]
            guard destinationCard.waitForExistence(timeout: 30) else {
                XCTFail("\(locale.slug): ホームが立ち上がらなかった")
                app.terminate()
                continue
            }

            assertTranslationReachedScreen(destinationCard, locale: locale)
            assertTabBarFits(app, locale: locale)
            walkDestinationSearch(app, locale: locale, from: destinationCard)
            walkTabScreens(app, locale: locale)
            walkNotificationSettings(app, locale: locale)

            app.terminate()
        }
    }

    // MARK: -

    /// 翻訳が画面に出ていること。
    /// ユニットテストは `.strings` を読むだけなので、
    /// 「カタログには入っているが画面に出ていない」は検出できない。
    private func assertTranslationReachedScreen(
        _ destinationCard: XCUIElement,
        locale: UITestSupport.Locale
    ) {
        guard let expected = locale.translatedSample else { return }
        XCTAssertTrue(
            destinationCard.label.contains(expected),
            "\(locale.slug): 目的地カードに「\(expected)」が出ていない（実際: \(destinationCard.label)）"
        )
    }

    /// タブバーは4項目が等幅で並ぶ。アイコンのみなので文字では崩れないが、
    /// 画面幅が狭い端末で見切れないことを確認する。
    private func assertTabBarFits(_ app: XCUIApplication, locale: UITestSupport.Locale) {
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
    }

    private func walkDestinationSearch(
        _ app: XCUIApplication,
        locale: UITestSupport.Locale,
        from card: XCUIElement
    ) {
        card.tap()
        guard app.buttons[AccessibilityID.destinationUseCurrentLocation].waitForExistence(timeout: 15) else {
            XCTFail("\(locale.slug): 目的地検索シートの中身が出なかった")
            return
        }
        attachScreenshot(app, name: "05_destinationSearch_\(locale.slug)")
        assertNoLayoutIssues(app, context: "\(locale.slug) 目的地検索")

        // 次の画面へ進むためシートを閉じる。開いたままだとタブが押せない
        let close = app.buttons[AccessibilityID.destinationCloseButton]
        if close.exists {
            close.tap()
        }
        XCTAssertTrue(
            card.waitForExistence(timeout: 10),
            "\(locale.slug): 目的地検索シートを閉じられなかった"
        )
    }

    private func walkTabScreens(_ app: XCUIApplication, locale: UITestSupport.Locale) {
        let tabs: [(String, String, String)] = [
            (AccessibilityID.tabHistory, AccessibilityID.screenHistory, "history"),
            (AccessibilityID.tabFavorites, AccessibilityID.screenFavorites, "favorites"),
            (AccessibilityID.tabSettings, AccessibilityID.screenSettings, "settings")
        ]

        for (tabID, screenID, name) in tabs {
            app.buttons[tabID].tap()
            guard element(app, screenID).waitForExistence(timeout: 15) else {
                XCTFail("\(locale.slug): \(name) に遷移できなかった")
                continue
            }
            attachScreenshot(app, name: "04_\(name)_\(locale.slug)")
            assertNoLayoutIssues(app, context: "\(locale.slug) \(name)")
        }
    }

    /// 設定の続き。トグルのラベルが長い言語で、スイッチと重ならないかを見る。
    /// 直前に設定画面まで来ている前提。
    private func walkNotificationSettings(_ app: XCUIApplication, locale: UITestSupport.Locale) {
        let link = app.buttons[AccessibilityID.settingsNotificationLink]
        guard link.waitForExistence(timeout: 15) else {
            XCTFail("\(locale.slug): 通知設定への導線が見つからなかった")
            return
        }
        link.tap()

        guard element(app, AccessibilityID.screenNotificationSettings).waitForExistence(timeout: 15) else {
            XCTFail("\(locale.slug): 通知設定に遷移できなかった")
            return
        }
        attachScreenshot(app, name: "14_notificationSettings_\(locale.slug)")
        assertNoLayoutIssues(app, context: "\(locale.slug) 通知設定")
    }
}
