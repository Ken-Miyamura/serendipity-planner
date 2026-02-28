import SwiftUI

struct InterestSelectionView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Hero: Illustration with floating badges
            ZStack {
                // Orange-tinted background
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(OnboardingColors.orange.opacity(0.08))
                    .frame(width: 200, height: 200)

                // Illustration
                Image("InterestIllustration")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 160, height: 160)

                // Floating badges
                FloatingBadge(icon: "camera.fill", color: .orange)
                    .offset(x: -95, y: -75)

                FloatingBadge(icon: "book.fill", color: Color(red: 0.4, green: 0.6, blue: 0.9))
                    .offset(x: 100, y: -30)

                FloatingBadge(icon: "cup.and.saucer.fill", color: Color(red: 0.6, green: 0.4, blue: 0.2))
                    .offset(x: 60, y: 90)
            }
            .padding(.top, 2)

            // Title
            Text("興味のあるジャンル")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(OnboardingColors.textMain)
                .padding(.top, 8)

            // Subtitle
            Text("3つ以上選択してください")
                .font(.subheadline)
                .foregroundColor(OnboardingColors.textSub)
                .padding(.top, 2)

            Text("後からアプリの設定画面で変更できます")
                .font(.caption)
                .foregroundColor(OnboardingColors.textSub.opacity(0.7))
                .padding(.top, 4)

            Spacer().frame(maxHeight: 20)

            // Interest Grid
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(SuggestionCategory.allCases, id: \.self) { category in
                    InterestTagView(
                        category: category,
                        isSelected: viewModel.selectedInterests.contains(category)
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.toggleInterest(category)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Floating Badge

private struct FloatingBadge: View {
    let icon: String
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 36, height: 36)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
        }
    }
}

struct InterestTagView: View {
    let category: SuggestionCategory
    let isSelected: Bool
    let action: () -> Void

    private let cardBackground = Color.theme.cardBackground

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: category.iconName)
                    .font(.system(size: 18, weight: .medium))
                Text(category.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        isSelected
                            ? Color.theme.color(for: category).opacity(0.12)
                            : cardBackground
                    )
            )
            .foregroundColor(
                isSelected
                    ? Color.theme.color(for: category)
                    : .secondary
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        isSelected ? Color.theme.color(for: category) : Color.clear,
                        lineWidth: 2
                    )
            )
            .shadow(color: Color.gray.opacity(0.08), radius: 8, x: 0, y: 2)
            .scaleEffect(isSelected ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .accessibilityLabel("\(category.displayName)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(isSelected ? "タップで選択解除" : "タップで選択")
    }
}
