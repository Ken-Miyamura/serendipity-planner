import SwiftUI

struct NotificationPermissionView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Hero: Illustration
            Image("NotificationIllustration")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 280, height: 280)
                .frame(height: 280)

            Spacer().frame(maxHeight: 20)

            // Permission button or granted state
            if viewModel.notificationPermissionGranted {
                PermissionGrantedBadge(
                    accessibilityText: "通知は許可済みです"
                )
            } else {
                PermissionActionButton(
                    icon: "checkmark.circle.fill",
                    label: "通知を許可する"
                ) {
                    Task {
                        await viewModel.requestNotificationPermission()
                    }
                }

                if let error = viewModel.permissionError, error.contains("通知") {
                    PermissionErrorView(error: error)
                }
            }

            PermissionDescription(
                text: "空き時間の前に\n体験の提案を通知します"
            )

            Spacer()
        }
        .padding(.horizontal, 4)
    }
}
