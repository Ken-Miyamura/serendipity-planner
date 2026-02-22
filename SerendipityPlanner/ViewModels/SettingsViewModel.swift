import Foundation

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var notificationsEnabled: Bool = true
    @Published var morningNotificationEnabled: Bool = true
    @Published var morningNotificationHour: Int = 7
    @Published var beforeFreeTimeNotificationEnabled: Bool = true
    @Published var notificationLeadTime: Int = 15
    @Published var minimumFreeTime: Int = 30
    @Published var weekdayStartHour: Int = 8
    @Published var weekdayEndHour: Int = 20
    @Published var weekendStartHour: Int = 10
    @Published var weekendEndHour: Int = 22
    @Published var preferredCategories: Set<SuggestionCategory> = Set(SuggestionCategory.allCases)
    @Published var selectionCounts: [String: Int] = [:]

    private var preferenceService: PreferenceServiceProtocol?

    init(preferenceService: PreferenceServiceProtocol? = nil) {
        self.preferenceService = preferenceService
        if preferenceService != nil {
            loadSettings()
        }
    }

    func configure(with preferenceService: PreferenceServiceProtocol) {
        self.preferenceService = preferenceService
        loadSettings()
    }

    private func loadSettings() {
        guard let service = preferenceService else { return }
        notificationsEnabled = service.settings.notificationsEnabled
        morningNotificationEnabled = service.settings.morningNotificationEnabled
        morningNotificationHour = service.settings.morningNotificationHour
        beforeFreeTimeNotificationEnabled = service.settings.beforeFreeTimeNotificationEnabled
        notificationLeadTime = service.settings.notificationLeadTimeMinutes
        minimumFreeTime = service.preference.minimumFreeTimeMinutes
        weekdayStartHour = service.preference.activeHours.weekday.startHour
        weekdayEndHour = service.preference.activeHours.weekday.endHour
        weekendStartHour = service.preference.activeHours.weekend.startHour
        weekendEndHour = service.preference.activeHours.weekend.endHour
        preferredCategories = Set(service.preference.preferredCategories)
        selectionCounts = service.preference.selectionCounts
    }

    func saveNotificationSettings() {
        preferenceService?.updateNotificationEnabled(notificationsEnabled)
        preferenceService?.updateNotificationLeadTime(notificationLeadTime)
    }

    func saveMorningNotificationSettings() {
        preferenceService?.updateMorningNotificationEnabled(morningNotificationEnabled)
        preferenceService?.updateMorningNotificationHour(morningNotificationHour)
    }

    func saveBeforeFreeTimeNotificationSettings() {
        preferenceService?.updateBeforeFreeTimeNotificationEnabled(beforeFreeTimeNotificationEnabled)
    }

    var morningHourOptions: [Int] {
        Array(Constants.Notification.morningHourRange)
    }

    func morningHourDisplayText(_ hour: Int) -> String {
        "\(hour):00"
    }

    func saveMinimumFreeTime() {
        preferenceService?.updateMinimumFreeTime(minimumFreeTime)
    }

    func saveActiveHours() {
        let activeHours = ActiveHoursPreference(
            weekday: ActiveHoursConfig(startHour: weekdayStartHour, endHour: weekdayEndHour),
            weekend: ActiveHoursConfig(startHour: weekendStartHour, endHour: weekendEndHour)
        )
        preferenceService?.updateActiveHours(activeHours)
    }

    func hourDisplayText(_ hour: Int) -> String {
        "\(hour):00"
    }

    func endHourOptions(after startHour: Int) -> [Int] {
        Array((startHour + 1) ... 23)
    }

    var startHourOptions: [Int] {
        Array(0 ... 22)
    }

    func toggleCategory(_ category: SuggestionCategory) {
        if preferredCategories.contains(category) {
            // Don't allow removing the last category
            guard preferredCategories.count > 1 else { return }
            preferredCategories.remove(category)
        } else {
            preferredCategories.insert(category)
        }
        preferenceService?.updatePreferredCategories(Array(preferredCategories))
    }

    var totalSelectionCount: Int {
        selectionCounts.values.reduce(0, +)
    }

    func resetLearningData() {
        preferenceService?.resetLearningData()
        selectionCounts = [:]
    }

    func selectionCount(for category: SuggestionCategory) -> Int {
        selectionCounts[category.rawValue] ?? 0
    }

    var leadTimeOptions: [Int] {
        [5, 10, 15, 30, 60]
    }

    var minimumFreeTimeOptions: [Int] {
        [30, 45, 60, 90, 120]
    }

    func leadTimeDisplayText(_ minutes: Int) -> String {
        if minutes >= 60 {
            return "\(minutes / 60)時間前"
        }
        return "\(minutes)分前"
    }

    func freeTimeDisplayText(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            let remaining = minutes % 60
            if remaining > 0 {
                return "\(hours)時間\(remaining)分"
            }
            return "\(hours)時間"
        }
        return "\(minutes)分"
    }
}
