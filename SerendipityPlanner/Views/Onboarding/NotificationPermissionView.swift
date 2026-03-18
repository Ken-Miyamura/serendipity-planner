import SwiftUI

struct NotificationPermissionView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Hero: Illustration
            Image("NotificationIllustration")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 320, height: 320)
                .frame(height: 320)
                .offset(y: appeared ? 0 : -30)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.8), value: appeared)

            Spacer().frame(maxHeight: 16)

            if let error = viewModel.permissionError, error.contains("通知") {
                PermissionErrorView(error: error)
            }

            PermissionDescription(
                headline: "通知でお知らせ",
                text: "空き時間の前に\n体験の提案を通知します"
            )
            .offset(y: appeared ? 0 : -20)
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.8).delay(0.3), value: appeared)

            Spacer()
        }
        .padding(.horizontal, 4)
        .onChange(of: viewModel.currentPage) { page in
            if page == 3 {
                appeared = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    appeared = true
                }
                if !viewModel.notificationPermissionGranted {
                    Task {
                        try? await Task.sleep(nanoseconds: 600_000_000)
                        await viewModel.requestNotificationPermission()
                    }
                }
            } else {
                appeared = false
            }
        }
    }
}
