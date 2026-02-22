@testable import SerendipityPlanner
import XCTest

@MainActor
final class HistoryViewModelTests: XCTestCase {
    private var sut: HistoryViewModel!
    private var mockHistoryService: MockHistoryService!

    override func setUp() {
        super.setUp()
        mockHistoryService = MockHistoryService()
        sut = HistoryViewModel(historyService: mockHistoryService)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - データ読み込みテスト

    func testLoadDataEmpty() {
        sut.loadData()

        XCTAssertTrue(sut.histories.isEmpty)
        XCTAssertTrue(sut.categorySummary.isEmpty)
        XCTAssertTrue(sut.groupedHistories.isEmpty)
    }

    func testLoadDataWithHistories() {
        let today = Date()
        mockHistoryService.histories = [
            SuggestionHistory(
                suggestion: Suggestion.mock(category: .cafe, title: "カフェ1"),
                acceptedDate: today,
                placeName: "テストカフェ"
            ),
            SuggestionHistory(
                suggestion: Suggestion.mock(category: .walk, title: "散歩1"),
                acceptedDate: today
            )
        ]

        sut.loadData()

        XCTAssertEqual(sut.histories.count, 2)
        XCTAssertEqual(sut.categorySummary[.cafe], 1)
        XCTAssertEqual(sut.categorySummary[.walk], 1)
        XCTAssertFalse(sut.groupedHistories.isEmpty)
    }

    // MARK: - 月切り替えテスト

    func testGoToPreviousMonth() {
        let calendar = Calendar.current
        let currentMonth = sut.currentMonth

        sut.goToPreviousMonth()

        let expectedMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth)!
        XCTAssertTrue(calendar.isDate(sut.currentMonth, equalTo: expectedMonth, toGranularity: .month))
    }

    func testGoToNextMonthDisabledWhenCurrent() {
        // 現在月の場合、次の月に進めない
        let currentMonth = sut.currentMonth
        sut.goToNextMonth()

        let calendar = Calendar.current
        XCTAssertTrue(calendar.isDate(sut.currentMonth, equalTo: currentMonth, toGranularity: .month))
    }

    func testGoToNextMonthFromPreviousMonth() {
        let calendar = Calendar.current

        // まず前月に移動
        sut.goToPreviousMonth()
        let previousMonth = sut.currentMonth

        // 次月に移動（現在月に戻る）
        sut.goToNextMonth()
        let expectedMonth = calendar.date(byAdding: .month, value: 1, to: previousMonth)!
        XCTAssertTrue(calendar.isDate(sut.currentMonth, equalTo: expectedMonth, toGranularity: .month))
    }

    // MARK: - isCurrentMonth テスト

    func testIsCurrentMonth() {
        XCTAssertTrue(sut.isCurrentMonth)

        sut.goToPreviousMonth()
        XCTAssertFalse(sut.isCurrentMonth)
    }

    // MARK: - 表示テキストテスト

    func testMonthDisplayText() {
        let text = sut.monthDisplayText
        XCTAssertFalse(text.isEmpty)
        // 「年」と「月」が含まれていることを確認
        XCTAssertTrue(text.contains("年"))
        XCTAssertTrue(text.contains("月"))
    }

    func testDateHeaderText() {
        let date = Date()
        let text = sut.dateHeaderText(for: date)
        XCTAssertFalse(text.isEmpty)
        // 「月」と「日」が含まれていることを確認
        XCTAssertTrue(text.contains("月"))
        XCTAssertTrue(text.contains("日"))
    }

    func testTimeText() {
        let date = Date()
        let text = sut.timeText(for: date)
        XCTAssertFalse(text.isEmpty)
        // 「:」が含まれていることを確認（HH:mm形式）
        XCTAssertTrue(text.contains(":"))
    }

    // MARK: - totalCount テスト

    func testTotalCount() {
        XCTAssertEqual(sut.totalCount, 0)

        mockHistoryService.histories = [
            SuggestionHistory(
                suggestion: Suggestion.mock(category: .cafe, title: "カフェ1"),
                acceptedDate: Date()
            )
        ]
        sut.loadData()

        XCTAssertEqual(sut.totalCount, 1)
    }

    // MARK: - sortedCategorySummary テスト

    func testSortedCategorySummary() {
        let today = Date()
        mockHistoryService.histories = [
            SuggestionHistory(
                suggestion: Suggestion.mock(category: .cafe, title: "カフェ1"),
                acceptedDate: today
            ),
            SuggestionHistory(
                suggestion: Suggestion.mock(category: .cafe, title: "カフェ2"),
                acceptedDate: today
            ),
            SuggestionHistory(
                suggestion: Suggestion.mock(category: .walk, title: "散歩1"),
                acceptedDate: today
            )
        ]

        sut.loadData()

        let sorted = sut.sortedCategorySummary
        XCTAssertEqual(sorted.first?.category, .cafe)
        XCTAssertEqual(sorted.first?.count, 2)
    }

    // MARK: - 日付グループ化テスト

    func testGroupedHistoriesByDate() {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        // 同月内で異なる日のデータ
        mockHistoryService.histories = [
            SuggestionHistory(
                suggestion: Suggestion.mock(category: .cafe, title: "今日のカフェ"),
                acceptedDate: today
            ),
            SuggestionHistory(
                suggestion: Suggestion.mock(category: .walk, title: "昨日の散歩"),
                acceptedDate: yesterday
            )
        ]

        sut.loadData()

        XCTAssertEqual(sut.groupedHistories.count, 2)
        // 新しい日が先頭
        let firstGroupDate = calendar.startOfDay(for: sut.groupedHistories[0].date)
        let todayStart = calendar.startOfDay(for: today)
        XCTAssertEqual(firstGroupDate, todayStart)
    }
}
