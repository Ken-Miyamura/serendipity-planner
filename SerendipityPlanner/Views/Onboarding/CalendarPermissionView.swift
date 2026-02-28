import SwiftUI

struct CalendarPermissionView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    private let cardBackground = Color.theme.cardBackground
    private let iconColor = Color.blue
    private let accentGreen = Color(red: 0.275, green: 0.608, blue: 0.459)

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon with circle background
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 88, height: 88)
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(iconColor)
            }

            Text("カレンダーへのアクセス")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            // Description card
            VStack(spacing: 16) {
                Text("カレンダーの予定を確認して\n空き時間を検出するために必要です")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                if viewModel.calendarPermissionGranted {
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
                    .accessibilityLabel("カレンダーへのアクセスは許可済みです")
                } else {
                    Button {
                        Task {
                            await viewModel.requestCalendarPermission()
                        }
                    } label: {
                        Text("カレンダーを許可する")
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

                    if let error = viewModel.permissionError, error.contains("カレンダー") {
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
