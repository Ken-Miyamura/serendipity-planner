import SwiftUI

/// 履歴画面のメインビュー
struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()

    private var useLightText: Bool {
        let period = TimePeriod.current()
        return period.prefersLightText
    }

    var body: some View {
        NavigationView {
            ZStack {
                SkyGradientView(weatherCondition: nil)

                if viewModel.histories.isEmpty {
                    VStack {
                        historyHeader
                        Spacer()
                        emptyStateView
                        Spacer()
                    }
                } else {
                    historyListView
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.loadData()
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - ヘッダー

    private var historyHeader: some View {
        VStack(spacing: 4) {
            Text("履歴")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(useLightText ? .white : .primary)
                .shadow(color: useLightText ? .black.opacity(0.3) : .clear, radius: 2, y: 1)

            monthNavigator
        }
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    // MARK: - 月切り替えナビゲーション

    private var monthNavigator: some View {
        HStack(spacing: 16) {
            Button {
                viewModel.goToPreviousMonth()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.caption)
                    .foregroundColor(useLightText ? .white.opacity(0.9) : .accentColor)
            }
            .accessibilityLabel("前の月")

            Text(viewModel.monthDisplayText)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(useLightText ? .white : .primary)

            Button {
                viewModel.goToNextMonth()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(viewModel.isCurrentMonth
                        ? (useLightText ? .white.opacity(0.4) : .secondary)
                        : (useLightText ? .white.opacity(0.9) : .accentColor))
            }
            .disabled(viewModel.isCurrentMonth)
            .accessibilityLabel("次の月")
        }
    }

    // MARK: - エンプティステート

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundColor(useLightText ? .white.opacity(0.8) : Color.theme.walk.opacity(0.8))

            Text("履歴がありません")
                .font(.headline)
                .foregroundColor(useLightText ? .white : .primary)

            Text("提案を受け入れると、\nここに履歴が表示されます。")
                .font(.subheadline)
                .foregroundColor(useLightText ? .white.opacity(0.7) : .secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - 履歴リスト

    private var historyListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                historyHeader

                // サマリーセクション
                HistorySummaryView(
                    categorySummary: viewModel.sortedCategorySummary,
                    totalCount: viewModel.totalCount
                )

                // 日付ごとのグループ化リスト
                ForEach(Array(viewModel.groupedHistories.enumerated()), id: \.element.date) { groupIndex, group in
                    VStack(alignment: .leading, spacing: 8) {
                        // 日付ヘッダー
                        Text(viewModel.dateHeaderText(for: group.date))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(useLightText ? .white.opacity(0.8) : .secondary)
                            .shadow(color: useLightText ? .black.opacity(0.3) : .clear, radius: 2, y: 1)
                            .padding(.leading, 4)

                        // 履歴行
                        ForEach(Array(group.items.enumerated()), id: \.element.id) { itemIndex, history in
                            HistoryRowView(
                                history: history,
                                timeText: viewModel.timeText(for: history.acceptedDate)
                            )
                            .staggeredAppear(index: groupIndex * 3 + itemIndex)
                        }
                    }
                }
            }
            .padding()
        }
    }
}
