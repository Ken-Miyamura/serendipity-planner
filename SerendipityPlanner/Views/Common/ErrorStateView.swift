import SwiftUI

struct ErrorStateView: View {
    let message: String
    var showOpenSettings: Bool = false
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            // 画面の目印はコンテナではなく**実体のある子**に付ける。
            // VStack のような小さなコンテナに付けると、SwiftUI が中の要素すべてに
            // 同じ identifier を配って回り、子に付けた identifier が消える
            // （再試行ボタンも「設定を開く」も screen.errorState になっていた）。
            Text("エラーが発生しました")
                .font(.headline)
                .uiTestID(AccessibilityID.screenErrorState)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("再試行") {
                retryAction()
            }
            .buttonStyle(.borderedProminent)
            .accessibilityHint("データの再読み込みを試みます")

            if showOpenSettings {
                Button("設定を開く") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(.bordered)
                .accessibilityHint("iOS設定アプリを開いて権限を変更します")
                .uiTestID(AccessibilityID.errorOpenSettingsButton)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
