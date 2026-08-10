import Foundation

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var currentPage = 0
    @Published var calendarPermissionGranted = false
    @Published var notificationPermissionGranted = false
    @Published var selectedInterests: Set<SuggestionCategory> = Set(SuggestionCategory.allCases)
    /// 権限エラーがどの権限のものかを表す。
    /// 以前は文言に "カレンダー" が含まれるかで判定していたため、翻訳すると壊れた。
    enum PermissionKind { case calendar, notification }

    @Published var permissionError: String?
    @Published private(set) var permissionErrorKind: PermissionKind?

    let totalPages = 5

    private let calendarService: CalendarServiceProtocol
    private let notificationService: NotificationServiceProtocol

    init(
        calendarService: CalendarServiceProtocol = CalendarService(),
        notificationService: NotificationServiceProtocol = NotificationService()
    ) {
        self.calendarService = calendarService
        self.notificationService = notificationService
    }

    var canProceed: Bool {
        // Interest selection page requires at least 3 selections
        if currentPage == 1 {
            return selectedInterests.count >= 3
        }
        return true
    }

    var isLastPage: Bool {
        currentPage == totalPages - 1
    }

    func nextPage() {
        guard currentPage < totalPages - 1 else { return }
        currentPage += 1
    }

    func previousPage() {
        guard currentPage > 0 else { return }
        currentPage -= 1
    }

    func toggleInterest(_ category: SuggestionCategory) {
        if selectedInterests.contains(category) {
            selectedInterests.remove(category)
        } else {
            selectedInterests.insert(category)
        }
    }

    func saveInterests(to preferenceService: PreferenceServiceProtocol) {
        preferenceService.updatePreferredCategories(Array(selectedInterests))
    }

    func requestCalendarPermission() async {
        permissionError = nil
        permissionErrorKind = nil
        do {
            let granted = try await calendarService.requestAccess()
            calendarPermissionGranted = granted
            if !granted {
                permissionError = String(localized: "カレンダーへのアクセスが拒否されました。設定アプリから許可してください。")
                permissionErrorKind = .calendar
            }
        } catch {
            calendarPermissionGranted = false
            permissionError = String(localized: "カレンダーの権限取得に失敗しました: \(error.localizedDescription)")
            permissionErrorKind = .calendar
        }
    }

    func requestNotificationPermission() async {
        permissionError = nil
        permissionErrorKind = nil
        do {
            let granted = try await notificationService.requestPermission()
            notificationPermissionGranted = granted
            if !granted {
                permissionError = String(localized: "通知が拒否されました。設定アプリから許可してください。")
                permissionErrorKind = .notification
            }
        } catch {
            notificationPermissionGranted = false
            permissionError = String(localized: "通知の権限取得に失敗しました: \(error.localizedDescription)")
            permissionErrorKind = .notification
        }
    }
}
