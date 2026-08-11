import MapKit
@testable import SerendipityPlanner
import XCTest

final class MapLauncherTests: XCTestCase {
    private let tokyoTower = MapPoint(name: "東京タワー", latitude: 35.658581, longitude: 139.745433)
    private let spot = MapPoint(name: "麻布 布袋家", latitude: 35.657000, longitude: 139.735000)

    /// `lat,lng(名前)` の名前部分。日本語と空白はパーセントエンコードされる。
    private let encodedSpotName = "(%E9%BA%BB%E5%B8%83%20%E5%B8%83%E8%A2%8B%E5%AE%B6)"
    private let encodedTowerName = "(%E6%9D%B1%E4%BA%AC%E3%82%BF%E3%83%AF%E3%83%BC)"

    // MARK: - Google マップ（アプリ）

    func testGoogleMapsURLWithOriginContainsWalkingDirections() {
        let url = MapLauncher.googleMapsURL(origin: tokyoTower, destination: spot)

        XCTAssertEqual(
            url?.absoluteString,
            "comgooglemaps://?saddr=35.658581,139.745433\(encodedTowerName)"
                + "&daddr=35.657000,139.735000\(encodedSpotName)"
                + "&directionsmode=walking"
        )
    }

    func testGoogleMapsURLWithoutOriginLeavesStartAddressEmpty() {
        let url = MapLauncher.googleMapsURL(origin: nil, destination: spot)

        // saddr が空 = 現在地が出発点（Google マップ側の仕様）
        XCTAssertEqual(
            url?.absoluteString,
            "comgooglemaps://?saddr=&daddr=35.657000,139.735000\(encodedSpotName)&directionsmode=walking"
        )
    }

    // MARK: - ブラウザ（Universal Maps URL）

    func testBrowserURLWithOriginUsesDirectionsFormat() {
        let url = MapLauncher.browserURL(origin: tokyoTower, destination: spot)

        XCTAssertEqual(
            url?.absoluteString,
            "https://www.google.com/maps/dir/?api=1"
                + "&origin=35.658581,139.745433\(encodedTowerName)"
                + "&destination=35.657000,139.735000\(encodedSpotName)"
                + "&travelmode=walking"
        )
    }

    func testBrowserURLWithoutOriginOmitsOriginParameter() {
        let url = MapLauncher.browserURL(origin: nil, destination: spot)

        // origin を省略すると Google 側で現在地が使われる
        XCTAssertEqual(
            url?.absoluteString,
            "https://www.google.com/maps/dir/?api=1"
                + "&destination=35.657000,139.735000\(encodedSpotName)"
                + "&travelmode=walking"
        )
    }

    // MARK: - 地点の解決は座標が担う

    func testCoordinatesArePreservedRegardlessOfName() {
        // 同じ座標・違う名前でも、座標部分は変わらない＝名前は表示用ラベルでしかない
        let renamed = MapPoint(name: "まったく別の名前", latitude: spot.latitude, longitude: spot.longitude)

        let googleURL = MapLauncher.googleMapsURL(origin: nil, destination: renamed)
        let browserURL = MapLauncher.browserURL(origin: nil, destination: renamed)

        XCTAssertTrue(googleURL?.absoluteString.contains("daddr=35.657000,139.735000(") == true)
        XCTAssertTrue(browserURL?.absoluteString.contains("destination=35.657000,139.735000(") == true)
    }

    // MARK: - 名前に空白・記号が含まれるケース

    func testSpotNameWithSymbolsCannotInjectExtraQueryParameters() {
        let messyName = MapPoint(
            name: "SHARE LOUNGE & Olive LOUNGE 渋谷 #1?a=b",
            latitude: 35.658034,
            longitude: 139.701636
        )

        let googleURL = MapLauncher.googleMapsURL(origin: nil, destination: messyName)
        let browserURL = MapLauncher.browserURL(origin: nil, destination: messyName)

        // クエリを区切る `&` `=` と、フラグメントを開始する `#` がエンコードされ、
        // 名前が別パラメータとして解釈されないこと
        let googleItems = queryItems(of: googleURL)
        XCTAssertEqual(googleItems.map(\.name), ["saddr", "daddr", "directionsmode"])
        XCTAssertEqual(googleItems.last?.value, "walking")
        XCTAssertEqual(
            googleItems.first(where: { $0.name == "daddr" })?.value,
            "35.658034,139.701636(SHARE LOUNGE & Olive LOUNGE 渋谷 #1?a=b)"
        )

        let browserItems = queryItems(of: browserURL)
        XCTAssertEqual(browserItems.map(\.name), ["api", "destination", "travelmode"])
        XCTAssertEqual(browserItems.last?.value, "walking")
        XCTAssertNil(browserURL?.fragment)
    }

    private func queryItems(of url: URL?) -> [URLQueryItem] {
        guard let url, let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return []
        }
        return components.queryItems ?? []
    }

    // MARK: - Apple マップ

    // MARK: - #40: ブラウザ経路の出発点

    /// 目的地が無くても現在地を出発点として明示すること。
    /// origin を省略すると Google マップ Web が自前で測位しに行き、
    /// そのとき travelmode=walking が無視されて車ルートで開いてしまう。
    func testBrowserURLFallsBackToCurrentLocationAsOrigin() throws {
        let currentLocation = MapPoint(name: nil, latitude: 35.681236, longitude: 139.767125)

        let url = try XCTUnwrap(MapLauncher.browserURL(origin: currentLocation, destination: spot))
        let query = try XCTUnwrap(url.query)

        XCTAssertTrue(query.contains("origin="), query)
        XCTAssertTrue(query.contains("35.681236,139.767125"), query)
        XCTAssertTrue(query.contains("travelmode=walking"), query)
    }

    /// 現在地には名前を付けないこと。
    /// "現在地" のような固定ラベルを載せると、ユーザーのマップアプリが別言語のときに
    /// そこだけ日本語が現れて不自然になる。
    func testUnnamedPointProducesCoordinatesOnly() throws {
        let unnamed = MapPoint(name: nil, latitude: 35.681236, longitude: 139.767125)

        let url = try XCTUnwrap(MapLauncher.browserURL(origin: unnamed, destination: spot))
        let decoded = url.absoluteString.removingPercentEncoding ?? url.absoluteString

        // 座標の直後に "(" が続かない = ラベルが付いていない
        XCTAssertFalse(decoded.contains("35.681236,139.767125("), decoded)
    }

    /// 空文字の名前もラベルとして出さないこと
    func testEmptyNameProducesCoordinatesOnly() throws {
        let empty = MapPoint(name: "", latitude: 35.681236, longitude: 139.767125)

        let url = try XCTUnwrap(MapLauncher.browserURL(origin: empty, destination: spot))
        let decoded = url.absoluteString.removingPercentEncoding ?? url.absoluteString

        XCTAssertFalse(decoded.contains("35.681236,139.767125()"), decoded)
    }

    /// 出発点も現在地も無い場合は従来どおり origin を省略すること
    func testBrowserURLStillOmitsOriginWhenNothingAvailable() throws {
        let url = try XCTUnwrap(MapLauncher.browserURL(origin: nil, destination: spot))
        let query = try XCTUnwrap(url.query)

        XCTAssertFalse(query.contains("origin="), query)
        XCTAssertTrue(query.contains("travelmode=walking"), query)
    }

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
