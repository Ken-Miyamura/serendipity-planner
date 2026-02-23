import Foundation

/// 受け入れた提案の履歴データ
struct SuggestionHistory: Codable, Identifiable {
    let id: UUID
    let suggestion: Suggestion
    let acceptedDate: Date
    let placeName: String?
    let placeAddress: String?

    init(
        id: UUID = UUID(),
        suggestion: Suggestion,
        acceptedDate: Date = Date(),
        placeName: String? = nil,
        placeAddress: String? = nil
    ) {
        self.id = id
        self.suggestion = suggestion
        self.acceptedDate = acceptedDate
        self.placeName = placeName
        self.placeAddress = placeAddress
    }
}
