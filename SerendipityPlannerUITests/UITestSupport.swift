import XCTest

/// UI テストの共通土台。
///
/// ## なぜ XCUITest なのか
///
/// 以前は AppleScript で Simulator のウィンドウ座標を計算してタップしていたが、
/// ウィンドウ位置のずれ、System Events からウィンドウが見えなくなる、要素の列挙で
/// 接続が落ちる、といった事象を頻繁に踏んで #36 では主要動線まで到達できなかった。
///
/// XCUITest は座標ではなく**要素の identifier** で操作するため、これらが起きない。
enum UITestSupport {
    /// 検証対象の5言語。
    /// 言語コードと、その言語で使う代表的な地域・座標をまとめて持つ。
    struct Locale {
        let language: String
        let region: String
        /// この言語で目的地カードに出ているはずの文言。
        ///
        /// ユニットテストは `.strings` を読むだけなので「カタログには入っているが
        /// 画面に出ていない」を検出できない。画面を歩くついでにここで確かめる。
        /// ja は原文そのもので、翻訳の確認にならないため nil。
        let translatedSample: String?

        /// スクリーンショットのファイル名などに使う短い識別子
        var slug: String {
            "\(language)_\(region)"
        }

        static let japanese = Locale(language: "ja", region: "JP", translatedSample: nil)
        static let english = Locale(language: "en", region: "US", translatedSample: "Pick a destination")
        static let korean = Locale(language: "ko", region: "KR", translatedSample: "목적지 정하기")
        static let spanish = Locale(language: "es", region: "ES", translatedSample: "Elegir un destino")
        static let french = Locale(language: "fr", region: "FR", translatedSample: "Choisir une destination")

        static let all: [Locale] = [.japanese, .english, .korean, .spanish, .french]
    }

    /// 指定した言語でアプリを起動する。
    ///
    /// オンボーディングは飛ばす。毎回5ステップ踏むとテストが遅くなるうえ、
    /// オンボーディング自体の検証は専用のテストで行うため。
    /// - Parameter stubData: 固定データで起動する。既定で有効。
    ///   実機のカレンダー・位置情報に依存すると、CI のまっさらなシミュレーターで
    ///   提案が0件になり要素を掴めない。5言語で同じ画面を出す目的もある。
    static func launch(
        _ locale: Locale,
        skipOnboarding: Bool = true,
        stubData: Bool = true,
        scenario: UITestScenario? = nil,
        arguments: [String] = []
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += [
            "-AppleLanguages", "(\(locale.language))",
            "-AppleLocale", "\(locale.language)_\(locale.region)"
        ]
        if skipOnboarding {
            app.launchArguments.append(LaunchArgument.skipOnboarding)
        } else {
            // 完了フラグは保存されるため、明示的に戻さないと2回目以降は
            // オンボーディングが始まらない
            app.launchArguments.append(LaunchArgument.forceOnboarding)
        }
        if stubData {
            app.launchArguments.append(LaunchArgument.stubData)
        }
        if let scenario {
            app.launchArguments += [UITestScenario.launchArgument, scenario.rawValue]
        }
        app.launchArguments += arguments
        app.launch()
        return app
    }

    /// アプリ側が見る起動引数。
    /// テストの都合をアプリ本体に持ち込むのは最小限にとどめる。
    enum LaunchArgument {
        /// オンボーディングを完了済みとして起動する
        static let skipOnboarding = "-uiTestSkipOnboarding"
        /// オンボーディングを未完了に戻して起動する
        static let forceOnboarding = "-uiTestForceOnboarding"
        /// カレンダー・天気を固定データにする（権限とネットワークに依存しない）
        static let stubData = "-uiTestStubData"
    }
}

extension XCTestCase {
    /// スクリーンショットを撮ってテスト結果に添付する。
    ///
    /// `.keepAlways` にしないと成功したテストの添付は破棄される。
    /// レイアウト確認が目的なので、成功時こそ残したい。
    func attachScreenshot(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// identifier で要素を引く。**種別を決め打ちしない。**
    ///
    /// SwiftUI は同じ `.accessibilityIdentifier` でも、中身によって
    /// other / staticText / button のどれとして公開するかが変わる。
    /// `app.otherElements[id]` で書くと、公開種別が変わった瞬間に
    /// 「要素が無い」となりテストだけが赤くなる（実際に空状態とエラー状態で踏んだ）。
    func element(_ app: XCUIApplication, _ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    /// 要素が現れるまで待つ。現れなければテストを失敗させる。
    @discardableResult
    func waitForElement(
        _ element: XCUIElement,
        timeout: TimeInterval = 15,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Bool {
        let appeared = element.waitForExistence(timeout: timeout)
        XCTAssertTrue(appeared, "要素が現れなかった: \(element)", file: file, line: line)
        return appeared
    }
}
