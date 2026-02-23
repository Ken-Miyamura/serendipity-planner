import SwiftUI

struct ContentView: View {
    @StateObject private var preferenceService = PreferenceService()
    @StateObject private var favoriteService = FavoriteService()

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
        .environmentObject(favoriteService)
    }
}

struct MainTabView: View {
    @ObservedObject var locationService: LocationService
    @State private var selectedTab = 0

    private let tabIcons = ["house.fill", "clock.arrow.circlepath", "heart.fill", "gearshape.fill"]
    private let tabColors: [Color] = [
        Color(red: 0.65, green: 0.52, blue: 0.42), // ホーム: ペールブラウン
        Color(red: 0.45, green: 0.68, blue: 0.58), // 履歴: ペールグリーン
        Color(red: 0.82, green: 0.52, blue: 0.62), // お気に入り: ペールピンク
        Color(red: 0.35, green: 0.35, blue: 0.38) // 設定: ペールブラック
    ]
    private let inactiveColor = Color(red: 0.70, green: 0.68, blue: 0.65)

    var body: some View {
        VStack(spacing: 0) {
            // コンテンツ — switch で切り替え（frame 制約なし）
            switch selectedTab {
            case 1: HistoryView()
            case 2: FavoritesView()
            case 3: SettingsView()
            default: HomeView(locationService: locationService)
            }

            // カスタムタブバー
            HStack(spacing: 0) {
                ForEach(0 ..< tabIcons.count, id: \.self) { index in
                    Button {
                        selectedTab = index
                    } label: {
                        Image(systemName: tabIcons[index])
                            .font(.system(size: 22))
                            .foregroundColor(selectedTab == index ? tabColors[index] : inactiveColor)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(tabAccessibilityLabel(for: index))
                }
            }
            .background(
                Color(red: 0.97, green: 0.96, blue: 0.94)
                    .ignoresSafeArea(.container, edges: .bottom)
            )
        }
    }

    private func tabAccessibilityLabel(for index: Int) -> String {
        switch index {
        case 0: "ホーム"
        case 1: "履歴"
        case 2: "お気に入り"
        case 3: "設定"
        default: ""
        }
    }
}
