import Foundation

/// カスタムURLスキーム（serendipityplanner://）経由の遷移先を管理する
/// 現状は「ホーム」のみサポート（目的地バナーが常に表示されているため）
class DeepLinkRouter: ObservableObject {
    @Published var selectedTab = 0

    func handle(_ url: URL) {
        guard url.scheme == "serendipityplanner" else { return }
        selectedTab = 0
    }
}
