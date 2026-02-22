import Foundation

struct UserSettings: Codable {
    var hasCompletedOnboarding: Bool
    var notificationsEnabled: Bool
    var notificationLeadTimeMinutes: Int
    var morningNotificationEnabled: Bool
    var morningNotificationHour: Int
    var beforeFreeTimeNotificationEnabled: Bool

    static let `default` = UserSettings(
        hasCompletedOnboarding: false,
        notificationsEnabled: true,
        notificationLeadTimeMinutes: 15,
        morningNotificationEnabled: true,
        morningNotificationHour: 7,
        beforeFreeTimeNotificationEnabled: true
    )
}
