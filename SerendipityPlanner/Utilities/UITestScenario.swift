import Foundation

/// UI テストでアプリをどの状態で立ち上げるか。
///
/// 空状態・エラー・読込中の文言は**提案が出ている状態より長くなりがち**で、
/// レイアウトが崩れるのはむしろこちら側。正常系だけ撮っても検証にならない。
///
/// アプリ本体とテストターゲットの両方から参照する。名前を二重に定義すると、
/// ずれたときに「起動しても状態が変わらないがテストは緑」という気づけない壊れ方をする。
/// `AccessibilityID` と同じ理由でここを唯一の定義とする。
///
/// `UITestStubs` 側に置かないのは、あちらが `#if DEBUG` でアプリの型に依存しており
/// テストターゲットから見えないため。
enum UITestScenario: String, CaseIterable {
    /// 提案が3件出ている通常の状態
    case standard
    /// 空き時間が0件（emptyStateView）
    case empty
    /// カレンダー権限が拒否されている（ErrorStateView +「設定を開く」）
    case denied
    /// カレンダー取得に失敗（ErrorStateView、再試行のみ）
    case error
    /// 読み込みが終わらない状態（ProgressView を撮るため）
    case loading
    /// 履歴・お気に入りにデータがある状態
    case seeded
    /// ウィジェットのレイアウト確認用の一覧を表示する
    case widget

    /// 起動引数。次の引数がシナリオ名
    static let launchArgument = "-uiTestScenario"

    /// 実行中のプロセスの起動引数から解決する
    static var current: UITestScenario {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: launchArgument),
              arguments.indices.contains(index + 1),
              let scenario = UITestScenario(rawValue: arguments[index + 1])
        else { return .standard }
        return scenario
    }
}
