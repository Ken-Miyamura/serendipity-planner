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

/// マップ経路の地点（出発点 / 到着点）。
struct MapPoint: Equatable {
    let name: String
    let latitude: Double
    let longitude: Double
}

extension TodayDestination {
    /// 「今日の目的地」を経路の出発点として使うための変換。
    var mapPoint: MapPoint {
        MapPoint(name: name, latitude: latitude, longitude: longitude)
    }
}

extension NearbyPlace {
    /// 提案スポットを経路の到着点として使うための変換。
    var mapPoint: MapPoint {
        MapPoint(name: name, latitude: latitude, longitude: longitude)
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

    /// 出発点と到着点を指定した徒歩経路としてマップアプリを開く。
    /// `origin` が nil のときは各アプリの「出発点未指定 = 現在地」仕様に委ねる。
    static func openDirections(_ app: MapApp, origin: MapPoint?, destination: MapPoint) {
        switch app {
        case .appleMaps:
            let originItem = origin.map(mapItem(for:)) ?? MKMapItem.forCurrentLocation()
            MKMapItem.openMaps(
                with: [originItem, mapItem(for: destination)],
                launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking]
            )
        case .googleMaps:
            guard let url = googleMapsURL(origin: origin, destination: destination) else { return }
            UIApplication.shared.open(url)
        case .browser:
            guard let url = browserURL(origin: origin, destination: destination) else { return }
            UIApplication.shared.open(url)
        }
    }

    // MARK: - 各アプリ向けの生成処理

    /// Apple マップ用の `MKMapItem`。名前を設定することで座標ではなく地点名が表示される。
    static func mapItem(for point: MapPoint) -> MKMapItem {
        let coordinate = CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
        let item = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        item.name = point.name
        return item
    }

    /// Google マップアプリ用の URL スキーム。
    /// `saddr` を空にすると現在地が出発点になる。
    /// https://developers.google.com/maps/documentation/urls/ios-urlscheme
    static func googleMapsURL(origin: MapPoint?, destination: MapPoint) -> URL? {
        var components = URLComponents()
        components.scheme = "comgooglemaps"
        components.host = ""
        components.queryItems = [
            URLQueryItem(name: "saddr", value: origin.map(coordinateQuery) ?? ""),
            URLQueryItem(name: "daddr", value: coordinateQuery(destination)),
            URLQueryItem(name: "directionsmode", value: "walking")
        ]
        return components.url
    }

    /// ブラウザ用の Universal cross-platform Maps URL（Directions 形式）。
    /// `origin` 省略時は Google 側で現在地が使われる。
    /// https://developers.google.com/maps/documentation/urls/get-started
    static func browserURL(origin: MapPoint?, destination: MapPoint) -> URL? {
        var components = URLComponents(string: "https://www.google.com/maps/dir/")
        var items = [URLQueryItem(name: "api", value: "1")]
        if let origin {
            items.append(URLQueryItem(name: "origin", value: coordinateQuery(origin)))
        }
        items.append(URLQueryItem(name: "destination", value: coordinateQuery(destination)))
        items.append(URLQueryItem(name: "travelmode", value: "walking"))
        components?.queryItems = items
        return components?.url
    }

    /// 経路指定に使う座標文字列。
    ///
    /// 地点名ではなく座標を渡すのは、チェーン店など同名スポットで別店舗にマッチするのを避けるため。
    /// 名前の可読性は `MKMapItem.name` を持つ Apple マップ側で担保し、Google 系は座標を優先する。
    /// 小数 6 桁（約 11cm）あれば徒歩経路の精度としては十分。
    private static func coordinateQuery(_ point: MapPoint) -> String {
        String(format: "%.6f,%.6f", point.latitude, point.longitude)
    }
}
