import Foundation

/// お気に入り提案を管理するサービス
/// UserDefaults を使って永続化を行う
class FavoriteService: ObservableObject, FavoriteServiceProtocol {
    @Published private(set) var favorites: [FavoriteSuggestion] = []

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.favorites = loadFromDefaults()
    }

    // MARK: - FavoriteServiceProtocol

    func getFavorites() -> [FavoriteSuggestion] {
        favorites
    }

    @discardableResult
    func addFavorite(_ suggestion: Suggestion) -> FavoriteSuggestion {
        let favorite = FavoriteSuggestion(from: suggestion)
        favorites.insert(favorite, at: 0)
        saveToDefaults()
        return favorite
    }

    func removeFavorite(id: UUID) {
        favorites.removeAll { $0.id == id }
        saveToDefaults()
    }

    func isFavorite(title: String, category: SuggestionCategory) -> Bool {
        favorites.contains { $0.title == title && $0.category == category }
    }

    func getFavorites(for category: SuggestionCategory) -> [FavoriteSuggestion] {
        favorites.filter { $0.category == category }
    }

    func favoritedCategories() -> Set<SuggestionCategory> {
        Set(favorites.map(\.category))
    }

    func removeAll() {
        favorites.removeAll()
        saveToDefaults()
    }

    // MARK: - Private

    private func loadFromDefaults() -> [FavoriteSuggestion] {
        guard let data = defaults.data(forKey: Constants.Storage.favoriteSuggestionsKey),
              let decoded = try? decoder.decode([FavoriteSuggestion].self, from: data)
        else {
            return []
        }
        return decoded
    }

    private func saveToDefaults() {
        if let data = try? encoder.encode(favorites) {
            defaults.set(data, forKey: Constants.Storage.favoriteSuggestionsKey)
        }
    }
}
