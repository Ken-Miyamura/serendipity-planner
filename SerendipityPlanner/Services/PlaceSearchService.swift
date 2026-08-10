import CoreLocation
import MapKit

class PlaceSearchService: PlaceSearchServiceProtocol {
    private let searchRadius: CLLocationDistance = 1500 // 1.5km

    /// Search for nearby places matching the suggestion category
    ///
    /// 主たる手段は `MKPointOfInterestCategory` によるカテゴリ検索（言語非依存）。
    /// カテゴリで表現しきれない分類だけ、端末の言語に応じたキーワード検索を併用する。
    func searchNearbyPlaces(
        for category: SuggestionCategory,
        near location: CLLocation
    ) async -> [NearbyPlace] {
        var allPlaces: [NearbyPlace] = []

        let poiCategories = category.pointOfInterestCategories
        if !poiCategories.isEmpty {
            allPlaces += await searchByCategory(poiCategories, category: category, near: location)
        }

        for query in category.supplementalQueries {
            allPlaces += await search(query: query, category: category, near: location)
        }

        // Sort by distance, remove duplicates by name
        var seen = Set<String>()
        return allPlaces
            .sorted { $0.distance < $1.distance }
            .filter { seen.insert($0.name).inserted }
    }

    /// Pick a random nearby place for a category
    func findNearbyPlace(
        for category: SuggestionCategory,
        near location: CLLocation
    ) async -> NearbyPlace? {
        let places = await searchNearbyPlaces(for: category, near: location)
        // Pick from the top 5 closest places randomly for variety
        let topPlaces = Array(places.prefix(5))
        return topPlaces.randomElement()
    }

    // MARK: - Private

    /// POI カテゴリによる検索。テキストクエリを使わないため言語に依存しない。
    private func searchByCategory(
        _ poiCategories: [MKPointOfInterestCategory],
        category: SuggestionCategory,
        near location: CLLocation
    ) async -> [NearbyPlace] {
        let request = MKLocalPointsOfInterestRequest(
            center: location.coordinate,
            radius: searchRadius
        )
        request.pointOfInterestFilter = MKPointOfInterestFilter(including: poiCategories)
        return await execute(MKLocalSearch(request: request), category: category, near: location)
    }

    /// キーワードによる検索。POI カテゴリで表現できない分類の補助にのみ使う。
    private func search(
        query: String,
        category: SuggestionCategory,
        near location: CLLocation
    ) async -> [NearbyPlace] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: searchRadius * 2,
            longitudinalMeters: searchRadius * 2
        )
        return await execute(MKLocalSearch(request: request), category: category, near: location)
    }

    private func execute(
        _ search: MKLocalSearch,
        category: SuggestionCategory,
        near location: CLLocation
    ) async -> [NearbyPlace] {
        do {
            let response = try await search.start()

            return response.mapItems.compactMap { item in
                guard let name = item.name else { return nil }

                let placeLocation = CLLocation(
                    latitude: item.placemark.coordinate.latitude,
                    longitude: item.placemark.coordinate.longitude
                )
                let distance = Int(location.distance(from: placeLocation))

                guard distance <= Int(searchRadius) else { return nil }

                return NearbyPlace(
                    name: name,
                    category: category,
                    latitude: item.placemark.coordinate.latitude,
                    longitude: item.placemark.coordinate.longitude,
                    distance: distance
                )
            }
        } catch {
            return []
        }
    }
}
