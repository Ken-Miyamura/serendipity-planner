import Foundation

/// 目的地検索シートに表示するおすすめエリア（キュレーション）。
/// 検索しなくてもワンタップで定番の行き先を選べるようにする。
struct RecommendedArea: Identifiable, Equatable {
    let id: UUID
    /// エリア名（例: "鎌倉"）
    let name: String
    /// 都道府県（例: "神奈川県"）
    let region: String
    /// キャッチコピー（例: "古都の散歩道"）
    let tagline: String
    let latitude: Double
    let longitude: Double

    init(
        id: UUID = UUID(),
        name: String,
        region: String,
        tagline: String,
        latitude: Double,
        longitude: Double
    ) {
        self.id = id
        self.name = name
        self.region = region
        self.tagline = tagline
        self.latitude = latitude
        self.longitude = longitude
    }

    /// 今日の目的地へ変換する
    func toDestination() -> TodayDestination {
        TodayDestination(
            name: name,
            subtitle: "\(region)・\(tagline)",
            latitude: latitude,
            longitude: longitude
        )
    }

    /// 定番のおすすめエリア一覧
    static let curated: [RecommendedArea] = [
        RecommendedArea(
            name: "鎌倉", region: "神奈川県", tagline: "古都の散歩道",
            latitude: 35.3192, longitude: 139.5466
        ),
        RecommendedArea(
            name: "横浜 みなとみらい", region: "神奈川県", tagline: "海辺と夜景",
            latitude: 35.4571, longitude: 139.6320
        ),
        RecommendedArea(
            name: "表参道", region: "東京都", tagline: "カフェとアート",
            latitude: 35.6657, longitude: 139.7128
        ),
        RecommendedArea(
            name: "江ノ島", region: "神奈川県", tagline: "海沿いさんぽ",
            latitude: 35.2990, longitude: 139.4807
        )
    ]
}
