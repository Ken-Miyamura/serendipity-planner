import SwiftUI

struct OnboardingContainerView: View {
    @EnvironmentObject private var preferenceService: PreferenceService
    @StateObject private var viewModel = OnboardingViewModel()
    let onComplete: () -> Void

    var body: some View {
        VStack {
            // Page indicator
            HStack(spacing: 8) {
                ForEach(0..<viewModel.totalPages, id: \.self) { index in
                    Circle()
                        .fill(index == viewModel.currentPage ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 20)

            // Content
            TabView(selection: $viewModel.currentPage) {
                WelcomePageView()
                    .tag(0)
                InterestSelectionView(viewModel: viewModel)
                    .tag(1)
                CalendarPermissionView(viewModel: viewModel)
                    .tag(2)
                NotificationPermissionView(viewModel: viewModel)
                    .tag(3)
                LocationInputView(viewModel: viewModel)
                    .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: viewModel.currentPage)

            // Bottom button
            Button {
                if viewModel.isLastPage {
                    viewModel.saveInterests(to: preferenceService)
                    onComplete()
                } else {
                    viewModel.nextPage()
                }
            } label: {
                Text(viewModel.isLastPage ? "はじめる" : "次へ")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.canProceed ? Color.accentColor : Color.gray)
                    .cornerRadius(12)
            }
            .disabled(!viewModel.canProceed)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}
