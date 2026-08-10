import CoreLocation
import SwiftUI

/// 目的地を選ぶシート。
/// エリア・駅・スポットを検索、または最近の検索・現在地周辺のおすすめエリアから選択できる。
/// 「現在地を使う」で目的地を解除し現在地ベースに戻す。
struct DestinationSearchView: View {
    let recentDestinations: [TodayDestination]
    /// おすすめエリア取得の基点となる現在地を返す（シート表示時に能動的に取得する）
    let locationProvider: () async -> CLLocation?
    let onSelect: (TodayDestination) -> Void
    let onUseCurrentLocation: () -> Void

    @StateObject private var viewModel = DestinationSearchViewModel()
    @Environment(\.dismiss) private var dismiss
    /// 候補の座標解決タスク。シートが閉じられたら破棄する（解決完了後に
    /// 目的地が勝手に確定してしまうのを防ぐ）。
    @State private var resolveTask: Task<Void, Never>?

    private let accent = Color.theme.walk
    /// design: 現在地アクションに使う珊瑚色(#F27A73)
    private let coral = Color(red: 0.949, green: 0.478, blue: 0.451)
    /// design: 検索フィールドの背景(#E9E6DF)
    private let searchFieldBackground = Color(red: 0.914, green: 0.902, blue: 0.875)

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

                if viewModel.isResolving {
                    resolvingOverlay
                }
            }
            .navigationTitle("目的地を選ぶ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(red: 0.486, green: 0.471, blue: 0.439))
                            .frame(width: 30, height: 30)
                            .background(Color(red: 0.906, green: 0.894, blue: 0.867))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("閉じる")
                }
            }
            .alert(
                "場所を取得できませんでした",
                isPresented: Binding(
                    get: { viewModel.resolveErrorMessage != nil },
                    set: { if !$0 { viewModel.resolveErrorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.resolveErrorMessage ?? "")
            }
            .task {
                let location = await locationProvider()
                await viewModel.loadRecommendedAreas(near: location)
            }
            .onDisappear {
                // 解決の完了を待たずに閉じられた場合、目的地を確定させない
                resolveTask?.cancel()
                resolveTask = nil
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - 検索フィールド

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            // IME 変換中は検索を走らせないため、素の TextField ではなく UITextField を包んで使う
            IMEAwareTextField(
                placeholder: String(localized: "エリア・駅・スポットを検索"),
                text: Binding(
                    get: { viewModel.query },
                    set: { viewModel.updateQuery($0) }
                ),
                onChange: { text, isComposing in
                    viewModel.updateQuery(text, isComposing: isComposing)
                }
            )
            .frame(height: 24)

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
        .background(searchFieldBackground)
        .cornerRadius(13)
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
                    .foregroundColor(coral)
                    .frame(width: 40, height: 40)
                    .background(coral.opacity(0.13))
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
            sectionHeader(String(localized: "最近の検索"))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(recentDestinations) { destination in
                        Button {
                            select(destination)
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.caption2)
                                    .foregroundColor(Color(red: 0.659, green: 0.643, blue: 0.608))
                                Text(destination.name)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.theme.cardBackground)
                            .cornerRadius(20)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - おすすめエリア（現在地ベース）

    @ViewBuilder
    private var recommendedSection: some View {
        if viewModel.isLoadingRecommendations {
            VStack(alignment: .leading, spacing: 10) {
                sectionHeader(String(localized: "この近くのおすすめ"))
                HStack(spacing: 8) {
                    ProgressView()
                    Text("近くの行き先を探しています...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
        } else if !viewModel.recommendedAreas.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                sectionHeader(String(localized: "この近くのおすすめ"))
                VStack(spacing: 8) {
                    ForEach(viewModel.recommendedAreas) { area in
                        Button {
                            select(area)
                        } label: {
                            areaRow(name: area.name, detail: area.subtitle)
                        }
                        .buttonStyle(.plain)
                    }
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
            } else if viewModel.candidates.isEmpty {
                // IME 変換中は確定を待つ。ここで「見つかりません」を出すと
                // 日本語入力の変換中ずっと表示されてしまう。
                if !viewModel.isComposing {
                    Text("該当する場所が見つかりませんでした")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                }
            } else {
                ForEach(viewModel.candidates) { candidate in
                    Button {
                        resolveTask?.cancel()
                        resolveTask = Task { await selectCandidate(candidate) }
                    } label: {
                        areaRow(name: candidate.title, detail: candidate.subtitle)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isResolving)
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
            Image(systemName: "mappin")
                .font(.system(size: 17))
                .foregroundColor(accent)
                .frame(width: 38, height: 38)
                .background(accent.opacity(0.18))
                .cornerRadius(11)

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
                .foregroundColor(Color(red: 0.765, green: 0.753, blue: 0.722))
        }
        .padding(14)
        .background(Color.theme.cardBackground)
        .cornerRadius(14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name)、\(detail)")
    }

    private var resolvingOverlay: some View {
        ZStack {
            Color.black.opacity(0.12).ignoresSafeArea()
            VStack(spacing: 10) {
                ProgressView()
                Text("場所を確認しています...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(20)
            .background(Color.theme.cardBackground)
            .cornerRadius(14)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("場所を確認しています")
    }

    private func select(_ destination: TodayDestination) {
        onSelect(destination)
        dismiss()
    }

    /// 候補は座標を持たないため、選択時に解決してから確定する
    private func selectCandidate(_ candidate: DestinationCandidate) async {
        guard let destination = await viewModel.resolve(candidate) else { return }
        // 解決を待っている間にシートが閉じられていたら確定しない
        guard !Task.isCancelled else { return }
        select(destination)
    }
}
