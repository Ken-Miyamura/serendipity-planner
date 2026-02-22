import Foundation

struct ActiveHoursConfig: Codable, Equatable {
    var startHour: Int
    var endHour: Int

    static let defaultWeekday = ActiveHoursConfig(startHour: 8, endHour: 20)
    static let defaultWeekend = ActiveHoursConfig(startHour: 10, endHour: 22)
}

struct ActiveHoursPreference: Codable, Equatable {
    var weekday: ActiveHoursConfig
    var weekend: ActiveHoursConfig

    static let `default` = ActiveHoursPreference(
        weekday: .defaultWeekday,
        weekend: .defaultWeekend
    )

    func config(for date: Date, holidays: Set<Date> = []) -> ActiveHoursConfig {
        let isRestDay = date.isWeekend || holidays.contains(date.startOfDay)
        return isRestDay ? weekend : weekday
    }
}

struct UserPreference: Codable, Equatable {
    var preferredCategories: [SuggestionCategory]
    var minimumFreeTimeMinutes: Int
    var activeHours: ActiveHoursPreference

    // Learning system: selection counts per category (keyed by rawValue)
    var selectionCounts: [String: Int]

    var totalSelectionCount: Int {
        selectionCounts.values.reduce(0, +)
    }

    static let `default` = UserPreference(
        preferredCategories: SuggestionCategory.allCases,
        minimumFreeTimeMinutes: 60,
        activeHours: .default,
        selectionCounts: [:]
    )

    /// Calculate learned weights with dynamic minimum guarantee per category
    func calculateLearnedWeights() -> [SuggestionCategory: Double] {
        let categories = preferredCategories
        let categoryCount = Double(categories.count)
        let minimumWeight = max(0.05, 1.0 / (categoryCount * 3.0))
        let total = totalSelectionCount

        guard total > 0 else {
            // No history yet — equal weights
            var weights = [SuggestionCategory: Double]()
            for category in categories {
                weights[category] = 1.0 / categoryCount
            }
            return weights
        }

        // Reserve minimum weight for each category, distribute the rest proportionally
        let reservedTotal = minimumWeight * categoryCount
        let distributable = 1.0 - reservedTotal

        var weights = [SuggestionCategory: Double]()
        for category in categories {
            let count = selectionCounts[category.rawValue] ?? 0
            let proportion = Double(count) / Double(total)
            weights[category] = minimumWeight + distributable * proportion
        }

        return weights
    }

    mutating func recordSelection(for category: SuggestionCategory) {
        selectionCounts[category.rawValue, default: 0] += 1
    }

    mutating func resetLearningData() {
        selectionCounts = [:]
    }

    func selectionCount(for category: SuggestionCategory) -> Int {
        selectionCounts[category.rawValue] ?? 0
    }

    init(
        preferredCategories: [SuggestionCategory],
        minimumFreeTimeMinutes: Int,
        activeHours: ActiveHoursPreference,
        selectionCounts: [String: Int]
    ) {
        self.preferredCategories = preferredCategories
        self.minimumFreeTimeMinutes = minimumFreeTimeMinutes
        self.activeHours = activeHours
        self.selectionCounts = selectionCounts
    }

    // MARK: - Migration

    /// Support decoding old format with preferredTimeRange
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        preferredCategories = try container.decode([SuggestionCategory].self, forKey: .preferredCategories)
        minimumFreeTimeMinutes = try container.decode(Int.self, forKey: .minimumFreeTimeMinutes)
        selectionCounts = try container.decode([String: Int].self, forKey: .selectionCounts)

        if let hours = try? container.decode(ActiveHoursPreference.self, forKey: .activeHours) {
            activeHours = hours
        } else {
            // Migration: old data had preferredTimeRange, use default activeHours
            activeHours = .default
        }
    }

    private enum CodingKeys: String, CodingKey {
        case preferredCategories
        case minimumFreeTimeMinutes
        case activeHours
        case selectionCounts
    }
}
