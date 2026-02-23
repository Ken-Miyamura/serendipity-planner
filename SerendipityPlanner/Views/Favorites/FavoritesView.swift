import SwiftUI

/// お気に入り一覧画面
struct FavoritesView: View {
    @EnvironmentObject private var favoriteService: FavoriteService
    @StateObject private var viewModel = FavoritesViewModel()

    private var useLightText: Bool {
        let period = TimePeriod.current()
        return period.prefersLightText
    }

    var body: some View {
        NavigationView {
            ZStack {
                SkyGradientView(weatherCondition: nil)

                if viewModel.isEmpty, viewModel.selectedCategory == nil {
                    VStack {
                        favoritesHeader
                        Spacer()
                        emptyStateView
                        Spacer()
                    }
                } else {
                    favoritesListView
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.configure(with: favoriteService)
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - ヘッダー

    private var favoritesHeader: some View {
        Text("お気に入り")
            .font(.title3)
            .fontWeight(.medium)
            .foregroundColor(useLightText ? .white : .primary)
            .shadow(color: useLightText ? .black.opacity(0.3) : .clear, radius: 2, y: 1)
            .padding(.top, 16)
            .padding(.bottom, 8)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart")
                .font(.system(size: 60))
                .foregroundColor(useLightText ? .white.opacity(0.5) : Color(red: 0.82, green: 0.52, blue: 0.62).opacity(0.5))

            Text("お気に入りはまだありません")
                .font(.headline)
                .foregroundColor(useLightText ? .white : .primary)

            Text("提案の詳細画面でハートアイコンをタップすると、\nここにお気に入りが表示されます。")
                .font(.subheadline)
                .foregroundColor(useLightText ? .white.opacity(0.7) : .secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Favorites List

    private var favoritesListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                favoritesHeader

                // カテゴリフィルタ
                if !viewModel.availableCategories.isEmpty {
                    categoryFilterBar
                }

                if viewModel.isEmpty {
                    // フィルタ適用時の空状態
                    VStack(spacing: 12) {
                        Spacer().frame(height: 40)
                        Text("このカテゴリのお気に入りはありません")
                            .font(.subheadline)
                            .foregroundColor(useLightText ? .white.opacity(0.7) : .secondary)
                    }
                } else {
                    ForEach(Array(viewModel.favorites.enumerated()), id: \.element.id) { index, favorite in
                        NavigationLink {
                            FavoriteDetailView(
                                favorite: favorite,
                                onDelete: {
                                    viewModel.removeFavorite(id: favorite.id)
                                }
                            )
                        } label: {
                            FavoriteRowView(
                                favorite: favorite,
                                formattedDate: viewModel.formattedDate(favorite.addedDate)
                            )
                        }
                        .buttonStyle(.plain)
                        .staggeredAppear(index: index)
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Category Filter

    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // 「すべて」ボタン
                filterChip(
                    label: "すべて",
                    isSelected: viewModel.selectedCategory == nil
                ) {
                    viewModel.filterByCategory(nil)
                }

                ForEach(viewModel.availableCategories, id: \.self) { category in
                    filterChip(
                        icon: category.iconName,
                        label: category.displayName,
                        color: Color.theme.color(for: category),
                        isSelected: viewModel.selectedCategory == category
                    ) {
                        viewModel.filterByCategory(category)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private func filterChip(
        icon: String? = nil,
        label: String,
        color: Color = .accentColor,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? color.opacity(0.2) : Color.theme.secondaryBackground)
            .foregroundColor(isSelected ? color : .secondary)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? color.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label)、\(isSelected ? "選択中" : "未選択")")
        .accessibilityHint("タップでフィルタを切り替え")
    }
}
