import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var preferenceService: PreferenceService
    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var favoriteService: FavoriteService
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showResetConfirmation = false
    @State private var showFavoriteClearConfirmation = false
    @State private var showDeleteHistoryConfirmation = false

    var body: some View {
        NavigationView {
            ZStack {
                SkyGradientView(weatherCondition: nil)
                Form {
                    // Location
                    Section(
                        header: Text("現在地"),
                        footer: Text("GPSから自動的に取得されます。天気と場所の提案に使用されます。")
                    ) {
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.accentColor)
                            Text(locationService.currentLocationName)
                            Spacer()
                        }
                    }

                    // Notifications
                    Section(header: Text("通知設定")) {
                        NavigationLink {
                            NotificationSettingsView(viewModel: viewModel)
                        } label: {
                            HStack {
                                Text("通知")
                                Spacer()
                                Text(viewModel.notificationsEnabled ? "オン" : "オフ")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    // Preferences
                    Section(header: Text("提案の設定")) {
                        // Minimum free time
                        Picker("最小空き時間", selection: $viewModel.minimumFreeTime) {
                            ForEach(viewModel.minimumFreeTimeOptions, id: \.self) { minutes in
                                Text(viewModel.freeTimeDisplayText(minutes)).tag(minutes)
                            }
                        }
                        .onChange(of: viewModel.minimumFreeTime) { _ in
                            viewModel.saveMinimumFreeTime()
                        }
                    }

                    // Weekday active hours
                    Section(header: Text("平日のアクティブ時間")) {
                        Picker("開始", selection: $viewModel.weekdayStartHour) {
                            ForEach(viewModel.startHourOptions, id: \.self) { hour in
                                Text(viewModel.hourDisplayText(hour)).tag(hour)
                            }
                        }
                        Picker("終了", selection: $viewModel.weekdayEndHour) {
                            ForEach(viewModel.endHourOptions(after: viewModel.weekdayStartHour), id: \.self) { hour in
                                Text(viewModel.hourDisplayText(hour)).tag(hour)
                            }
                        }
                    }
                    .onChange(of: viewModel.weekdayStartHour) { newValue in
                        if viewModel.weekdayEndHour <= newValue {
                            viewModel.weekdayEndHour = newValue + 1
                        }
                        viewModel.saveActiveHours()
                    }
                    .onChange(of: viewModel.weekdayEndHour) { _ in
                        viewModel.saveActiveHours()
                    }

                    // Weekend active hours
                    Section(header: Text("休日のアクティブ時間")) {
                        Picker("開始", selection: $viewModel.weekendStartHour) {
                            ForEach(viewModel.startHourOptions, id: \.self) { hour in
                                Text(viewModel.hourDisplayText(hour)).tag(hour)
                            }
                        }
                        Picker("終了", selection: $viewModel.weekendEndHour) {
                            ForEach(viewModel.endHourOptions(after: viewModel.weekendStartHour), id: \.self) { hour in
                                Text(viewModel.hourDisplayText(hour)).tag(hour)
                            }
                        }
                    }
                    .onChange(of: viewModel.weekendStartHour) { newValue in
                        if viewModel.weekendEndHour <= newValue {
                            viewModel.weekendEndHour = newValue + 1
                        }
                        viewModel.saveActiveHours()
                    }
                    .onChange(of: viewModel.weekendEndHour) { _ in
                        viewModel.saveActiveHours()
                    }

                    // Categories
                    Section(header: Text("提案カテゴリ")) {
                        ForEach(SuggestionCategory.allCases, id: \.self) { category in
                            Button {
                                viewModel.toggleCategory(category)
                            } label: {
                                HStack {
                                    Image(systemName: category.iconName)
                                        .foregroundColor(Color.theme.color(for: category))
                                    Text(category.displayName)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if viewModel.preferredCategories.contains(category) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.accentColor)
                                    }
                                }
                            }
                            .accessibilityLabel("\(category.displayName)、\(viewModel.preferredCategories.contains(category) ? "有効" : "無効")")
                            .accessibilityHint("タップで切り替え")
                        }
                    }

                    // Learning data
                    Section(
                        header: Text("学習データ"),
                        footer: Text("提案を受け入れるとカテゴリの出現率が調整されます。")
                    ) {
                        ForEach(SuggestionCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.iconName)
                                    .foregroundColor(Color.theme.color(for: category))
                                Text(category.displayName)
                                Spacer()
                                Text("\(viewModel.selectionCount(for: category))回")
                                    .foregroundColor(.secondary)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(category.displayName)、\(viewModel.selectionCount(for: category))回選択")
                        }

                        Button(role: .destructive) {
                            showResetConfirmation = true
                        } label: {
                            Text("好みをリセット")
                        }
                    }

                    // History data
                    Section(
                        header: Text("履歴データ"),
                        footer: Text("受け入れた提案の履歴をすべて削除します。この操作は取り消せません。")
                    ) {
                        Button(role: .destructive) {
                            showDeleteHistoryConfirmation = true
                        } label: {
                            Text("履歴データを削除")
                        }
                    }

                    // Favorites
                    Section(
                        header: Text("お気に入り"),
                        footer: Text("お気に入りに保存したすべての提案を削除します。")
                    ) {
                        Button(role: .destructive) {
                            showFavoriteClearConfirmation = true
                        } label: {
                            Text("お気に入りデータを削除")
                        }
                    }

                    // App info
                    Section(header: Text("アプリ情報")) {
                        HStack {
                            Text("バージョン")
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .hideFormBackground()
                .navigationTitle("設定")
                .onAppear {
                    viewModel.configure(with: preferenceService, favoriteService: favoriteService)
                }
                .alert("好みをリセット", isPresented: $showResetConfirmation) {
                    Button("リセット", role: .destructive) {
                        viewModel.resetLearningData()
                    }
                    Button("キャンセル", role: .cancel) {}
                } message: {
                    Text("学習データをリセットすると、提案の重み付けが初期状態に戻ります。")
                }
                .alert("履歴データを削除", isPresented: $showDeleteHistoryConfirmation) {
                    Button("削除", role: .destructive) {
                        viewModel.deleteAllHistories()
                    }
                    Button("キャンセル", role: .cancel) {}
                } message: {
                    Text("すべての履歴データが削除されます。この操作は取り消せません。")
                }
                .alert("お気に入りデータを削除", isPresented: $showFavoriteClearConfirmation) {
                    Button("削除", role: .destructive) {
                        viewModel.clearFavorites()
                    }
                    Button("キャンセル", role: .cancel) {}
                } message: {
                    Text("お気に入りに保存したすべての提案が削除されます。この操作は取り消せません。")
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}
