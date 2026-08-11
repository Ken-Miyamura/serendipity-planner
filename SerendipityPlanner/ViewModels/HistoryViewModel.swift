import Foundation

@MainActor
class HistoryViewModel: ObservableObject {
    @Published var currentMonth: Date = .init()
    @Published var histories: [SuggestionHistory] = []
    @Published var categorySummary: [SuggestionCategory: Int] = [:]
    @Published var groupedHistories: [(date: Date, items: [SuggestionHistory])] = []

    private var historyService: HistoryServiceProtocol
    /// 日付表示に使うロケール。テストから固定するための注入口で、既定は端末設定。
    private let locale: Locale

    init(historyService: HistoryServiceProtocol = HistoryService(), locale: Locale = .current) {
        self.historyService = historyService
        self.locale = locale
    }

    // MARK: - データ読み込み

    func loadData() {
        histories = historyService.fetchHistories(for: currentMonth)
        categorySummary = historyService.categorySummary(for: currentMonth)
        groupedHistories = groupByDate(histories)
    }

    // MARK: - 月の切り替え

    func goToPreviousMonth() {
        guard let newMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) else { return }
        currentMonth = newMonth
        loadData()
    }

    func goToNextMonth() {
        guard let newMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) else { return }
        // 未来の月には進めない
        let calendar = Calendar.current
        if calendar.compare(newMonth, to: Date(), toGranularity: .month) == .orderedDescending {
            return
        }
        currentMonth = newMonth
        loadData()
    }

    var isCurrentMonth: Bool {
        let calendar = Calendar.current
        return calendar.isDate(currentMonth, equalTo: Date(), toGranularity: .month)
    }

    var monthDisplayText: String {
        // ja: 2026年8月 / en: August 2026
        DateFormatter.localized(template: "yMMMM", locale: locale).string(from: currentMonth)
    }

    var totalCount: Int {
        histories.count
    }

    // MARK: - ソートされたカテゴリサマリー

    var sortedCategorySummary: [(category: SuggestionCategory, count: Int)] {
        categorySummary
            .map { (category: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    // MARK: - 日付グループ化

    private func groupByDate(_ histories: [SuggestionHistory]) -> [(date: Date, items: [SuggestionHistory])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: histories) { history in
            calendar.startOfDay(for: history.acceptedDate)
        }
        return grouped
            .map { (date: $0.key, items: $0.value.sorted { $0.acceptedDate > $1.acceptedDate }) }
            .sorted { $0.date > $1.date }
    }

    // MARK: - 日付表示

    func dateHeaderText(for date: Date) -> String {
        // ja: 8月11日(火) / en: Tue, Aug 11
        DateFormatter.localized(template: "MMMdE", locale: locale).string(from: date)
    }

    func timeText(for date: Date) -> String {
        // 12/24時間表記はロケールの慣習に従う
        DateFormatter.localizedTime(locale: locale).string(from: date)
    }
}
