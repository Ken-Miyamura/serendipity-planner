import MapKit
@testable import SerendipityPlanner
import XCTest

final class MapLauncherTests: XCTestCase {
    private let tokyoTower = MapPoint(name: "東京タワー", latitude: 35.658581, longitude: 139.745433)
    private let spot = MapPoint(name: "麻布 布袋家", latitude: 35.657000, longitude: 139.735000)

    // MARK: - Google マップ（アプリ）

    func testGoogleMapsURLWithOriginContainsWalkingDirections() {
        let url = MapLauncher.googleMapsURL(origin: tokyoTower, destination: spot)

        XCTAssertEqual(
            url?.absoluteString,
            "comgooglemaps://?saddr=35.658581,139.745433&daddr=35.657000,139.735000&directionsmode=walking"
        )
    }

    func testGoogleMapsURLWithoutOriginLeavesStartAddressEmpty() {
        let url = MapLauncher.googleMapsURL(origin: nil, destination: spot)

        // saddr が空 = 現在地が出発点（Google マップ側の仕様）
        XCTAssertEqual(
            url?.absoluteString,
            "comgooglemaps://?saddr=&daddr=35.657000,139.735000&directionsmode=walking"
        )
    }

    // MARK: - ブラウザ（Universal Maps URL）

    func testBrowserURLWithOriginUsesDirectionsFormat() {
        let url = MapLauncher.browserURL(origin: tokyoTower, destination: spot)

        XCTAssertEqual(
            url?.absoluteString,
            "https://www.google.com/maps/dir/?api=1"
                + "&origin=35.658581,139.745433"
                + "&destination=35.657000,139.735000"
                + "&travelmode=walking"
        )
    }

    func testBrowserURLWithoutOriginOmitsOriginParameter() {
        let url = MapLauncher.browserURL(origin: nil, destination: spot)

        // origin を省略すると Google 側で現在地が使われる
        XCTAssertEqual(
            url?.absoluteString,
            "https://www.google.com/maps/dir/?api=1&destination=35.657000,139.735000&travelmode=walking"
        )
    }

    // MARK: - 名前に空白・記号が含まれるケース

    func testURLsAreNotBrokenBySpotNameContainingSpacesAndSymbols() {
        let messyName = MapPoint(
            name: "SHARE LOUNGE & Olive LOUNGE 渋谷 #1?a=b",
            latitude: 35.658034,
            longitude: 139.701636
        )

        let googleURL = MapLauncher.googleMapsURL(origin: messyName, destination: messyName)
        let browserURL = MapLauncher.browserURL(origin: messyName, destination: messyName)

        // 名前は URL に含めず座標のみを渡すため、どんな名前でもクエリが壊れない
        XCTAssertEqual(
            googleURL?.absoluteString,
            "comgooglemaps://?saddr=35.658034,139.701636&daddr=35.658034,139.701636&directionsmode=walking"
        )
        XCTAssertEqual(
            browserURL?.absoluteString,
            "https://www.google.com/maps/dir/?api=1"
                + "&origin=35.658034,139.701636"
                + "&destination=35.658034,139.701636"
                + "&travelmode=walking"
        )
    }

    // MARK: - Apple マップ

    func testMapItemCarriesNameAndCoordinate() {
        let item = MapLauncher.mapItem(for: spot)

        XCTAssertEqual(item.name, "麻布 布袋家")
        XCTAssertEqual(item.placemark.coordinate.latitude, 35.657000, accuracy: 0.000001)
        XCTAssertEqual(item.placemark.coordinate.longitude, 139.735000, accuracy: 0.000001)
    }

    // MARK: - MapPoint への変換

    func testTodayDestinationConvertsToMapPoint() {
        let destination = TodayDestination(
            name: "鎌倉",
            subtitle: "神奈川県 鎌倉市",
            latitude: 35.319,
            longitude: 139.550
        )

        XCTAssertEqual(
            destination.mapPoint,
            MapPoint(name: "鎌倉", latitude: 35.319, longitude: 139.550)
        )
    }

    func testNearbyPlaceConvertsToMapPoint() {
        let place = NearbyPlace(
            name: "麻布 布袋家",
            category: .gourmet,
            latitude: 35.657,
            longitude: 139.735,
            distance: 320
        )

        XCTAssertEqual(
            place.mapPoint,
            MapPoint(name: "麻布 布袋家", latitude: 35.657, longitude: 139.735)
        )
    }
}
