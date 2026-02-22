import Foundation
import CoreLocation

class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate, LocationServiceProtocol {
    @Published var currentLocationName: String = "取得中..."
    @Published var currentLocation: CLLocation?
    @Published var locationAuthorized = false
    @Published var locationError: String?

    private let preferenceService: PreferenceService
    private let locationManager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocation?, Never>?

    init(preferenceService: PreferenceService) {
        self.preferenceService = preferenceService
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        updateAuthorizationStatus()
    }

    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func requestCurrentLocation() async -> CLLocation? {
        guard locationAuthorized else { return nil }

        // Return cached location if recent (within 5 minutes)
        if let cached = currentLocation,
           Date().timeIntervalSince(cached.timestamp) < 300 {
            return cached
        }

        return await withCheckedContinuation { continuation in
            locationContinuation = continuation
            locationManager.requestLocation()
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        locationContinuation?.resume(returning: location)
        locationContinuation = nil

        // Reverse geocode to get display name
        reverseGeocode(location)
    }

    private func reverseGeocode(_ location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            guard let placemark = placemarks?.first else { return }
            DispatchQueue.main.async {
                // Show locality (city) + subLocality (district) if available
                if let subLocality = placemark.subLocality, let locality = placemark.locality {
                    self?.currentLocationName = "\(locality) \(subLocality)"
                } else if let locality = placemark.locality {
                    self?.currentLocationName = locality
                } else if let admin = placemark.administrativeArea {
                    self?.currentLocationName = admin
                }
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationContinuation?.resume(returning: nil)
        locationContinuation = nil
        DispatchQueue.main.async {
            self.locationError = "位置情報の取得に失敗しました: \(error.localizedDescription)"
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        updateAuthorizationStatus()
    }

    private func updateAuthorizationStatus() {
        let status = locationManager.authorizationStatus
        locationAuthorized = (status == .authorizedWhenInUse || status == .authorizedAlways)
    }

}
