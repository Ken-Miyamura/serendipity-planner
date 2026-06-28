import SwiftUI

/// 目的地を選ぶシート。
/// エリア・駅・スポットを検索、または最近の検索・おすすめエリアから選択できる。
/// 「現在地を使う」で目的地を解除し現在地ベースに戻す。
struct DestinationSearchView: View {
    let recentDestinations: [TodayDestination]
    let recommendedAreas: [RecommendedArea]
    let onSelect: (TodayDestination) -> Void
    let onUseCurrentLocation: () -> Void

    @StateObject private var viewModel = DestinationSearchViewModel()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var searchFocused: Bool

    private let accent = Color.theme.walk

    var body: some View {
        NavigationView {
            ZStack {
                Color.theme.pageBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        searchField

                        if viewModel.query.trimmingCharacters(in: .whitespaces).isEmpty {
                            currentLocationButton
                            if !recentDestinations.isEmpty {
                                recentSection
                            }
                            recommendedSection
                        } else {
                            searchResultsSection
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("目的地を選ぶ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - 検索フィールド

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("エリア・駅・スポットを検索", text: Binding(
                get: { viewModel.query },
                set: { viewModel.updateQuery($0) }
            ))
            .focused($searchFocused)
            .autocorrectionDisabled()
            .submitLabel(.search)

            if !viewModel.query.isEmpty {
                Button {
                    viewModel.updateQuery("")
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("検索をクリア")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.theme.cardBackground)
        .cornerRadius(12)
    }

    // MARK: - 現在地を使う

    private var currentLocationButton: some View {
        Button {
            onUseCurrentLocation()
            dismiss()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "location.fill")
                    .font(.body)
                    .foregroundColor(accent)
                    .frame(width: 40, height: 40)
                    .background(accent.opacity(0.15))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("現在地を使う")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    Text("GPSから周辺のスポットを提案")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(14)
            .background(Color.theme.cardBackground)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .accessibilityHint("目的地を解除して現在地ベースに戻します")
    }

    // MARK: - 最近の検索

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("最近の検索")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(recentDestinations) { destination in
                        Button {
                            select(destination)
                        } label: {
                            Text(destination.name)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.theme.cardBackground)
                                .cornerRadius(16)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - おすすめエリア

    private var recommendedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("おすすめエリア")
            VStack(spacing: 8) {
                ForEach(recommendedAreas) { area in
                    Button {
                        select(area.toDestination())
                    } label: {
                        areaRow(name: area.name, detail: "\(area.region)・\(area.tagline)")
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - 検索結果

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if viewModel.isSearching {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("検索中...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            } else if viewModel.results.isEmpty {
                Text("該当する場所が見つかりませんでした")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(viewModel.results) { destination in
                    Button {
                        select(destination)
                    } label: {
                        areaRow(name: destination.name, detail: destination.subtitle)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Parts

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.secondary)
    }

    private func areaRow(name: String, detail: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "mappin.circle.fill")
                .font(.title3)
                .foregroundColor(accent)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                if !detail.isEmpty {
                    Text(detail)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding(14)
        .background(Color.theme.cardBackground)
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name)、\(detail)")
    }

    private func select(_ destination: TodayDestination) {
        onSelect(destination)
        dismiss()
    }
}
