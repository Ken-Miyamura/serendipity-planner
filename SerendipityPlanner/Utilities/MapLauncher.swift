import Foundation
import MapKit
import UIKit

enum MapApp: String, Identifiable, CaseIterable {
    case appleMaps
    case googleMaps
    case browser

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .appleMaps: "Apple マップ"
        case .googleMaps: "Google マップ"
        case .browser: "ブラウザで開く"
        }
    }
}

enum MapLauncher {
    static func availableApps() -> [MapApp] {
        var apps: [MapApp] = [.appleMaps]
        if let url = URL(string: "comgooglemaps://"),
           UIApplication.shared.canOpenURL(url) {
            apps.append(.googleMaps)
        }
        apps.append(.browser)
        return apps
    }

    static func open(_ app: MapApp, name: String, latitude: Double, longitude: Double) {
        switch app {
        case .appleMaps:
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let item = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
            item.name = name
            item.openInMaps(launchOptions: [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
            ])
        case .googleMaps:
            let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            if let url = URL(string: "comgooglemaps://?q=\(encoded)&center=\(latitude),\(longitude)&zoom=16&directionsmode=walking") {
                UIApplication.shared.open(url)
            }
        case .browser:
            if let url = URL(string: "https://www.google.com/maps/search/?api=1&query=\(latitude),\(longitude)") {
                UIApplication.shared.open(url)
            }
        }
    }
}
