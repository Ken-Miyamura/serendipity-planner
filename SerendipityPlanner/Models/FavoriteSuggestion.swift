import Foundation

/// お気に入り提案モデル
/// ユーザーが気に入った提案を保存するためのデータ構造
struct FavoriteSuggestion: Codable, Identifiable {
    let id: UUID
    let category: SuggestionCategory
    let title: String
    let description: String
    let placeName: String?
    let placeAddress: String?
    let latitude: Double?
    let longitude: Double?
    let addedDate: Date

    init(
        id: UUID = UUID(),
        category: SuggestionCategory,
        title: String,
        description: String,
        placeName: String? = nil,
        placeAddress: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        addedDate: Date = Date()
    ) {
        self.id = id
        self.category = category
        self.title = title
        self.description = description
        self.placeName = placeName
        self.placeAddress = placeAddress
        self.latitude = latitude
        self.longitude = longitude
        self.addedDate = addedDate
    }

    /// Suggestion から FavoriteSuggestion を生成する
    init(from suggestion: Suggestion) {
        self.id = UUID()
        self.category = suggestion.category
        self.title = suggestion.title
        self.description = suggestion.description
        self.placeName = suggestion.nearbyPlace?.name
        self.placeAddress = nil
        self.latitude = suggestion.nearbyPlace?.latitude
        self.longitude = suggestion.nearbyPlace?.longitude
        self.addedDate = Date()
    }
}
