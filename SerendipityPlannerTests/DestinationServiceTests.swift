@testable import SerendipityPlanner
import XCTest

final class DestinationServiceTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "DestinationServiceTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    // MARK: - 設定・解除

    func testSetDestinationStoresCurrent() {
        let service = DestinationService(defaults: defaults)
        let destination = TodayDestination.mock()

        service.setDestination(destination)

        XCTAssertEqual(service.currentDestination?.name, "鎌倉")
    }

    func testClearDestinationRemovesCurrent() {
        let service = DestinationService(defaults: defaults)
        service.setDestination(.mock())

        service.clearDestination()

        XCTAssertNil(service.currentDestination)
    }

    // MARK: - 永続化

    func testDestinationPersistsAcrossInstances() {
        let service = DestinationService(defaults: defaults)
        service.setDestination(.mock(name: "横浜"))

        let reloaded = DestinationService(defaults: defaults)

        XCTAssertEqual(reloaded.currentDestination?.name, "横浜")
    }

    // MARK: - 当日限定（翌日自動リセット）

    func testDestinationFromPreviousDayIsDiscardedOnLoad() {
        let yesterday = Date().adding(days: -1)
        let staleService = DestinationService(defaults: defaults)
        staleService.setDestination(.mock(name: "江ノ島", setDate: yesterday))

        // 別インスタンスで読み込むと、当日でないため破棄される
        let reloaded = DestinationService(defaults: defaults)

        XCTAssertNil(reloaded.currentDestination)
    }

    func testTodaysDestinationSurvivesReload() {
        let service = DestinationService(defaults: defaults)
        service.setDestination(.mock(name: "表参道", setDate: Date()))

        let reloaded = DestinationService(defaults: defaults)

        XCTAssertEqual(reloaded.currentDestination?.name, "表参道")
    }

    // MARK: - 最近の検索

    func testRecentDestinationsAreRecorded() {
        let service = DestinationService(defaults: defaults)
        service.setDestination(.mock(name: "鎌倉"))
        service.setDestination(.mock(name: "横浜"))

        XCTAssertEqual(service.recentDestinations.map(\.name), ["横浜", "鎌倉"])
    }

    func testRecentDestinationsDeduplicateByName() {
        let service = DestinationService(defaults: defaults)
        service.setDestination(.mock(name: "鎌倉"))
        service.setDestination(.mock(name: "横浜"))
        service.setDestination(.mock(name: "鎌倉"))

        XCTAssertEqual(service.recentDestinations.map(\.name), ["鎌倉", "横浜"])
    }

    func testRecentDestinationsAreCapped() {
        let service = DestinationService(defaults: defaults)
        for index in 0 ..< 10 {
            service.setDestination(.mock(name: "エリア\(index)"))
        }

        XCTAssertLessThanOrEqual(service.recentDestinations.count, 6)
        // 最新が先頭
        XCTAssertEqual(service.recentDestinations.first?.name, "エリア9")
    }
}
