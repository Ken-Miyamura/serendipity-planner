import MapKit
import SwiftUI

struct SuggestionDetailView: View {
    @StateObject private var viewModel: SuggestionDetailViewModel
    let onAccept: () -> Void
    let onRegenerate: () -> Void

    @State private var showMapAppPicker = false
    @State private var pendingPlace: NearbyPlace?

    private let weather: WeatherData?
    private let preference: UserPreference
    private let preferenceService: PreferenceServiceProtocol?
    private let locationService: LocationServiceProtocol?
    private let calendarService: CalendarServiceProtocol?
    private let favoriteService: FavoriteServiceProtocol?
    private let destination: TodayDestination?

    init(
        suggestion: Suggestion,
        weather: WeatherData?,
        preference: UserPreference,
        preferenceService: PreferenceServiceProtocol? = nil,
        locationService: LocationServiceProtocol? = nil,
        calendarService: CalendarServiceProtocol? = nil,
        favoriteService: FavoriteServiceProtocol? = nil,
        destination: TodayDestination? = nil,
        onAccept: @escaping () -> Void,
        onRegenerate: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: {
            let vm = SuggestionDetailViewModel(suggestion: suggestion)
            vm.configure(
                weather: weather,
                preference: preference,
                preferenceService: preferenceService,
                locationService: locationService,
                calendarService: calendarService,
                favoriteService: favoriteService,
                destination: destination
            )
            return vm
        }())
        self.weather = weather
        self.preference = preference
        self.preferenceService = preferenceService
        self.locationService = locationService
        self.calendarService = calendarService
        self.favoriteService = favoriteService
        self.destination = destination
        self.onAccept = onAccept
        self.onRegenerate = onRegenerate
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 提案の出所（現在地 / 目的地）— ナビ直下に配置
                sourceBadge

                // Header
                headerSection

                // Description
                descriptionSection

                // Nearby place
                if viewModel.suggestion.nearbyPlace != nil {
                    placeSection
                    placeMapSection
                }

                // Weather context
                weatherSection

                // Action buttons
                if viewModel.isAccepted {
                    SuggestionAcceptedView()
                } else {
                    actionButtons
                }

                // Alternatives
                if !viewModel.isAccepted, !viewModel.alternatives.isEmpty {
                    alternativesSection
                }
            }
            .padding()
        }
        .navigationTitle("提案の詳細")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if favoriteService != nil {
                    Button {
                        viewModel.toggleFavorite()
                    } label: {
                        Image(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(viewModel.isFavorite ? Color(red: 0.82, green: 0.52, blue: 0.62) : .secondary)
                    }
                    .accessibilityLabel(viewModel.isFavorite ? "お気に入りから削除" : "お気に入りに追加")
                    .accessibilityHint("この提案のお気に入り状態を切り替えます")
                }
            }
        }
        .alert(
            viewModel.calendarAlertMessage ?? "",
            isPresented: Binding(
                get: { viewModel.calendarAlertMessage != nil },
                set: { if !$0 { viewModel.calendarAlertMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {
                onAccept()
            }
        }
        .confirmationDialog(
            "マップアプリで開く",
            isPresented: $showMapAppPicker,
            titleVisibility: .visible
        ) {
            if let place = pendingPlace {
                ForEach(MapLauncher.availableApps()) { app in
                    Button(app.displayName) {
                        MapLauncher.open(
                            app,
                            name: place.name,
                            latitude: place.latitude,
                            longitude: place.longitude
                        )
                    }
                }
                Button("キャンセル", role: .cancel) {}
            }
        }
        .task {
            await viewModel.enrichIfNeeded()
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: viewModel.suggestion.category.iconName)
                .font(.system(size: 48))
                .foregroundColor(Color.theme.color(for: viewModel.suggestion.category))
                .frame(width: 80, height: 80)
                .background(
                    Color.theme.color(for: viewModel.suggestion.category).opacity(0.1)
                )
                .cornerRadius(20)
                .accessibilityHidden(true)

            Text(viewModel.suggestion.title)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Label(
                    viewModel.suggestion.freeTimeSlot.timeRangeText,
                    systemImage: "clock"
                )
                Label(
                    "\(viewModel.suggestion.duration)分",
                    systemImage: "timer"
                )
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("詳細")
                .font(.headline)

            Text(viewModel.suggestion.description)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.theme.secondaryBackground)
        .cornerRadius(12)
    }

    private var weatherSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "cloud.sun")
                .foregroundColor(.orange)
            Text(viewModel.suggestion.weatherContext)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.theme.secondaryBackground)
        .cornerRadius(12)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                viewModel.accept()
            } label: {
                Text("この提案を受け入れる")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.theme.color(for: viewModel.suggestion.category))
                    .cornerRadius(14)
            }
            .accessibilityLabel("この提案を受け入れる")
            .accessibilityHint("提案をカレンダーに追加します")

            Button {
                viewModel.regenerate()
                onRegenerate()
            } label: {
                Text("別の提案を見る")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.theme.secondaryBackground)
                    .cornerRadius(12)
            }
            .accessibilityLabel("別の提案を見る")
            .accessibilityHint("新しい提案を生成します")
        }
    }

    private var placeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let place = viewModel.suggestion.nearbyPlace {
                HStack(spacing: 8) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(Color.theme.color(for: viewModel.suggestion.category))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(place.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("\(placeReferenceName)から\(place.walkingTimeText) ・ \(place.distanceText)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button {
                        presentMapPicker(for: place)
                    } label: {
                        Image(systemName: "map.fill")
                            .font(.body)
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.theme.color(for: viewModel.suggestion.category))
                            .cornerRadius(8)
                    }
                    .accessibilityLabel("マップで開く")
                    .accessibilityHint("\(place.name)をマップアプリで表示します")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.theme.cardBackground)
        .cornerRadius(16)
    }

    @ViewBuilder
    private var placeMapSection: some View {
        if let place = viewModel.suggestion.nearbyPlace {
            Button {
                presentMapPicker(for: place)
            } label: {
                mapPreview(for: place)
                    .overlay(alignment: .topTrailing) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.right.square.fill")
                            Text("マップで開く")
                        }
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.55))
                        .clipShape(Capsule())
                        .padding(8)
                    }
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(place.name)をマップで開く")
            .accessibilityAddTraits(.isButton)
        }
    }

    private var alternativesSection: some View {
        AlternativesSectionView(
            alternatives: viewModel.alternatives,
            weather: weather,
            preference: preference,
            preferenceService: preferenceService,
            locationService: locationService,
            calendarService: calendarService,
            favoriteService: favoriteService,
            destination: destination,
            onAccept: onAccept,
            onRegenerate: onRegenerate
        )
    }
}

