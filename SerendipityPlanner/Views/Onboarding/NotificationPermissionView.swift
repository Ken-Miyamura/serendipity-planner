import SwiftUI

struct NotificationPermissionView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "bell.badge")
                .font(.system(size: 64))
                .foregroundColor(.orange)

            Text("通知の許可")
                .font(.title2)
                .fontWeight(.bold)

            Text("空き時間の前に\n体験の提案を通知します")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if viewModel.notificationPermissionGranted {
                Label("許可済み", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.headline)
                    .accessibilityLabel("通知は許可済みです")
            } else {
                Button {
                    Task {
                        await viewModel.requestNotificationPermission()
                    }
                } label: {
                    Text("通知を許可する")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: 240)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(12)
                }

                if let error = viewModel.permissionError, error.contains("通知") {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button("設定を開く") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.caption)
                }
            }

            Spacer()

            Text("後から設定アプリで変更できます")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding()
    }
}
