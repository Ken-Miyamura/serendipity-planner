import Foundation

/// 「今日の目的地」を管理するサービス。
/// UserDefaults で永続化し、当日限定（日付が変わると自動的に解除）の振る舞いを持つ。
class DestinationService: ObservableObject, DestinationServiceProtocol {
    @Published private(set) var currentDestination: TodayDestination?
    @Published private(set) var recentDestinations: [TodayDestination] = []

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    /// 最近の検索の保持件数
    private let maxRecents = 6

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.currentDestination = loadValidCurrentDestination()
        self.recentDestinations = loadRecents()
    }

    // MARK: - DestinationServiceProtocol

    func setDestination(_ destination: TodayDestination) {
        currentDestination = destination
        saveCurrent()
        addToRecents(destination)
    }

    func clearDestination() {
        currentDestination = nil
        defaults.removeObject(forKey: Constants.Storage.todayDestinationKey)
    }

    func recommendedAreas() -> [RecommendedArea] {
        RecommendedArea.curated
    }

    // MARK: - Current Destination Persistence

    /// 保存済みの目的地を読み込む。当日でなければ破棄し、永続化からも削除する（翌日自動リセット）。
    private func loadValidCurrentDestination() -> TodayDestination? {
        guard let data = defaults.data(forKey: Constants.Storage.todayDestinationKey),
              let decoded = try? decoder.decode(TodayDestination.self, from: data)
        else {
            return nil
        }
        guard decoded.isValidForToday else {
            defaults.removeObject(forKey: Constants.Storage.todayDestinationKey)
            return nil
        }
        return decoded
    }

    private func saveCurrent() {
        guard let currentDestination,
              let data = try? encoder.encode(currentDestination) else { return }
        defaults.set(data, forKey: Constants.Storage.todayDestinationKey)
    }

    // MARK: - Recent Destinations Persistence

    private func loadRecents() -> [TodayDestination] {
        guard let data = defaults.data(forKey: Constants.Storage.recentDestinationsKey),
              let decoded = try? decoder.decode([TodayDestination].self, from: data)
        else {
            return []
        }
        return decoded
    }

    /// 最近の検索へ追加する。同名のものは重複させず先頭へ移動し、上限件数で打ち切る。
    private func addToRecents(_ destination: TodayDestination) {
        recentDestinations.removeAll { $0.name == destination.name }
        recentDestinations.insert(destination, at: 0)
        if recentDestinations.count > maxRecents {
            recentDestinations = Array(recentDestinations.prefix(maxRecents))
        }
        saveRecents()
    }

    private func saveRecents() {
        if let data = try? encoder.encode(recentDestinations) {
            defaults.set(data, forKey: Constants.Storage.recentDestinationsKey)
        }
    }
}
