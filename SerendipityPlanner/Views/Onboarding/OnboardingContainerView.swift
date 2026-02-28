import SwiftUI

struct OnboardingContainerView: View {
    @EnvironmentObject private var preferenceService: PreferenceService
    @StateObject private var viewModel = OnboardingViewModel()
    let onComplete: () -> Void

    private let pageBackground = Color.theme.pageBackground
    private var isWelcomePage: Bool { viewModel.currentPage == 0 }

    var body: some View {
        ZStack {
            (isWelcomePage ? Color(red: 0.98, green: 0.97, blue: 0.94) : pageBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
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

                // Footer: page dots + button
                HStack {
                    // Page indicator (left)
                    HStack(spacing: 6) {
                        ForEach(0 ..< viewModel.totalPages, id: \.self) { index in
                            Capsule()
                                .fill(index == viewModel.currentPage ? OnboardingColors.coralMuted : Color.secondary.opacity(0.2))
                                .frame(width: index == viewModel.currentPage ? 20 : 8, height: 8)
                                .animation(.easeInOut(duration: 0.3), value: viewModel.currentPage)
                        }
                    }

                    Spacer()

                    // Button (right)
                    Button {
                        if viewModel.isLastPage {
                            viewModel.saveInterests(to: preferenceService)
                            onComplete()
                        } else {
                            viewModel.nextPage()
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(isWelcomePage || viewModel.canProceed ? OnboardingColors.coralMuted : Color.gray.opacity(0.4))
                                .frame(width: 56, height: 56)
                                .shadow(color: isWelcomePage || viewModel.canProceed ? OnboardingColors.coralMuted.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
                            Image(systemName: viewModel.isLastPage ? "checkmark" : "arrow.right")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .disabled(!isWelcomePage && !viewModel.canProceed)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 36)
            }
        }
    }
}
