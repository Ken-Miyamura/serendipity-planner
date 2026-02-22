@testable import SerendipityPlanner
import XCTest

@MainActor
final class FavoritesViewModelTests: XCTestCase {
    private var sut: FavoritesViewModel!
    private var mockFavoriteService: MockFavoriteService!

    override func setUp() {
        super.setUp()
        mockFavoriteService = MockFavoriteService()
        sut = FavoritesViewModel(favoriteService: mockFavoriteService)
    }

    override func tearDown() {
        sut = nil
        mockFavoriteService = nil
        super.tearDown()
    }

    // MARK: - 読み込みテスト

    func testLoadFavoritesEmpty() {
        sut.loadFavorites()

        XCTAssertTrue(sut.isEmpty)
        XCTAssertTrue(sut.favorites.isEmpty)
    }

    func testLoadFavoritesWithData() {
        mockFavoriteService.addFavorite(Suggestion.mock(category: .cafe, title: "カフェ"))
        mockFavoriteService.addFavorite(Suggestion.mock(category: .walk, title: "散歩"))

        sut.loadFavorites()

        XCTAssertEqual(sut.favorites.count, 2)
        XCTAssertFalse(sut.isEmpty)
    }

    // MARK: - フィルタリングテスト

    func testFilterByCategory() {
        mockFavoriteService.addFavorite(Suggestion.mock(category: .cafe, title: "カフェ1"))
        mockFavoriteService.addFavorite(Suggestion.mock(category: .walk, title: "散歩1"))
        mockFavoriteService.addFavorite(Suggestion.mock(category: .cafe, title: "カフェ2"))

        sut.filterByCategory(.cafe)

        XCTAssertEqual(sut.selectedCategory, .cafe)
        XCTAssertEqual(sut.favorites.count, 2)
        XCTAssertTrue(sut.favorites.allSatisfy { $0.category == .cafe })
    }

    func testFilterByCategoryNil() {
        mockFavoriteService.addFavorite(Suggestion.mock(category: .cafe, title: "カフェ"))
        mockFavoriteService.addFavorite(Suggestion.mock(category: .walk, title: "散歩"))

        sut.filterByCategory(.cafe)
        sut.filterByCategory(nil)

        XCTAssertNil(sut.selectedCategory)
        XCTAssertEqual(sut.favorites.count, 2)
    }

    func testFilterByToggleSameCategory() {
        mockFavoriteService.addFavorite(Suggestion.mock(category: .cafe, title: "カフェ"))
        mockFavoriteService.addFavorite(Suggestion.mock(category: .walk, title: "散歩"))

        sut.filterByCategory(.cafe)
        XCTAssertEqual(sut.selectedCategory, .cafe)

        // 同じカテゴリを再タップするとフィルタ解除
        sut.filterByCategory(.cafe)
        XCTAssertNil(sut.selectedCategory)
        XCTAssertEqual(sut.favorites.count, 2)
    }

    // MARK: - 削除テスト

    func testRemoveFavoriteAtOffsets() {
        mockFavoriteService.addFavorite(Suggestion.mock(category: .cafe, title: "カフェ"))
        mockFavoriteService.addFavorite(Suggestion.mock(category: .walk, title: "散歩"))
        sut.loadFavorites()

        sut.removeFavorite(at: IndexSet(integer: 0))

        XCTAssertEqual(sut.favorites.count, 1)
        XCTAssertEqual(mockFavoriteService.removeFavoriteCallCount, 1)
    }

    func testRemoveFavoriteById() {
        let favorite = mockFavoriteService.addFavorite(Suggestion.mock(category: .cafe, title: "カフェ"))
        sut.loadFavorites()

        sut.removeFavorite(id: favorite.id)

        XCTAssertTrue(sut.isEmpty)
        XCTAssertEqual(mockFavoriteService.removeFavoriteCallCount, 1)
    }

    // MARK: - カテゴリ一覧テスト

    func testAvailableCategories() {
        mockFavoriteService.addFavorite(Suggestion.mock(category: .cafe, title: "カフェ"))
        mockFavoriteService.addFavorite(Suggestion.mock(category: .walk, title: "散歩"))
        mockFavoriteService.addFavorite(Suggestion.mock(category: .cafe, title: "カフェ2"))
        sut.loadFavorites()

        let categories = sut.availableCategories

        XCTAssertEqual(categories.count, 2)
        XCTAssertTrue(categories.contains(.cafe))
        XCTAssertTrue(categories.contains(.walk))
    }

    // MARK: - フォーマットテスト

    func testFormattedDate() {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2025
        components.month = 3
        components.day = 15
        let date = calendar.date(from: components)!

        let formatted = sut.formattedDate(date)

        XCTAssertEqual(formatted, "2025/3/15")
    }

    // MARK: - configure テスト

    func testConfigure() {
        let newService = MockFavoriteService()
        newService.addFavorite(Suggestion.mock(category: .reading, title: "読書"))

        let vm = FavoritesViewModel()
        vm.configure(with: newService)

        XCTAssertEqual(vm.favorites.count, 1)
        XCTAssertEqual(vm.favorites.first?.title, "読書")
    }
}
