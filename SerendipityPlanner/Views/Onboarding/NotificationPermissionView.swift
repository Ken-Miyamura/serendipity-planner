import SwiftUI

struct NotificationPermissionView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    private let cardBackground = Color.theme.cardBackground
    private let iconColor = Color.orange
    private let accentGreen = Color(red: 0.275, green: 0.608, blue: 0.459)

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon with circle background
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 88, height: 88)
                Image(systemName: "bell.badge")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(iconColor)
            }

            Text("通知の許可")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            // Description card
            VStack(spacing: 16) {
                Text("空き時間の前に\n体験の提案を通知します")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                if viewModel.notificationPermissionGranted {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(accentGreen)
                            .font(.title3)
                        Text("許可済み")
                            .font(.headline)
                            .foregroundColor(accentGreen)
                    }
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(accentGreen.opacity(0.1))
                    )
                    .accessibilityLabel("通知は許可済みです")
                } else {
                    Button {
                        Task {
                            await viewModel.requestNotificationPermission()
                        }
                    } label: {
                        Text("通知を許可する")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(iconColor)
                            )
                            .shadow(color: iconColor.opacity(0.3), radius: 8, x: 0, y: 4)
                    }

                    if let error = viewModel.permissionError, error.contains("通知") {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)

                        Button("設定を開く") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .font(.caption)
                        .foregroundColor(iconColor)
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(cardBackground)
            )
            .shadow(color: Color.gray.opacity(0.08), radius: 8, x: 0, y: 2)
            .padding(.horizontal, 8)

            Spacer()

            Text("後から設定アプリで変更できます")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding()
    }
}
