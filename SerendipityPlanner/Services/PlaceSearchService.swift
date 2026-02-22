import MapKit
import CoreLocation

class PlaceSearchService {
    private let searchRadius: CLLocationDistance = 1500 // 1.5km

    /// Search for nearby places matching the suggestion category
    func searchNearbyPlaces(
        for category: SuggestionCategory,
        near location: CLLocation
    ) async -> [NearbyPlace] {
        let queries = category.searchQueries
        var allPlaces: [NearbyPlace] = []

        for query in queries {
            let places = await search(query: query, category: category, near: location)
            allPlaces.append(contentsOf: places)
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

        do {
            let search = MKLocalSearch(request: request)
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