// MARK: - マップ関連ヘルパー

private extension SuggestionDetailView {
    /// 「いまどこ基点の提案か」を示すバッジ（目的地名 or 現在地）
    var sourceBadge: some View {
        let accent = Color.theme.walk
        // design: 緑の塗り円(#469B75)に白いピン
        let pinCircle = Color(red: 0.275, green: 0.608, blue: 0.459)
        return HStack(spacing: 8) {
            Image(systemName: "mappin")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 22, height: 22)
                .background(pinCircle)
                .clipShape(Circle())

            Group {
                if let destination {
                    Text(destination.name)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        + Text(" 周辺から提案中")
                        .foregroundColor(accent)
                } else {
                    Text("現在地周辺から提案中")
                        .foregroundColor(accent)
                }
            }
            .font(.footnote)

            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [accent.opacity(0.16), accent.opacity(0.06)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(destination.map { "\($0.name)周辺から提案中" } ?? "現在地周辺から提案中")
    }

    /// 距離表記の基点ラベル（目的地名 or 現在地）
    var placeReferenceName: String {
        destination?.name ?? "現在地"
    }

    func mapPreview(for place: NearbyPlace) -> some View {
        let coordinate = CLLocationCoordinate2D(
            latitude: place.latitude,
            longitude: place.longitude
        )
        let region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 500,
            longitudinalMeters: 500
        )

        return Map(coordinateRegion: .constant(region), annotationItems: [place]) { p in
            MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: p.latitude, longitude: p.longitude)) {
                VStack(spacing: 2) {
                    Image(systemName: viewModel.suggestion.category.iconName)
                        .font(.caption)
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(Color.theme.color(for: viewModel.suggestion.category))
                        .clipShape(Circle())
                        .shadow(radius: 2)

                    Image(systemName: "triangle.fill")
                        .font(.system(size: 6))
                        .foregroundColor(Color.theme.color(for: viewModel.suggestion.category))
                        .rotationEffect(.degrees(180))
                        .offset(y: -4)
                }
            }
        }
        .frame(height: 180)
        .cornerRadius(12)
        .allowsHitTesting(false)
    }

    func presentMapPicker(for place: NearbyPlace) {
        pendingPlace = place
        showMapAppPicker = true
    }
}

// MARK: - 代替提案セクション

private struct AlternativesSectionView: View {
    let alternatives: [Suggestion]
    let weather: WeatherData?
    let preference: UserPreference
    let preferenceService: PreferenceServiceProtocol?
    let locationService: LocationServiceProtocol?
    let calendarService: CalendarServiceProtocol?
    let favoriteService: FavoriteServiceProtocol?
    let destination: TodayDestination?
    let onAccept: () -> Void
    let onRegenerate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader

            ForEach(alternatives) { alt in
                NavigationLink {
                    SuggestionDetailView(
                        suggestion: alt,
                        weather: weather,
                        preference: preference,
                        preferenceService: preferenceService,
                        locationService: locationService,
                        calendarService: calendarService,
                        favoriteService: favoriteService,
                        destination: destination,
                        onAccept: onAccept,
                        onRegenerate: onRegenerate
                    )
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: alt.category.iconName)
                            .foregroundColor(Color.theme.color(for: alt.category))
                            .frame(width: 36, height: 36)
                            .background(
                                Color.theme.color(for: alt.category).opacity(0.1)
                            )
                            .cornerRadius(8)

                        VStack(alignment: .leading) {
                            Text(alt.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            Text(alt.category.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.theme.secondaryBackground)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var sectionHeader: some View {
        if let destination {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(destination.name)の ほかの候補")
                    .font(.headline)
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.caption2)
                        .foregroundColor(Color.theme.walk)
                    Text("すべて\(destination.name)エリアから選んでいます")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        } else {
            Text("他の候補")
                .font(.headline)
        }
    }
}
