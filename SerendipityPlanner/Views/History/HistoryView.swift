import SwiftUI

/// 履歴画面のメインビュー
struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                SkyGradientView(weatherCondition: nil)

                if viewModel.histories.isEmpty {
                    emptyStateView
                } else {
                    historyListView
                }
            }
            .navigationTitle("履歴")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    monthNavigator
                }
            }
            .onAppear {
                viewModel.loadData()
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - 月切り替えナビゲーション

    private var monthNavigator: some View {
        HStack(spacing: 16) {
            Button {
                viewModel.goToPreviousMonth()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.caption)
                    .foregroundColor(.accentColor)
            }
            .accessibilityLabel("前の月")

            Text(viewModel.monthDisplayText)
                .font(.subheadline)
                .fontWeight(.medium)

            Button {
                viewModel.goToNextMonth()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(viewModel.isCurrentMonth ? .secondary : .accentColor)
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
                .foregroundColor(Color.theme.walk.opacity(0.8))

            Text("履歴がありません")
                .font(.headline)
                .foregroundColor(.primary)

            Text("提案を受け入れると、\nここに履歴が表示されます。")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - 履歴リスト

    private var historyListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // サマリーセクション
                HistorySummaryView(
                    categorySummary: viewModel.sortedCategorySummary,
                    totalCount: viewModel.totalCount
                )

                // 日付ごとのグループ化リスト
                ForEach(viewModel.groupedHistories, id: \.date) { group in
                    VStack(alignment: .leading, spacing: 8) {
                        // 日付ヘッダー
                        Text(viewModel.dateHeaderText(for: group.date))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)

                        // 履歴行
                        ForEach(group.items) { history in
                            HistoryRowView(
                                history: history,
                                timeText: viewModel.timeText(for: history.acceptedDate)
                            )
                        }
                    }
                }
            }
            .padding()
        }
    }
}
