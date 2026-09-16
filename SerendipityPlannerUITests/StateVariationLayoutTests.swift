import XCTest

/// #37 の残りスコープ: 状態バリエーションと、主要動線から外れた画面のレイアウト検証。
///
/// `LayoutVerificationTests` が見ているのは**提案が出ている正常系**だけ。
/// 空状態・エラー・読込中の文言は正常系より長くなりがちで、崩れるのはむしろこちら側。
/// イシューでも「状態バリエーションを飛ばさないこと」と明記している。
final class StateVariationLayoutTests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = true // 1言語で落ちても残りを見たい
    }

    // MARK: - ホームの状態バリエーション

    /// 空き時間なし / 権限拒否 / 取得失敗 / 読込中 を5言語で確認する。
    func testHomeStateVariationsInEveryLanguage() {
        // 待つ対象の要素が状態ごとに違う。ここで対にしておく
        let states: [(UITestScenario, String, String)] = [
            (.empty, AccessibilityID.homeEmptyState, "empty"),
            (.denied, AccessibilityID.screenErrorState, "denied"),
            (.error, AccessibilityID.screenErrorState, "error"),
            (.loading, AccessibilityID.homeLoading, "loading")
        ]

        for locale in UITestSupport.Locale.all {
            for (scenario, waitFor, name) in states {
                let app = UITestSupport.launch(locale, scenario: scenario)
                guard element(app, waitFor).waitForExistence(timeout: 30) else {
                    XCTFail("\(locale.slug): ホームの \(name) 状態が出なかった")
                    app.terminate()
                    continue
                }
                attachScreenshot(app, name: "10_home-\(name)_\(locale.slug)")
                assertNoLayoutIssues(app, context: "\(locale.slug) ホーム(\(name))")
                app.terminate()
            }
        }
    }

    /// 権限拒否のときだけ「設定を開く」が出ること。
    ///
    /// 取得失敗との違いがここ。ボタンが2つ縦に並ぶぶん文字が長い言語で崩れやすいので、
    /// 出ていること自体を明示的に押さえる。
    func testDeniedStateOffersSettingsShortcut() {
        for locale in UITestSupport.Locale.all {
            let app = UITestSupport.launch(locale, scenario: .denied)
            guard element(app, AccessibilityID.screenErrorState).waitForExistence(timeout: 30) else {
                XCTFail("\(locale.slug): エラー状態が出なかった")
                app.terminate()
                continue
            }
            // ラベルは言語ごとに変わるため、ボタンの数で見る（再試行 + 設定を開く）
            XCTAssertGreaterThanOrEqual(
                app.buttons.allElementsBoundByIndex.filter(\.isHittable).count, 2,
                "\(locale.slug): 権限拒否なのに「設定を開く」が見当たらない"
            )
            app.terminate()
        }
    }

    // MARK: - データがある一覧と、その詳細

    /// 履歴・お気に入りに行が並んだ状態と、お気に入り詳細を5言語で確認する。
    ///
    /// 空状態は `LayoutVerificationTests` 側で撮れている。行が並んだときの
    /// 折り返しと、詳細への遷移はデータが無いと一切検証できない。
    func testSeededListScreensInEveryLanguage() {
        for locale in UITestSupport.Locale.all {
            let app = UITestSupport.launch(locale, scenario: .seeded)
            waitForElement(app.buttons[AccessibilityID.tabHome], timeout: 30)

            // --- 履歴（データあり） ---
            app.buttons[AccessibilityID.tabHistory].tap()
            if element(app, AccessibilityID.screenHistory).waitForExistence(timeout: 15) {
                attachScreenshot(app, name: "11_history-filled_\(locale.slug)")
                assertNoLayoutIssues(app, context: "\(locale.slug) 履歴(データあり)")
            } else {
                XCTFail("\(locale.slug): 履歴に遷移できなかった")
            }

            // --- お気に入り（データあり） ---
            app.buttons[AccessibilityID.tabFavorites].tap()
            guard element(app, AccessibilityID.screenFavorites).waitForExistence(timeout: 15) else {
                XCTFail("\(locale.slug): お気に入りに遷移できなかった")
                app.terminate()
                continue
            }
            attachScreenshot(app, name: "12_favorites-filled_\(locale.slug)")
            assertNoLayoutIssues(app, context: "\(locale.slug) お気に入り(データあり)")

            // --- お気に入り詳細 ---
            let row = app.buttons[AccessibilityID.favoriteRow(0)]
            if row.waitForExistence(timeout: 10) {
                row.tap()
                if element(app, AccessibilityID.screenFavoriteDetail).waitForExistence(timeout: 15) {
                    attachScreenshot(app, name: "13_favoriteDetail_\(locale.slug)")
                    assertNoLayoutIssues(app, context: "\(locale.slug) お気に入り詳細")
                } else {
                    XCTFail("\(locale.slug): お気に入り詳細に遷移できなかった")
                }
            } else {
                XCTFail("\(locale.slug): お気に入りの行が出なかった（投入データが効いていない）")
            }

            app.terminate()
        }
    }

    // MARK: - 通知設定

    /// 設定 → 通知設定 を5言語で確認する。
    /// トグルのラベルが長い言語で、スイッチと重ならないかを見る。
    func testNotificationSettingsInEveryLanguage() {
        for locale in UITestSupport.Locale.all {
            let app = UITestSupport.launch(locale)
            waitForElement(app.buttons[AccessibilityID.tabSettings], timeout: 30)
            app.buttons[AccessibilityID.tabSettings].tap()

            guard element(app, AccessibilityID.screenSettings).waitForExistence(timeout: 15) else {
                XCTFail("\(locale.slug): 設定に遷移できなかった")
                app.terminate()
                continue
            }

            let link = app.buttons[AccessibilityID.settingsNotificationLink]
            guard link.waitForExistence(timeout: 10) else {
                XCTFail("\(locale.slug): 通知設定への導線が見つからなかった")
                app.terminate()
                continue
            }
            link.tap()

            if element(app, AccessibilityID.screenNotificationSettings).waitForExistence(timeout: 15) {
                attachScreenshot(app, name: "14_notificationSettings_\(locale.slug)")
                assertNoLayoutIssues(app, context: "\(locale.slug) 通知設定")
            } else {
                XCTFail("\(locale.slug): 通知設定に遷移できなかった")
            }

            app.terminate()
        }
    }

    // MARK: - ウィジェット

    /// ウィジェットのレイアウトを5言語で確認する。
    ///
    /// ホーム画面への配置は自動化が壊れやすいため、同じビューを同じ寸法の枠で
    /// アプリ側に描いて撮る（`WidgetGalleryView` を参照）。見たいのは文字が枠に
    /// 収まるかで、WidgetKit の配信そのものではない。
    func testWidgetLayoutInEveryLanguage() {
        for locale in UITestSupport.Locale.all {
            let app = UITestSupport.launch(locale, scenario: .widget)
            guard element(app, AccessibilityID.screenWidgetGallery).waitForExistence(timeout: 30) else {
                XCTFail("\(locale.slug): ウィジェット一覧が出なかった")
                app.terminate()
                continue
            }
            attachScreenshot(app, name: "15_widget_\(locale.slug)")

            // 枠からはみ出していないかを枠ごとに見る。
            // 画面全体で見ると、枠の外にある余白まで許容範囲に入ってしまう。
            for name in ["small", "small.empty", "medium", "medium.empty"] {
                let container = element(app, AccessibilityID.widgetPreview(name))
                XCTAssertTrue(container.exists, "\(locale.slug): ウィジェット \(name) が無い")
                // 枠が取れていないと判定が意味をなさないので、幅を先に確かめる
                XCTAssertGreaterThan(
                    container.frame.width, 100,
                    "\(locale.slug): ウィジェット \(name) の枠が取れていない (\(container.frame))"
                )
                assertTextFits(in: container, app: app, context: "\(locale.slug) widget \(name)")
            }

            app.terminate()
        }
    }

    /// 枠の中のテキストが枠に収まっているか。
    private func assertTextFits(
        in container: XCUIElement,
        app: XCUIApplication,
        context: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard container.exists else { return }
        let bounds = container.frame
        for text in app.staticTexts.allElementsBoundByIndex where text.exists {
            let frame = text.frame
            guard frame.height > 0, frame.width > 0 else { continue }
            // この枠に属するものだけを見る（縦方向の重なりで判定する）
            guard frame.midY >= bounds.minY, frame.midY <= bounds.maxY else { continue }
            XCTAssertTrue(
                frame.minX >= bounds.minX - 1 && frame.maxX <= bounds.maxX + 1,
                "\(context): 「\(text.label.prefix(30))」が枠からはみ出している "
                    + "(x=\(Int(frame.minX))...\(Int(frame.maxX)) / 枠 \(Int(bounds.minX))...\(Int(bounds.maxX)))",
                file: file, line: line
            )
        }
    }
}
