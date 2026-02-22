import Foundation
import Combine

class PreferenceService: ObservableObject {
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
