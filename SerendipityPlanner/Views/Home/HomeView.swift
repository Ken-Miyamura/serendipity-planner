import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var preferenceService: PreferenceService
    @StateObject private var viewModel = HomeViewModel()
    let locationService: LocationService

    var body: some View {
        NavigationView {
            ZStack {
                SkyGradientView(weatherCondition: viewModel.weather?.condition)
                    .animation(.easeInOut(duration: 1.2), value: viewModel.weather?.condition)

                if viewModel.isLoading && viewModel.suggestions.isEmpty && viewModel.acceptedSuggestions.isEmpty {
                    ProgressView("今日の空き時間を探しています...")
                        .tint(useLightText ? .white : nil)
                        .foregroundColor(useLightText ? .white : .primary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.errorMessage, viewModel.suggestions.isEmpty && viewModel.acceptedSuggestions.isEmpty {
                    ErrorStateView(message: error) {
                        Task { await viewModel.refresh() }
                    }
                } else if viewModel.suggestions.isEmpty && viewModel.acceptedSuggestions.isEmpty {
                    emptyStateView
                } else {
                    suggestionListView
                }
            }
            .navigationBarHidden(true)
            .task {
                viewModel.configure(with: preferenceService, locationService: locationService)
                locationService.requestPermission()
                await viewModel.loadData()
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Greeting Header

    private var useLightText: Bool {
        let period = TimePeriod.current()
        if period.prefersLightText { return true }
        if period == .goldenHour,
           viewModel.weather?.condition == .thunderstorm { return true }
        return false
    }

    private var greetingHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text(greetingText)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(useLightText ? .white : .primary)
                    .shadow(color: useLightText ? .black.opacity(0.3) : .clear, radius: 2, y: 1)
                    .lineSpacing(4)

                Spacer()

                if let weather = viewModel.weather {
                    WeatherBadgeView(weather: weather)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<10:
            return "おはようございます。\n今日、素敵な偶然が訪れますように"
        case 10..<17:
            return "今日、素敵な偶然が訪れますように"
        case 17..<21:
            return "今日の残り時間に、\n小さな幸運を見つけましょう"
        default:
            return "おつかれさまでした。\n明日も素敵な一日になりますように"
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 60))
                .foregroundColor(useLightText ? .white.opacity(0.8) : Color.theme.walk)
            Text("今日はゆっくりお過ごしください")
                .font(.headline)
                .foregroundColor(useLightText ? .white : .primary)
            Text("空き時間が見つかりませんでした。\n忙しい日も、ちょっと深呼吸を。")
                .font(.subheadline)
                .foregroundColor(useLightText ? .white.opacity(0.7) : .secondary)
                .multilineTextAlignment(.center)
            Button("再読み込み") {
                Task { await viewModel.refresh() }
            }
            .buttonStyle(.plain)
            .foregroundColor(useLightText ? .white.opacity(0.8) : Color.theme.walk)
        }
        .padding()
    }

    // MARK: - Suggestion List

    private var suggestionListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                greetingHeader

                if !viewModel.acceptedSuggestions.isEmpty {
                    acceptedSection
                }

                ForEach(viewModel.suggestions) { suggestion in
                    NavigationLink {
                        SuggestionDetailView(
                            suggestion: suggestion,
                            weather: viewModel.weather,
                            preference: preferenceService.preference,
                            preferenceService: preferenceService,
                            locationService: locationService,
                            calendarService: viewModel.calendarService,
                            onAccept: { viewModel.acceptSuggestion(suggestion) },
                            onRegenerate: {
                                viewModel.regenerateSuggestion(
                                    for: suggestion.freeTimeSlot,
                                    excluding: suggestion.category
                                )
                            }
                        )
                    } label: {
                        FreeTimeCardView(suggestion: suggestion)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }

    // MARK: - Accepted Section

    private var acceptedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("今日の予定")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(useLightText ? .white.opacity(0.8) : .secondary)

            ForEach(viewModel.acceptedSuggestions) { suggestion in
                AcceptedCardView(suggestion: suggestion)
            }
        }
    }
}
