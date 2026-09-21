@testable import SerendipityPlanner
import XCTest

/// UI テスト用の投入データが、シナリオを抜けたときに残らないこと。
///
/// ## 直したバグ
///
/// 投入先は本物と同じ `UserDefaults` なので、**書いたら次の起動にも残る**。
/// seeded 以外で消していなかったため、空状態を見るつもりの画面に
/// 前回のデータが出たままになっていた。
///
/// 表に出なかったのは、テストクラスの実行順がたまたま
/// 「空状態を見る側が先」だったから。順番が変われば静かに壊れる。
///
/// UI テストでも書けるが、起動を2回挟むため1件で15分以上かかった。
/// 中身は `UserDefaults` の読み書きなので、こちらで見る。
final class UITestStubStorageTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "UITestStubStorageTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    /// seeded なら履歴とお気に入りが書き込まれること。
    /// 目的地は seeded の対象外（消す側にだけ入っている）。
    func testSeededScenarioWritesItsKeys() {
        UITestStubs.applyStorage(for: .seeded, to: defaults)

        for key in UITestStubs.seededKeys {
            XCTAssertNotNil(defaults.data(forKey: key), "\(key) が書き込まれていない")
        }
    }

    /// seeded 以外に切り替えたら消えること（これが直したバグ）
    func testNonSeededScenarioClearsPreviouslySeededKeys() {
        UITestStubs.applyStorage(for: .seeded, to: defaults)
        XCTAssertFalse(UITestStubs.keysClearedBetweenScenarios.isEmpty, "検証するキーが無い")

        UITestStubs.applyStorage(for: .standard, to: defaults)

        for key in UITestStubs.keysClearedBetweenScenarios {
            XCTAssertNil(
                defaults.data(forKey: key),
                "\(key) が残っている（次の起動に前回のデータが写り込む）"
            )
        }
    }

    /// seeded 以外のどのシナリオでも消えること。
    /// 空状態・エラー・読込中はどれも「データが無い前提」の画面を見る。
    func testEverySceneOtherThanSeededStartsClean() {
        for scenario in UITestScenario.allCases where scenario != .seeded {
            UITestStubs.applyStorage(for: .seeded, to: defaults)
            UITestStubs.applyStorage(for: scenario, to: defaults)

            for key in UITestStubs.keysClearedBetweenScenarios {
                XCTAssertNil(
                    defaults.data(forKey: key),
                    "\(scenario.rawValue): \(key) が残っている"
                )
            }
        }
    }
}
