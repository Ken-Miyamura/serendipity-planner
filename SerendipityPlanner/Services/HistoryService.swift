import Foundation

/// 提案履歴の永続化と集計を行うサービス
class HistoryService: HistoryServiceProtocol {
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - 保存・取得

    func saveHistory(_ history: SuggestionHistory) {
        var histories = fetchAllHistories()
        histories.append(history)
        persist(histories)
    }

    func fetchAllHistories() -> [SuggestionHistory] {
        guard let data = userDefaults.data(forKey: Constants.Storage.suggestionHistoryKey),
              let histories = try? JSONDecoder().decode([SuggestionHistory].self, from: data)
        else {
            return []
        }
        return histories
    }

    func fetchHistories(from startDate: Date, to endDate: Date) -> [SuggestionHistory] {
        fetchAllHistories().filter { history in
            history.acceptedDate >= startDate && history.acceptedDate <= endDate
        }
    }

    func fetchHistories(for month: Date) -> [SuggestionHistory] {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: month),
              let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month))
        else {
            return []
        }
        let endOfMonth = calendar.date(byAdding: .day, value: range.count, to: startOfMonth) ?? startOfMonth
        return fetchHistories(from: startOfMonth, to: endOfMonth)
    }

    // MARK: - 削除

    func deleteHistory(_ id: UUID) {
        var histories = fetchAllHistories()
        histories.removeAll { $0.id == id }
        persist(histories)
    }

    func deleteAllHistories() {
        userDefaults.removeObject(forKey: Constants.Storage.suggestionHistoryKey)
    }

    // MARK: - 集計

    func categorySummary(for month: Date) -> [SuggestionCategory: Int] {
        let histories = fetchHistories(for: month)
        var summary: [SuggestionCategory: Int] = [:]
        for history in histories {
            summary[history.suggestion.category, default: 0] += 1
        }
        return summary
    }

    // MARK: - Private

    private func persist(_ histories: [SuggestionHistory]) {
        guard let data = try? JSONEncoder().encode(histories) else { return }
        userDefaults.set(data, forKey: Constants.Storage.suggestionHistoryKey)
    }
}
