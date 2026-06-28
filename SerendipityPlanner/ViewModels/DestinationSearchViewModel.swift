import CoreLocation
import Foundation
import MapKit

/// 目的地検索シートの検索ロジック。
/// - 入力に応じて MKLocalSearch でエリア・駅・スポットを検索する（デバウンス付き）
/// - 現在地周辺の「おすすめエリア」を MapKit から動的に取得する
@MainActor
final class DestinationSearchViewModel: ObservableObject {
    @Published var query = ""
    @Published private(set) var results: [TodayDestination] = []
    @Published private(set) var isSearching = false
    @Published private(set) var recommendedAreas: [TodayDestination] = []
    @Published private(set) var isLoadingRecommendations = false

    /// 現在地が取れないときのフォールバック検索リージョン。
    /// 沖縄〜北海道まで含むよう広めに設定（中心は本州あたり）。
    private let japanRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 36.0, longitude: 137.5),
        span: MKCoordinateSpan(latitudeDelta: 22, longitudeDelta: 22)
    )

    /// おすすめエリア抽出に使う「行き先になりやすい」検索クエリ
    private let recommendationQueries = ["観光スポット", "名所", "公園"]
    /// おすすめエリアの最大表示件数
    private let maxRecommendations = 6

    /// 検索バイアスの基点となる現在地（シート表示時に取得）
    private var userLocation: CLLocation?

    private var searchTask: Task<Void, Never>?

    // MARK: - 検索

    /// 入力変更時に呼ぶ。空なら結果をクリアし、それ以外はデバウンス後に検索する。
    func updateQuery(_ text: String) {
        query = text
        searchTask?.cancel()

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            results = []
            isSearching = false
            return
        }

        searchTask = Task { [weak self] in
            // デバウンス（連続入力中は検索しない）
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            await self?.performSearch(query: trimmed)
        }
    }

    private func performSearch(query: String) async {
        isSearching = true
        defer { isSearching = false }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = searchRegion()

        do {
            let response = try await MKLocalSearch(request: request).start()
            guard !Task.isCancelled else { return }
            results = response.mapItems.compactMap { Self.destination(from: $0) }
        } catch {
            guard !Task.isCancelled else { return }
            results = []
        }
    }

    /// 検索リージョン。現在地が取れていれば現在地を中心に広めにバイアスし、
    /// 近場を優先しつつ全国の地名検索も可能にする。取れなければ全国フォールバック。
    private func searchRegion() -> MKCoordinateRegion {
        guard let userLocation else { return japanRegion }
        return MKCoordinateRegion(
            center: userLocation.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 16, longitudeDelta: 16)
        )
    }

    // MARK: - おすすめエリア（現在地ベース）

    /// 現在地周辺の行き先候補を取得する。位置が無ければ空にする（固定データは持たない）。
    func loadRecommendedAreas(near location: CLLocation?) async {
        // 検索バイアスにも使うため現在地を保持する
        userLocation = location
        guard let location else {
            recommendedAreas = []
            return
        }

        isLoadingRecommendations = true
        defer { isLoadingRecommendations = false }

        // 近隣の街・エリアに届くよう、提案検索より広めのリージョンを使う
        let region = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.45, longitudeDelta: 0.45)
        )

        var collected: [TodayDestination] = []
        var seenNames = Set<String>()

        for query in recommendationQueries {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query
            request.region = region
            guard let response = try? await MKLocalSearch(request: request).start() else { continue }

            for item in response.mapItems {
                guard let destination = Self.recommendedDestination(from: item, userLocation: location),
                      seenNames.insert(destination.name).inserted else { continue }
                collected.append(destination)
            }
        }

        // 現在地から近い順に並べ、上限件数で打ち切る
        recommendedAreas = Array(
            collected
                .sorted { location.distance(from: $0.location) < location.distance(from: $1.location) }
                .prefix(maxRecommendations)
        )
    }

    // MARK: - 変換

    /// 検索結果の MKMapItem を今日の目的地へ変換する
    private static func destination(from item: MKMapItem) -> TodayDestination? {
        guard let name = item.name else { return nil }
        let placemark = item.placemark
        let subtitle = [placemark.administrativeArea, placemark.locality]
            .compactMap(\.self)
            .joined(separator: " ")

        return TodayDestination(
            name: name,
            subtitle: subtitle.isEmpty ? "周辺のスポットを提案" : subtitle,
            latitude: placemark.coordinate.latitude,
            longitude: placemark.coordinate.longitude
        )
    }

    /// おすすめエリアの MKMapItem を今日の目的地へ変換する（現在地からの距離を補足に含める）
    private static func recommendedDestination(
        from item: MKMapItem,
        userLocation: CLLocation
    ) -> TodayDestination? {
        guard let name = item.name else { return nil }
        let placemark = item.placemark
        let coordinate = placemark.coordinate
        let distance = userLocation.distance(
            from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        )
        let region = placemark.administrativeArea ?? placemark.locality ?? ""
        let distanceText = Self.distanceText(meters: distance)
        let subtitle = region.isEmpty ? distanceText : "\(region)・\(distanceText)"

        return TodayDestination(
            name: name,
            subtitle: subtitle,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
    }

    private static func distanceText(meters: Double) -> String {
        if meters >= 1000 {
            return "現在地から約\(Int((meters / 1000).rounded()))km"
        }
        return "現在地から約\(Int(meters))m"
    }
}
