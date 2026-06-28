import Foundation
import MapKit

/// 目的地検索シートの検索ロジック。
/// 入力に応じて MKLocalSearch でエリア・駅・スポットを検索する（デバウンス付き）。
@MainActor
final class DestinationSearchViewModel: ObservableObject {
    @Published var query = ""
    @Published private(set) var results: [TodayDestination] = []
    @Published private(set) var isSearching = false

    /// 日本全域をカバーする検索リージョン（全国どこでも検索できるよう広めに設定）
    private let japanRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 36.2, longitude: 138.2),
        span: MKCoordinateSpan(latitudeDelta: 12, longitudeDelta: 12)
    )

    private var searchTask: Task<Void, Never>?

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
        request.region = japanRegion

        do {
            let response = try await MKLocalSearch(request: request).start()
            guard !Task.isCancelled else { return }
            results = response.mapItems.compactMap { Self.destination(from: $0) }
        } catch {
            guard !Task.isCancelled else { return }
            results = []
        }
    }

    /// MKMapItem を今日の目的地へ変換する
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
}
