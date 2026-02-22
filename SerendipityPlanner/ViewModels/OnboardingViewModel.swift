import Foundation

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var currentPage = 0
    @Published var calendarPermissionGranted = false
    @Published var notificationPermissionGranted = false
    @Published var selectedInterests: Set<SuggestionCategory> = [.cafe, .walk, .reading]

    let totalPages = 5

    private let calendarService = CalendarService()
    private let notificationService = NotificationService()

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

    func saveInterests(to preferenceService: PreferenceService) {
        preferenceService.updatePreferredCategories(Array(selectedInterests))
    }

    func requestCalendarPermission() async {
        do {
            calendarPermissionGranted = try await calendarService.requestAccess()
        } catch {
            calendarPermissionGranted = false
        }
    }

    func requestNotificationPermission() async {
        do {
            notificationPermissionGranted = try await notificationService.requestPermission()
        } catch {
            notificationPermissionGranted = false
        }
    }
}
