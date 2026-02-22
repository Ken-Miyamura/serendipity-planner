import SwiftUI

struct CalendarPermissionView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(.blue)

            Text("カレンダーへのアクセス")
                .font(.title2)
                .fontWeight(.bold)

            Text("カレンダーの予定を確認して\n空き時間を検出するために必要です")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if viewModel.calendarPermissionGranted {
                Label("許可済み", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.headline)
                    .accessibilityLabel("カレンダーへのアクセスは許可済みです")
            } else {
                Button {
                    Task {
                        await viewModel.requestCalendarPermission()
                    }
                } label: {
                    Text("カレンダーを許可する")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: 240)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }

                if let error = viewModel.permissionError, error.contains("カレンダー") {
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
