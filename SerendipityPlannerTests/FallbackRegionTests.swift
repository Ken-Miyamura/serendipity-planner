@testable import SerendipityPlanner
import MapKit
import XCTest

/// 現在地が取れないときの検索リージョン（#34: 日本固定 → 端末の地域設定ベース）のテスト。
final class FallbackRegionTests: XCTestCase {
    func testJapanRegionIsCenteredOnJapan() {
        let region = MKCoordinateRegion.region(forCountryCode: "JP")

        XCTAssertEqual(region.center.latitude, 36.0, accuracy: 0.01)
        XCTAssertEqual(region.center.longitude, 137.5, accuracy: 0.01)
    }

    /// 配信対象地域それぞれに代表リージョンがあること（世界全体に落ちないこと）
    func testTargetRegionsAreMapped() {
        for code in ["JP", "KR", "US", "GB", "ES", "FR"] {
            let region = MKCoordinateRegion.region(forCountryCode: code)
            XCTAssertNotEqual(
                region.span.latitudeDelta,
                MKCoordinateRegion.world.span.latitudeDelta,
                "\(code) の代表リージョンが未定義で世界全体に落ちている"
            )
        }
    }

    /// 未知の地域では世界全体を返すこと。
    /// ここで日本を返すと、位置情報を許可していない海外ユーザーの検索基点が日本になる（#34 の元の不具合）。
    func testUnknownRegionFallsBackToWorldNotJapan() {
        let region = MKCoordinateRegion.region(forCountryCode: "ZZ")

        XCTAssertEqual(region.center.latitude, 0, accuracy: 0.01)
        XCTAssertEqual(region.center.longitude, 0, accuracy: 0.01)
        XCTAssertEqual(region.span.latitudeDelta, 180, accuracy: 0.01)
    }

    /// 地域が取れない場合も世界全体にフォールバックすること
    func testNilRegionFallsBackToWorld() {
        let region = MKCoordinateRegion.region(forCountryCode: nil)

        XCTAssertEqual(region.span.longitudeDelta, 360, accuracy: 0.01)
    }

    /// 各地域の span が有効範囲に収まっていること（不正値だと MapKit が黙って無視する）
    func testAllRegionSpansAreValid() {
        for code in ["JP", "KR", "US", "GB", "CA", "AU", "ES", "MX", "AR", "FR"] {
            let span = MKCoordinateRegion.region(forCountryCode: code).span
            XCTAssertGreaterThan(span.latitudeDelta, 0, "\(code) の span が不正")
            XCTAssertLessThanOrEqual(span.latitudeDelta, 180, "\(code) の span が範囲外")
            XCTAssertLessThanOrEqual(span.longitudeDelta, 360, "\(code) の span が範囲外")
        }
    }
}
