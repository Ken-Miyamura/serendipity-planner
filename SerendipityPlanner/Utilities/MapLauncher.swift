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
        case .appleMaps: String(localized: "Apple マップ")
        case .googleMaps: String(localized: "Google マップ")
        case .browser: String(localized: "ブラウザで開く")
        }
    }
}

/// マップ経路の地点（出発点 / 到着点）。
struct MapPoint: Equatable {
    /// 表示用のラベル。現在地のように「名前を持たない地点」では nil。
    ///
    /// 現在地に "現在地" のような固定ラベルを付けると、ユーザーのマップアプリが
    /// 別言語のときにそこだけ日本語が現れて不自然になる。座標のみで渡す。
    let name: String?
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
    ///
    /// - Parameters:
    ///   - origin: 経路の出発点。nil のときは「現在地から」の意味になる。
    ///   - currentLocation: 解決済みの現在地の座標。**ブラウザ経路でのみ使う。**
    ///
    /// Apple マップと Google マップアプリは出発点を省略しても徒歩で開くため、
    /// `origin` が nil のままそれぞれの「未指定 = 現在地」仕様に委ねる。座標を
    /// 明示すると現在地としてではなく単なる地点として扱われ、追従もしなくなる。
    ///
    /// 一方ブラウザ（Google マップ Web）は `origin` を省略すると自前で測位しに行き、
    /// **そのとき `travelmode=walking` が無視されて車ルートで開く**。こちらだけは
    /// 現在地の座標を明示する必要がある。
    static func openDirections(
        _ app: MapApp,
        origin: MapPoint?,
        destination: MapPoint,
        currentLocation: MapPoint? = nil
    ) {
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
            // 出発点が無い場合だけ現在地で補う。それも取れなければ従来どおり省略する。
            let browserOrigin = origin ?? currentLocation
            guard let url = browserURL(origin: browserOrigin, destination: destination) else { return }
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
            URLQueryItem(name: "saddr", value: origin.map(labeledCoordinateQuery) ?? ""),
            URLQueryItem(name: "daddr", value: labeledCoordinateQuery(destination)),
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
            items.append(URLQueryItem(name: "origin", value: labeledCoordinateQuery(origin)))
        }
        items.append(URLQueryItem(name: "destination", value: labeledCoordinateQuery(destination)))
        items.append(URLQueryItem(name: "travelmode", value: "walking"))
        components?.queryItems = items
        return components?.url
    }

    /// 経路指定に使う座標文字列。小数 6 桁（約 11cm）あれば徒歩経路の精度としては十分。
    private static func coordinateQuery(_ point: MapPoint) -> String {
        String(format: "%.6f,%.6f", point.latitude, point.longitude)
    }

    /// 座標にラベルを添えた `lat,lng(名前)` 形式。名前が無ければ座標のみ。
    ///
    /// 地点の解決はあくまで座標が担い、名前は表示用のラベルとしてのみ渡す。
    /// 名前だけを検索させるとチェーン店などで別店舗にマッチする恐れがあるが、
    /// この形式なら座標で地点が確定するためその心配がない。
    /// 実機の Google マップアプリ / Google マップ Web の双方で、
    /// 正しい地点に着いたうえで地点名が表示されることを確認済み。
    private static func labeledCoordinateQuery(_ point: MapPoint) -> String {
        guard let name = point.name, !name.isEmpty else { return coordinateQuery(point) }
        return "\(coordinateQuery(point))(\(name))"
    }
}
