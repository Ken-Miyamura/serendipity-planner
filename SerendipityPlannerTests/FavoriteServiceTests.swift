@testable import SerendipityPlanner
import XCTest

final class FavoriteServiceTests: XCTestCase {
    private var sut: FavoriteService!
    private var testDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        testDefaults = UserDefaults(suiteName: "FavoriteServiceTests")!
        testDefaults.removePersistentDomain(forName: "FavoriteServiceTests")
        sut = FavoriteService(defaults: testDefaults)
    }

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: "FavoriteServiceTests")
        testDefaults = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - 追加テスト

    func testAddFavorite() {
        let suggestion = Suggestion.mock(category: .cafe, title: "テストカフェ")

        let favorite = sut.addFavorite(suggestion)

        XCTAssertEqual(sut.getFavorites().count, 1)
        XCTAssertEqual(favorite.title, "テストカフェ")
        XCTAssertEqual(favorite.category, .cafe)
    }

    func testAddMultipleFavorites() {
        let suggestion1 = Suggestion.mock(category: .cafe, title: "カフェ1")
        let suggestion2 = Suggestion.mock(category: .walk, title: "散歩1")

        sut.addFavorite(suggestion1)
        sut.addFavorite(suggestion2)

        XCTAssertEqual(sut.getFavorites().count, 2)
        // 新しいものが先頭に来る
        XCTAssertEqual(sut.getFavorites().first?.title, "散歩1")
    }

    func testAddFavoriteWithNearbyPlace() {
        var suggestion = Suggestion.mock(category: .cafe, title: "場所付きカフェ")
        suggestion.nearbyPlace = NearbyPlace(
            name: "テストカフェ店", category: .cafe,
            latitude: 35.6812, longitude: 139.7671, distance: 200
        )

        let favorite = sut.addFavorite(suggestion)

        XCTAssertEqual(favorite.placeName, "テストカフェ店")
        XCTAssertEqual(favorite.latitude, 35.6812)
        XCTAssertEqual(favorite.longitude, 139.7671)
    }

    // MARK: - 削除テスト

    func testRemoveFavorite() {
        let suggestion = Suggestion.mock(category: .cafe, title: "削除テスト")
        let favorite = sut.addFavorite(suggestion)

        sut.removeFavorite(id: favorite.id)

        XCTAssertTrue(sut.getFavorites().isEmpty)
    }

    func testRemoveSpecificFavorite() {
        let suggestion1 = Suggestion.mock(category: .cafe, title: "残す")
        let suggestion2 = Suggestion.mock(category: .walk, title: "削除する")

        sut.addFavorite(suggestion1)
        let favorite2 = sut.addFavorite(suggestion2)

        sut.removeFavorite(id: favorite2.id)

        XCTAssertEqual(sut.getFavorites().count, 1)
        XCTAssertEqual(sut.getFavorites().first?.title, "残す")
    }

    func testRemoveAll() {
        sut.addFavorite(Suggestion.mock(category: .cafe, title: "カフェ"))
        sut.addFavorite(Suggestion.mock(category: .walk, title: "散歩"))
        sut.addFavorite(Suggestion.mock(category: .reading, title: "読書"))

        sut.removeAll()

        XCTAssertTrue(sut.getFavorites().isEmpty)
    }

    // MARK: - 判定テスト

    func testIsFavorite() {
        let suggestion = Suggestion.mock(category: .cafe, title: "お気に入りカフェ")
        sut.addFavorite(suggestion)

        XCTAssertTrue(sut.isFavorite(title: "お気に入りカフェ", category: .cafe))
        XCTAssertFalse(sut.isFavorite(title: "お気に入りカフェ", category: .walk))
        XCTAssertFalse(sut.isFavorite(title: "存在しないカフェ", category: .cafe))
    }

    // MARK: - フィルタリングテスト

    func testGetFavoritesForCategory() {
        sut.addFavorite(Suggestion.mock(category: .cafe, title: "カフェ1"))
        sut.addFavorite(Suggestion.mock(category: .walk, title: "散歩1"))
        sut.addFavorite(Suggestion.mock(category: .cafe, title: "カフェ2"))

        let cafeFavorites = sut.getFavorites(for: .cafe)

        XCTAssertEqual(cafeFavorites.count, 2)
        XCTAssertTrue(cafeFavorites.allSatisfy { $0.category == .cafe })
    }

    func testFavoritedCategories() {
        sut.addFavorite(Suggestion.mock(category: .cafe, title: "カフェ"))
        sut.addFavorite(Suggestion.mock(category: .walk, title: "散歩"))
        sut.addFavorite(Suggestion.mock(category: .cafe, title: "カフェ2"))

        let categories = sut.favoritedCategories()

        XCTAssertEqual(categories.count, 2)
        XCTAssertTrue(categories.contains(.cafe))
        XCTAssertTrue(categories.contains(.walk))
    }

    // MARK: - 永続化テスト

    func testPersistence() {
        sut.addFavorite(Suggestion.mock(category: .cafe, title: "永続化テスト"))

        // 新しいインスタンスで読み込み
        let newService = FavoriteService(defaults: testDefaults)

        XCTAssertEqual(newService.getFavorites().count, 1)
        XCTAssertEqual(newService.getFavorites().first?.title, "永続化テスト")
    }

    func testPersistenceAfterRemove() {
        let favorite = sut.addFavorite(Suggestion.mock(category: .cafe, title: "永続化削除テスト"))
        sut.removeFavorite(id: favorite.id)

        let newService = FavoriteService(defaults: testDefaults)

        XCTAssertTrue(newService.getFavorites().isEmpty)
    }

    func testPersistenceAfterRemoveAll() {
        sut.addFavorite(Suggestion.mock(category: .cafe, title: "カフェ"))
        sut.addFavorite(Suggestion.mock(category: .walk, title: "散歩"))
        sut.removeAll()

        let newService = FavoriteService(defaults: testDefaults)

        XCTAssertTrue(newService.getFavorites().isEmpty)
    }
}
