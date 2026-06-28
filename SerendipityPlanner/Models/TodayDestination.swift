import CoreLocation
import Foundation

/// 「今日の目的地」。当日のみ有効で、日付が変わると自動的に無効化される。
/// 検索結果・おすすめエリア・最近の検索のいずれからも生成され、提案の検索基点となる。
struct TodayDestination: Codable, Equatable, Identifiable {
    let id: UUID
    /// 表示名（例: "鎌倉"）
    let name: String
    /// 補足（例: "鎌倉駅周辺" / "神奈川県 鎌倉市"）
    let subtitle: String
    let latitude: Double
    let longitude: Double
    /// この目的地を設定した日時
    let setDate: Date

    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }

    /// 設定日が今日であれば有効。日付が変わると無効になる。
    var isValidForToday: Bool {
        Calendar.current.isDateInToday(setDate)
    }

    init(
        id: UUID = UUID(),
        name: String,
        subtitle: String,
        latitude: Double,
        longitude: Double,
        setDate: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.subtitle = subtitle
        self.latitude = latitude
        self.longitude = longitude
        self.setDate = setDate
    }
}
