import CoreLocation
@testable import SerendipityPlanner
import XCTest

@MainActor
final class SuggestionDetailViewModelTests: XCTestCase {
    private var sut: SuggestionDetailViewModel!
    private var mockEngine: MockSuggestionEngine!
    private var mockPlaceSearch: MockPlaceSearchService!
    private var mockPreference: MockPreferenceService!
    private var mockLocation: MockLocationService!
    private var mockCalendar: MockCalendarService!

    override func setUp() {
        super.setUp()
        mockEngine = MockSuggestionEngine()
        mockPlaceSearch = MockPlaceSearchService()
        mockPreference = MockPreferenceService()
        mockLocation = MockLocationService()
        mockCalendar = MockCalendarService()

        let suggestion = Suggestion.mock()
        sut = SuggestionDetailViewModel(
            suggestion: suggestion,
            suggestionEngine: mockEngine,
            placeSearchService: mockPlaceSearch
        )
        sut.configure(
            weather: .mock(),
            preference: .default,
            preferenceService: mockPreference,
            locationService: mockLocation,
            calendarService: mockCalendar
        )
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - #40: ブラウザ経路の出発点に使う現在地

    /// スポットが既に埋まっていても現在地が解決されること。
    ///
    /// enrichWithPlace() は nearbyPlace があると早期 return するため、そこに
    /// 相乗りさせるとホーム画面でスポットが埋まっている通常の経路で現在地が
    /// 解決されず、ブラウザ経路の修正が効かなくなる。
    func testCurrentLocationResolvedEvenWhenPlaceAlreadyExists() async {
        var suggestion = Suggestion.mock(category: .cafe, title: "カフェ")
        suggestion.nearbyPlace = NearbyPlace(
            name: "既存スポット", category: .cafe,
            latitude: 35.0, longitude: 139.0, distance: 100
        )
        let location = MockLocationService()
        location.currentLocation = CLLocation(latitude: 35.681236, longitude: 139.767125)
        let vm = SuggestionDetailViewModel(
            suggestion: suggestion,
            suggestionEngine: mockEngine,
            placeSearchService: mockPlaceSearch
        )
        vm.configure(weather: .mock(), preference: .default, locationService: location)

        await vm.enrichIfNeeded()

        let point = try? XCTUnwrap(vm.currentLocationPoint)
        XCTAssertEqual(point?.latitude ?? 0, 35.681236, accuracy: 0.000001)
        XCTAssertEqual(point?.longitude ?? 0, 139.767125, accuracy: 0.000001)
        // 現在地は固有名を持たないのでラベルを付けない
        XCTAssertNil(point?.name ?? nil)
    }

    /// 目的地が設定されているときは現在地を解決しないこと（目的地が出発点になるため）
    func testCurrentLocationNotResolvedWhenDestinationIsSet() async {
        let location = MockLocationService()
        location.currentLocation = CLLocation(latitude: 35.681236, longitude: 139.767125)
        let vm = SuggestionDetailViewModel(
            suggestion: Suggestion.mock(category: .cafe, title: "カフェ"),
            suggestionEngine: mockEngine,
            placeSearchService: mockPlaceSearch
        )
        vm.configure(
            weather: .mock(), preference: .default,
            locationService: location, destination: .mock()
        )

        await vm.enrichIfNeeded()

        XCTAssertNil(vm.currentLocationPoint)
    }

    /// 現在地が取れないときは nil のままで、従来どおり origin 省略にフォールバックすること
    func testCurrentLocationStaysNilWhenUnavailable() async {
        let location = MockLocationService()
        location.currentLocation = nil
        let vm = SuggestionDetailViewModel(
            suggestion: Suggestion.mock(category: .cafe, title: "カフェ"),
            suggestionEngine: mockEngine,
            placeSearchService: mockPlaceSearch
        )
        vm.configure(weather: .mock(), preference: .default, locationService: location)

        await vm.enrichIfNeeded()

        XCTAssertNil(vm.currentLocationPoint)
    }

    // MARK: - Accept Tests

    func testAcceptRecordsSelection() {
        sut.accept()

        XCTAssertTrue(sut.isAccepted)
        XCTAssertTrue(sut.suggestion.isAccepted)
        XCTAssertEqual(mockPreference.recordSelectionCategories.count, 1)
        XCTAssertEqual(mockPreference.recordSelectionCategories.first, .cafe)
    }

    func testAcceptAddsToCalendar() {
        sut.accept()

        XCTAssertEqual(mockCalendar.addEventCallCount, 1)
        XCTAssertEqual(mockCalendar.addEventTitles.first, "テストカフェ")
        XCTAssertEqual(sut.calendarAlertMessage, "カレンダーに追加しました")
    }

    func testAcceptCalendarFailure() {
        mockCalendar.addEventError = NSError(domain: "test", code: 1)

        sut.accept()

        XCTAssertEqual(sut.calendarAlertMessage, "カレンダーへの追加に失敗しました")
    }

    func testAcceptWithoutCalendarService() {
        let suggestion = Suggestion.mock()
        let vm = SuggestionDetailViewModel(
            suggestion: suggestion,
            suggestionEngine: mockEngine,
            placeSearchService: mockPlaceSearch
        )
        vm.configure(
            weather: .mock(),
            preference: .default,
            preferenceService: mockPreference
        )

        vm.accept()

        XCTAssertTrue(vm.isAccepted)
        XCTAssertEqual(vm.calendarAlertMessage, "提案を受け入れました")
    }

    // MARK: - Destination-based Enrichment Tests

    func testEnrichUsesDestinationLocationWhenSet() async {
        // GPS は取れないが目的地が設定されている状況
        mockLocation.currentLocation = nil
        let destination = TodayDestination.mock(name: "鎌倉", latitude: 35.3192, longitude: 139.5466)
        let vm = SuggestionDetailViewModel(
            suggestion: .mock(),
            suggestionEngine: mockEngine,
            placeSearchService: mockPlaceSearch
        )
        vm.configure(
            weather: .mock(),
            preference: .default,
            locationService: mockLocation,
            destination: destination
        )
        mockPlaceSearch.findResult = NearbyPlace(
            name: "報国寺", category: .cafe,
            latitude: 35.32, longitude: 139.55, distance: 300
        )

        await vm.enrichIfNeeded()

        // 目的地座標を基点に検索される（GPS が nil でも enrich される）
        XCTAssertEqual(mockPlaceSearch.findCallCount, 1)
        XCTAssertEqual(mockPlaceSearch.lastFindLocation?.coordinate.latitude ?? 0, 35.3192, accuracy: 0.0001)
        XCTAssertEqual(mockPlaceSearch.lastFindLocation?.coordinate.longitude ?? 0, 139.5466, accuracy: 0.0001)
        XCTAssertEqual(vm.suggestion.nearbyPlace?.name, "報国寺")
    }

    func testEnrichUsesCurrentLocationWhenNoDestination() async {
        mockLocation.currentLocation = CLLocation(latitude: 35.68, longitude: 139.76)
        mockPlaceSearch.findResult = NearbyPlace(
            name: "テストカフェ", category: .cafe,
            latitude: 35.68, longitude: 139.76, distance: 200
        )

        // sut は setUp で目的地なし
        await sut.enrichIfNeeded()

        XCTAssertEqual(mockPlaceSearch.lastFindLocation?.coordinate.latitude ?? 0, 35.68, accuracy: 0.0001)
    }

    func testDestinationExposed() {
        XCTAssertNil(sut.destination)

        let destination = TodayDestination.mock(name: "横浜")
        let vm = SuggestionDetailViewModel(suggestion: .mock(), suggestionEngine: mockEngine, placeSearchService: mockPlaceSearch)
        vm.configure(weather: .mock(), preference: .default, destination: destination)

        XCTAssertEqual(vm.destination?.name, "横浜")
    }
}
