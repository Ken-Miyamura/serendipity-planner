import Foundation

/// お気に入り一覧画面の ViewModel
@MainActor
class FavoritesViewModel: ObservableObject {
    @Published var favorites: [FavoriteSuggestion] = []
    @Published var selectedCategory: SuggestionCategory?

    private var favoriteService: FavoriteServiceProtocol?

    init(favoriteService: FavoriteServiceProtocol? = nil) {
        self.favoriteService = favoriteService
        if favoriteService != nil {
            loadFavorites()
        }
    }

    func configure(with favoriteService: FavoriteServiceProtocol) {
        self.favoriteService = favoriteService
        loadFavorites()
    }

    /// お気に入り一覧を読み込む
    func loadFavorites() {
        guard let favoriteService else { return }
        if let category = selectedCategory {
            favorites = favoriteService.getFavorites(for: category)
        } else {
            favorites = favoriteService.getFavorites()
        }
    }

    /// カテゴリフィルタを設定する
    func filterByCategory(_ category: SuggestionCategory?) {
        if selectedCategory == category {
            selectedCategory = nil
        } else {
            selectedCategory = category
        }
        loadFavorites()
    }

    /// お気に入りを削除する
    func removeFavorite(at offsets: IndexSet) {
        for index in offsets {
            let favorite = favorites[index]
            favoriteService?.removeFavorite(id: favorite.id)
        }
        loadFavorites()
    }

    /// お気に入りを ID で削除する
    func removeFavorite(id: UUID) {
        favoriteService?.removeFavorite(id: id)
        loadFavorites()
    }

    /// お気に入りに登録されているカテゴリ一覧を取得する
    var availableCategories: [SuggestionCategory] {
        guard let favoriteService else { return [] }
        return SuggestionCategory.allCases.filter {
            favoriteService.favoritedCategories().contains($0)
        }
    }

    /// お気に入りが空かどうか
    var isEmpty: Bool {
        favorites.isEmpty
    }

    /// 追加日のフォーマット済み文字列
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/M/d"
        return formatter.string(from: date)
    }
}
