import SwiftUI

// MARK: - 代替提案セクション

struct AlternativesSectionView: View {
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
