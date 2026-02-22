@testable import SerendipityPlanner
import XCTest

final class HistoryServiceTests: XCTestCase {
    private var sut: HistoryService!
    private var userDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        userDefaults = UserDefaults(suiteName: "HistoryServiceTests")!
        userDefaults.removePersistentDomain(forName: "HistoryServiceTests")
        sut = HistoryService(userDefaults: userDefaults)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: "HistoryServiceTests")
        sut = nil
        super.tearDown()
    }

    // MARK: - 保存・取得テスト

    func testSaveAndFetchHistory() {
        let suggestion = Suggestion.mock(category: .cafe, title: "テストカフェ")
        let history = SuggestionHistory(suggestion: suggestion, placeName: "スタバ渋谷")

        sut.saveHistory(history)

        let fetched = sut.fetchAllHistories()
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.suggestion.title, "テストカフェ")
        XCTAssertEqual(fetched.first?.placeName, "スタバ渋谷")
    }

    func testSaveMultipleHistories() {
        let suggestion1 = Suggestion.mock(category: .cafe, title: "カフェ1")
        let suggestion2 = Suggestion.mock(category: .walk, title: "散歩1")

        sut.saveHistory(SuggestionHistory(suggestion: suggestion1))
        sut.saveHistory(SuggestionHistory(suggestion: suggestion2))

        let fetched = sut.fetchAllHistories()
        XCTAssertEqual(fetched.count, 2)
    }

    func testFetchEmptyHistories() {
        let fetched = sut.fetchAllHistories()
        XCTAssertTrue(fetched.isEmpty)
    }

    // MARK: - 日付範囲フィルタリングテスト

    func testFetchHistoriesByDateRange() throws {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = try XCTUnwrap(calendar.date(byAdding: .day, value: -1, to: today))
        let twoDaysAgo = try XCTUnwrap(calendar.date(byAdding: .day, value: -2, to: today))

        let suggestion1 = Suggestion.mock(category: .cafe, title: "今日のカフェ")
        let suggestion2 = Suggestion.mock(category: .walk, title: "昨日の散歩")
        let suggestion3 = Suggestion.mock(category: .reading, title: "一昨日の読書")

        sut.saveHistory(SuggestionHistory(suggestion: suggestion1, acceptedDate: today))
        sut.saveHistory(SuggestionHistory(suggestion: suggestion2, acceptedDate: yesterday))
        sut.saveHistory(SuggestionHistory(suggestion: suggestion3, acceptedDate: twoDaysAgo))

        let fetched = sut.fetchHistories(from: yesterday, to: today)
        XCTAssertEqual(fetched.count, 2)
    }

    // MARK: - 月別取得テスト

    func testFetchHistoriesForMonth() throws {
        let calendar = Calendar.current
        let today = Date()

        let suggestion = Suggestion.mock(category: .cafe, title: "今月のカフェ")
        sut.saveHistory(SuggestionHistory(suggestion: suggestion, acceptedDate: today))

        let fetched = sut.fetchHistories(for: today)
        XCTAssertEqual(fetched.count, 1)

        // 先月のデータは含まれない
        let lastMonth = try XCTUnwrap(calendar.date(byAdding: .month, value: -1, to: today))
        let fetchedLastMonth = sut.fetchHistories(for: lastMonth)
        XCTAssertTrue(fetchedLastMonth.isEmpty)
    }

    // MARK: - 削除テスト

    func testDeleteHistory() {
        let suggestion = Suggestion.mock(category: .cafe, title: "削除テスト")
        let history = SuggestionHistory(suggestion: suggestion)

        sut.saveHistory(history)
        XCTAssertEqual(sut.fetchAllHistories().count, 1)

        sut.deleteHistory(history.id)
        XCTAssertTrue(sut.fetchAllHistories().isEmpty)
    }

    func testDeleteAllHistories() {
        let suggestion1 = Suggestion.mock(category: .cafe, title: "カフェ1")
        let suggestion2 = Suggestion.mock(category: .walk, title: "散歩1")

        sut.saveHistory(SuggestionHistory(suggestion: suggestion1))
        sut.saveHistory(SuggestionHistory(suggestion: suggestion2))
        XCTAssertEqual(sut.fetchAllHistories().count, 2)

        sut.deleteAllHistories()
        XCTAssertTrue(sut.fetchAllHistories().isEmpty)
    }

    // MARK: - カテゴリ集計テスト

    func testCategorySummary() {
        let today = Date()

        sut.saveHistory(SuggestionHistory(
            suggestion: Suggestion.mock(category: .cafe, title: "カフェ1"),
            acceptedDate: today
        ))
        sut.saveHistory(SuggestionHistory(
            suggestion: Suggestion.mock(category: .cafe, title: "カフェ2"),
            acceptedDate: today
        ))
        sut.saveHistory(SuggestionHistory(
            suggestion: Suggestion.mock(category: .walk, title: "散歩1"),
            acceptedDate: today
        ))

        let summary = sut.categorySummary(for: today)
        XCTAssertEqual(summary[.cafe], 2)
        XCTAssertEqual(summary[.walk], 1)
        XCTAssertNil(summary[.reading])
    }

    func testCategorySummaryEmptyMonth() throws {
        let calendar = Calendar.current
        let lastMonth = try XCTUnwrap(calendar.date(byAdding: .month, value: -1, to: Date()))

        let summary = sut.categorySummary(for: lastMonth)
        XCTAssertTrue(summary.isEmpty)
    }
}
