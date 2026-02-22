import SwiftUI

struct ContentView: View {
    @StateObject private var preferenceService = PreferenceService()

    var body: some View {
        let locationService = LocationService(preferenceService: preferenceService)
        Group {
            if preferenceService.settings.hasCompletedOnboarding {
                MainTabView(locationService: locationService)
            } else {
                OnboardingContainerView {
                    preferenceService.completeOnboarding()
                }
            }
        }
        .environmentObject(preferenceService)
        .environmentObject(locationService)
    }
}

struct MainTabView: View {
    @ObservedObject var locationService: LocationService

    var body: some View {
        TabView {
            HomeView(locationService: locationService)
                .tabItem {
                    Label("ホーム", systemImage: "house.fill")
                }

            SettingsView()
                .tabItem {
                    Label("設定", systemImage: "gearshape.fill")
                }
        }
    }
}
