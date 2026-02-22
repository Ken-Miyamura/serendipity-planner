import SwiftUI
import MapKit

struct SuggestionDetailView: View {
    @StateObject private var viewModel: SuggestionDetailViewModel
    let onAccept: () -> Void
    let onRegenerate: () -> Void

    private let weather: WeatherData?
    private let preference: UserPreference
    private let preferenceService: PreferenceService?
    private let locationService: LocationService?
    private let calendarService: CalendarService?

    init(
        suggestion: Suggestion,
        weather: WeatherData?,
        preference: UserPreference,
        preferenceService: PreferenceService? = nil,
        locationService: LocationService? = nil,
        calendarService: CalendarService? = nil,
        onAccept: @escaping () -> Void,
        onRegenerate: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: {
            let vm = SuggestionDetailViewModel(suggestion: suggestion)
            vm.configure(weather: weather, preference: preference, preferenceService: preferenceService, locationService: locationService, calendarService: calendarService)
            return vm
        }())
        self.weather = weather
        self.preference = preference
        self.preferenceService = preferenceService
        self.locationService = locationService
        self.calendarService = calendarService
        self.onAccept = onAccept
        self.onRegenerate = onRegenerate
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
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
                if !viewModel.isAccepted && !viewModel.alternatives.isEmpty {
                    alternativesSection
                }
            }
            .padding()
        }
        .navigationTitle("提案の詳細")
        .navigationBarTitleDisplayMode(.inline)
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
                    .cornerRadius(12)
            }

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
                        Text("\(place.distanceText) ・ \(place.walkingTimeText)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button {
                        openInMaps(place: place)
                    } label: {
                        Image(systemName: "map.fill")
                            .font(.body)
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.theme.color(for: viewModel.suggestion.category))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.theme.secondaryBackground)
        .cornerRadius(12)
    }

    @ViewBuilder
    private var placeMapSection: some View {
        if let place = viewModel.suggestion.nearbyPlace {
            let coordinate = CLLocationCoordinate2D(
                latitude: place.latitude,
                longitude: place.longitude
            )
            let region = MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: 500,
                longitudinalMeters: 500
            )

            Map(coordinateRegion: .constant(region), annotationItems: [place]) { p in
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
            .onTapGesture {
                openInMaps(place: place)
            }
        }
    }

    private func openInMaps(place: NearbyPlace) {
        let coordinate = CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = place.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking,
        ])
    }

    private var alternativesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("他の候補")
                .font(.headline)

            ForEach(viewModel.alternatives) { alt in
                NavigationLink {
                    SuggestionDetailView(
                        suggestion: alt,
                        weather: weather,
                        preference: preference,
                        preferenceService: preferenceService,
                        locationService: locationService,
                        calendarService: calendarService,
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
}
