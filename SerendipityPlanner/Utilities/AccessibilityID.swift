import SwiftUI

/// UI テストから要素を指すための識別子。
///
/// `accessibilityLabel` は画面に出る文言そのもので**言語ごとに変わる**ため、
/// 5言語を横断するテストの目印には使えない。identifier は翻訳されないので、
/// 同じテストコードがどの言語でも動く。
///
/// ```swift
/// .accessibilityLabel("目的地を決める")        // fr では "Choisir une destination"
/// .accessibilityIdentifier(AccessibilityID.destinationCard)  // 常に同じ
/// ```
///
/// 文字列を本体とテストの2箇所に散らすと、片方だけ直したときに気づけない。
/// ここを唯一の定義とし、テストターゲットからも参照する。
enum AccessibilityID {
    // MARK: - タブ

    static func tab(_ index: Int) -> String {
        "tab.\(index)"
    }

    static let tabHome = tab(0)
    static let tabHistory = tab(1)
    static let tabFavorites = tab(2)
    static let tabSettings = tab(3)

    // MARK: - ホーム

    static let homeGreeting = "home.greeting"
    static let homeWeatherBadge = "home.weatherBadge"
    static let homeSectionTitle = "home.sectionTitle"
    static let homeLocationChip = "home.locationChip"
    static let homeEmptyState = "home.emptyState"
    static let homeReloadButton = "home.reloadButton"
    /// 提案カード。順番で指せるよう index を取る
    static func suggestionCard(_ index: Int) -> String {
        "home.suggestionCard.\(index)"
    }

    // MARK: - 目的地

    static let destinationCard = "destination.card"
    static let destinationChangeButton = "destination.changeButton"
    static let destinationSearchField = "destination.searchField"
    static let destinationUseCurrentLocation = "destination.useCurrentLocation"
    static let destinationCloseButton = "destination.closeButton"
    static func destinationCandidate(_ index: Int) -> String {
        "destination.candidate.\(index)"
    }

    static func destinationRecommendation(_ index: Int) -> String {
        "destination.recommendation.\(index)"
    }

    // MARK: - 提案詳細

    static let detailTitle = "detail.title"
    static let detailDescription = "detail.description"
    static let detailPlaceRow = "detail.placeRow"
    static let detailMapButton = "detail.mapButton"
    static let detailAcceptButton = "detail.acceptButton"
    static let detailFavoriteButton = "detail.favoriteButton"
    static let detailBackButton = "detail.backButton"

    // MARK: - マップアプリ選択シート

    static let mapPickerSheet = "mapPicker.sheet"
    static func mapPickerApp(_ index: Int) -> String {
        "mapPicker.app.\(index)"
    }

    static let mapPickerCancel = "mapPicker.cancel"

    // MARK: - 履歴 / お気に入り

    static let historyMonthLabel = "history.monthLabel"
    static let historyEmptyState = "history.emptyState"
    static let favoritesEmptyState = "favorites.emptyState"
    static func favoriteRow(_ index: Int) -> String {
        "favorites.row.\(index)"
    }

    // MARK: - 画面ルート

    //
    // 画面が表示されたことの判定に使う。個々の要素は Form の中で
    // スクロールしないと掴めないことがあるため、まずルートで待つ。

    static let screenHome = "screen.home"
    static let screenHistory = "screen.history"
    static let screenFavorites = "screen.favorites"
    static let screenSettings = "screen.settings"
    static let screenDetail = "screen.detail"
    static let screenDestinationSearch = "screen.destinationSearch"

    // MARK: - オンボーディング

    static let onboardingNextButton = "onboarding.nextButton"
    static func onboardingPage(_ index: Int) -> String {
        "onboarding.page.\(index)"
    }

    // MARK: - 設定

    static let settingsCategorySection = "settings.categorySection"
    static let settingsNotificationLink = "settings.notificationLink"
    static let settingsVersionRow = "settings.versionRow"
}

extension View {
    /// `AccessibilityID` を付ける。`.accessibilityIdentifier` の呼び出しを短くするだけ。
    func uiTestID(_ id: String) -> some View {
        accessibilityIdentifier(id)
    }
}
