import SwiftUI

struct OnboardingContainerView: View {
    @EnvironmentObject private var preferenceService: PreferenceService
    @StateObject private var viewModel = OnboardingViewModel()
    let onComplete: () -> Void

    private let pageBackground = Color.theme.pageBackground
    private let accentGreen = Color(red: 0.275, green: 0.608, blue: 0.459)

    var body: some View {
        ZStack {
            pageBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Page indicator
                HStack(spacing: 8) {
                    ForEach(0 ..< viewModel.totalPages, id: \.self) { index in
                        Capsule()
                            .fill(index == viewModel.currentPage ? accentGreen : Color.secondary.opacity(0.2))
                            .frame(width: index == viewModel.currentPage ? 24 : 8, height: 8)
                            .animation(.easeInOut(duration: 0.3), value: viewModel.currentPage)
                    }
                }
                .padding(.top, 24)

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
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(viewModel.canProceed ? accentGreen : Color.gray.opacity(0.4))
                        )
                        .shadow(color: viewModel.canProceed ? accentGreen.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
                }
                .disabled(!viewModel.canProceed)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}
