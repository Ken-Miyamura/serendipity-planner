import SwiftUI

struct InterestSelectionView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "heart.fill")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)

            Text("興味のあるジャンルを\n選んでください")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("3つ以上選択してください（後から変更できます）")
                .font(.subheadline)
                .foregroundColor(.secondary)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(SuggestionCategory.allCases, id: \.self) { category in
                    InterestTagView(
                        category: category,
                        isSelected: viewModel.selectedInterests.contains(category)
                    ) {
                        viewModel.toggleInterest(category)
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

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: category.iconName)
                    .font(.title3)
                Text(category.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                isSelected
                    ? Color.theme.color(for: category).opacity(0.15)
                    : Color(.secondarySystemBackground)
            )
            .foregroundColor(
                isSelected
                    ? Color.theme.color(for: category)
                    : .secondary
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.theme.color(for: category) : Color.clear,
                        lineWidth: 2
                    )
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}
