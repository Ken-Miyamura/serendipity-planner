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

            Text("エラーが発生しました")
                .font(.headline)

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
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
