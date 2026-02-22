import SwiftUI

/// お気に入り一覧画面
struct FavoritesView: View {
    @EnvironmentObject private var favoriteService: FavoriteService
    @StateObject private var viewModel = FavoritesViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                SkyGradientView(weatherCondition: nil)

                if viewModel.isEmpty, viewModel.selectedCategory == nil {
                    emptyStateView
                } else {
                    favoritesListView
                }
            }
            .navigationTitle("お気に入り")
            .onAppear {
                viewModel.configure(with: favoriteService)
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))

            Text("お気に入りはまだありません")
                .font(.headline)
                .foregroundColor(.primary)

            Text("提案の詳細画面でハートアイコンをタップすると、\nここにお気に入りが表示されます。")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Favorites List

    private var favoritesListView: some View {
        VStack(spacing: 0) {
            // カテゴリフィルタ
            if !viewModel.availableCategories.isEmpty {
                categoryFilterBar
            }

            if viewModel.isEmpty {
                // フィルタ適用時の空状態
                VStack(spacing: 12) {
                    Spacer()
                    Text("このカテゴリのお気に入りはありません")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                List {
                    ForEach(viewModel.favorites) { favorite in
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
                        .listRowBackground(Color.clear)
                    }
                    .onDelete(perform: viewModel.removeFavorite)
                }
                .listStyle(.plain)
                .hideFormBackground()
            }
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
