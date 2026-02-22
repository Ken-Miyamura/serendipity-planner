import SwiftUI

struct NotificationSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        ZStack {
            SkyGradientView(weatherCondition: nil)
            Form {
            Section(header: Text("通知")) {
                Toggle("通知を有効にする", isOn: $viewModel.notificationsEnabled)
                    .onChange(of: viewModel.notificationsEnabled) { _ in
                        viewModel.saveNotificationSettings()
                    }
            }

            if viewModel.notificationsEnabled {
                // Morning summary notification
                Section(
                    header: Text("朝の概要通知"),
                    footer: Text("毎朝、今日の隙間時間の数をお知らせします。")
                ) {
                    Toggle("朝の通知を有効にする", isOn: $viewModel.morningNotificationEnabled)
                        .onChange(of: viewModel.morningNotificationEnabled) { _ in
                            viewModel.saveMorningNotificationSettings()
                        }

                    if viewModel.morningNotificationEnabled {
                        Picker("通知時刻", selection: $viewModel.morningNotificationHour) {
                            ForEach(viewModel.morningHourOptions, id: \.self) { hour in
                                Text(viewModel.morningHourDisplayText(hour)).tag(hour)
                            }
                        }
                        .onChange(of: viewModel.morningNotificationHour) { _ in
                            viewModel.saveMorningNotificationSettings()
                        }
                    }
                }

                // Before free time notification
                Section(
                    header: Text("隙間時間前の通知"),
                    footer: Text("空き時間の開始前に提案を通知します。")
                ) {
                    Toggle("隙間時間前に通知する", isOn: $viewModel.beforeFreeTimeNotificationEnabled)
                        .onChange(of: viewModel.beforeFreeTimeNotificationEnabled) { _ in
                            viewModel.saveBeforeFreeTimeNotificationSettings()
                        }

                    if viewModel.beforeFreeTimeNotificationEnabled {
                        Picker("通知タイミング", selection: $viewModel.notificationLeadTime) {
                            ForEach(viewModel.leadTimeOptions, id: \.self) { minutes in
                                Text(viewModel.leadTimeDisplayText(minutes)).tag(minutes)
                            }
                        }
                        .pickerStyle(.inline)
                        .onChange(of: viewModel.notificationLeadTime) { _ in
                            viewModel.saveNotificationSettings()
                        }
                    }
                }
            }
        }
            .hideFormBackground()
            .navigationTitle("通知設定")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
