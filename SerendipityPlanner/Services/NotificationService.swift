import Foundation
import UserNotifications

class NotificationService: NotificationServiceProtocol {
    private let center = UNUserNotificationCenter.current()

    func requestPermission() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .badge, .sound])
    }

    func isAuthorized() async -> Bool {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus == .authorized
    }

    func scheduleSuggestionNotification(
        for suggestion: Suggestion,
        leadTimeMinutes: Int = Constants.Notification.defaultLeadTimeMinutes
    ) {
        let content = UNMutableNotificationContent()
        content.title = "セレンディピティ"
        content.body = "\(suggestion.freeTimeSlot.timeRangeText)に空き時間があります。\(suggestion.title)はいかがですか？"
        content.sound = .default
        content.categoryIdentifier = Constants.Notification.categoryIdentifier

        let triggerDate = suggestion.freeTimeSlot.startDate.adding(minutes: -leadTimeMinutes)
        guard triggerDate > Date() else { return }

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: suggestion.id.uuidString,
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    func scheduleMorningNotification(hour: Int, freeSlotCount: Int) {
        // Cancel existing morning notification first
        cancelMorningNotification()

        guard freeSlotCount > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "おはようございます ☀️"
        content.body = "今日の隙間時間：\(freeSlotCount)つ見つかりました。タップして提案を確認しましょう。"
        content.sound = .default
        content.categoryIdentifier = Constants.Notification.morningNotificationIdentifier

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: Constants.Notification.morningNotificationIdentifier,
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    func cancelMorningNotification() {
        center.removePendingNotificationRequests(
            withIdentifiers: [Constants.Notification.morningNotificationIdentifier]
        )
    }

    func cancelNotification(for suggestionId: UUID) {
        center.removePendingNotificationRequests(withIdentifiers: [suggestionId.uuidString])
    }

    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }
}
