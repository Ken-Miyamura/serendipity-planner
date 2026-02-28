import SwiftUI

struct InterestSelectionView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    private let accentGreen = Color(red: 0.275, green: 0.608, blue: 0.459)
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(accentGreen.opacity(0.12))
                    .frame(width: 72, height: 72)
                Image(systemName: "heart.fill")
                    .font(.system(size: 32))
                    .foregroundColor(accentGreen)
            }

            Text("興味のあるジャンルを\n選んでください")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)

            Text("3つ以上選択してください（後から変更できます）")
                .font(.subheadline)
                .foregroundColor(.secondary)

            LazyVGrid(columns: columns, spacing: 12) {
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
            .padding(.horizontal, 16)

            Spacer()
        }
        .padding()
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
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
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
                RoundedRectangle(cornerRadius: 12, style: .continuous)
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
