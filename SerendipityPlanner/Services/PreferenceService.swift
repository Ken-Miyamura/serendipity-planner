import Combine
import Foundation

class PreferenceService: ObservableObject, PreferenceServiceProtocol {
    @Published var settings: UserSettings
    @Published var preference: UserPreference

    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        if let data = UserDefaults.standard.data(forKey: Constants.Storage.userSettingsKey),
           let decoded = try? JSONDecoder().decode(UserSettings.self, from: data) {
            self.settings = decoded
        } else {
            self.settings = .default
        }

        if let data = UserDefaults.standard.data(forKey: Constants.Storage.userPreferenceKey),
           let decoded = try? JSONDecoder().decode(UserPreference.self, from: data) {
            self.preference = decoded
        } else {
            self.preference = .default
        }

        applyUITestOverridesIfNeeded()
    }

    /// UI テストから起動状態を指定できるようにする。
    ///
    /// オンボーディングを毎回5ステップ踏むとテストが遅く、壊れやすくもなる。
    /// アプリ本体に持ち込む分岐はここだけに閉じ、保存もしない（起動ごとに揮発する）。
    private func applyUITestOverridesIfNeeded() {
        let arguments = ProcessInfo.processInfo.arguments
        guard arguments.contains("-uiTestSkipOnboarding") else { return }

        settings.hasCompletedOnboarding = true
        // 提案が出ない時間帯に撮影すると空状態しか見られないため、終日を活動時間にする
        preference.activeHours = ActiveHoursPreference(
            weekday: ActiveHoursConfig(startHour: 0, endHour: 23),
            weekend: ActiveHoursConfig(startHour: 0, endHour: 23)
        )
    }

    func saveSettings() {
        if let data = try? encoder.encode(settings) {
            defaults.set(data, forKey: Constants.Storage.userSettingsKey)
        }
    }

    func savePreference() {
        if let data = try? encoder.encode(preference) {
            defaults.set(data, forKey: Constants.Storage.userPreferenceKey)
        }
    }

    func completeOnboarding() {
        settings.hasCompletedOnboarding = true
        saveSettings()
    }

    func updateNotificationEnabled(_ enabled: Bool) {
        settings.notificationsEnabled = enabled
        saveSettings()
    }

    func updateNotificationLeadTime(_ minutes: Int) {
        settings.notificationLeadTimeMinutes = minutes
        saveSettings()
    }

    func updateMorningNotificationEnabled(_ enabled: Bool) {
        settings.morningNotificationEnabled = enabled
        saveSettings()
    }

    func updateMorningNotificationHour(_ hour: Int) {
        settings.morningNotificationHour = hour
        saveSettings()
    }

    func updateBeforeFreeTimeNotificationEnabled(_ enabled: Bool) {
        settings.beforeFreeTimeNotificationEnabled = enabled
        saveSettings()
    }

    func updatePreferredCategories(_ categories: [SuggestionCategory]) {
        preference.preferredCategories = categories
        savePreference()
    }

    func updateMinimumFreeTime(_ minutes: Int) {
        preference.minimumFreeTimeMinutes = minutes
        savePreference()
    }

    func updateActiveHours(_ activeHours: ActiveHoursPreference) {
        preference.activeHours = activeHours
        savePreference()
    }

    func recordSelection(for category: SuggestionCategory) {
        preference.recordSelection(for: category)
        savePreference()
    }

    func resetLearningData() {
        preference.resetLearningData()
        savePreference()
    }

    func resetAll() {
        settings = .default
        preference = .default
        saveSettings()
        savePreference()
    }
}
