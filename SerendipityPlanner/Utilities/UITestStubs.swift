#if DEBUG
    import CoreLocation
    import Foundation

    /// UI テスト時に本物のサービスの代わりに使うスタブ。
    ///
    /// ## なぜ必要か
    ///
    /// UI テストが実機の状態に依存すると、次の2つの問題が出る。
    ///
    /// 1. **CI で落ちる。** CI のシミュレーターは毎回まっさらで、カレンダーも位置情報も
    ///    未許可。許可されていないと提案が0件になり、画面の要素が存在しなくなる。
    ///    実際に新規シミュレーター（iPhone 16e）で目的地カードを掴めず落ちた。
    /// 2. **5言語のレイアウト比較にならない。** 言語ごとに違う提案・違うスポット名が
    ///    出ると、崩れているのか内容が違うだけなのか判別できない。
    ///
    /// 決まった内容を流し込むことで、どの言語・どの端末でも同じ画面が出る。
    ///
    /// `#if DEBUG` で囲っているのでリリースビルドには含まれない。
    enum UITestStubs {
        /// 起動引数にこれがあればスタブを使う
        static let launchArgument = "-uiTestStubData"

        static var isEnabled: Bool {
            ProcessInfo.processInfo.arguments.contains(launchArgument)
        }

        /// どの状態で立ち上げるか。定義は `UITestScenario`（テストターゲットと共有）。
        static var scenario: UITestScenario {
            .current
        }

        /// 東京駅。スポット検索が確実に結果を返す場所を選ぶ。
        static let location = CLLocation(latitude: 35.6812, longitude: 139.7671)
        /// 現在地の表示名。言語で変わらない固定値にしておくことで、
        /// 5言語のスクリーンショットを同じ条件で比べられる。
        static let locationName = "Marunouchi"

        /// 提案に紐づく周辺スポット。
        ///
        /// これが nil だと詳細画面のマップボタンごと消え、マップアプリ選択シートの
        /// レイアウト検証が**黙って素通りする**。`PlaceSearchService` は検索失敗を
        /// 空配列に変換するため、通信が無い CI では実際にそうなる。
        ///
        /// 距離は固定値にするが、表示の整形（m / ft）は本物の `LocalizedUnits` を
        /// 通るので、単位のロケール差はこのスタブでも検証できる。
        static func place(for category: SuggestionCategory) -> NearbyPlace {
            NearbyPlace(
                name: "Marunouchi Park",
                category: category,
                latitude: 35.6840,
                longitude: 139.7640,
                distance: 320
            )
        }

        // MARK: - 保存データの投入

        /// 履歴・お気に入りが**空でない状態**を作る。
        ///
        /// 空状態は別シナリオで撮る。行が並んだときの折り返しや、お気に入り詳細への
        /// 遷移はデータが無いと一切検証できない。
        ///
        /// 保存先は本物と同じ `UserDefaults`。サービスは init で読むため、
        /// ContentView がサービスを作る前（`AppDelegate`）に呼ぶ必要がある。
        static func seedStorageIfNeeded() {
            guard isEnabled, scenario == .seeded else { return }

            let encoder = JSONEncoder()
            let defaults = UserDefaults.standard

            if let data = try? encoder.encode(favorites) {
                defaults.set(data, forKey: Constants.Storage.favoriteSuggestionsKey)
            }
            if let data = try? encoder.encode(histories) {
                defaults.set(data, forKey: Constants.Storage.suggestionHistoryKey)
            }
        }

        /// 投入するお気に入り。カテゴリを散らして色とアイコンの違いも見えるようにする。
        private static var favorites: [FavoriteSuggestion] {
            zip(StubCalendarService.fixedSlots(), spreadTemplates).map { slot, template in
                FavoriteSuggestion(
                    category: template.category,
                    title: template.title,
                    description: template.description,
                    placeName: place(for: template.category).name,
                    placeAddress: locationName,
                    latitude: place(for: template.category).latitude,
                    longitude: place(for: template.category).longitude,
                    addedDate: slot.startDate
                )
            }
        }

        /// 行ごとに違うカテゴリになるテンプレートを、必要数ぶん取り出す。
        /// 同じカテゴリばかりだと、色分けとアイコンが効いているか確認できない。
        private static var spreadTemplates: [SuggestionTemplates.Template] {
            SuggestionCategory.allCases.compactMap { category in
                SuggestionTemplates.templates(for: category).first
            }
        }

        /// 投入する履歴。当月に収まる日付にして、月別集計が空にならないようにする。
        private static var histories: [SuggestionHistory] {
            zip(StubCalendarService.fixedSlots(), spreadTemplates).map { slot, template in
                let suggestion = Suggestion(
                    category: template.category,
                    title: template.title,
                    description: template.description,
                    duration: 60,
                    freeTimeSlot: slot,
                    weatherContext: "",
                    isAccepted: true,
                    nearbyPlace: place(for: template.category)
                )
                return SuggestionHistory(
                    suggestion: suggestion,
                    acceptedDate: slot.startDate,
                    placeName: place(for: template.category).name,
                    placeAddress: locationName
                )
            }
        }

        /// 起動引数に応じて本物かスタブかを返す。
        ///
        /// ViewModel の既定引数をここ経由にすることで、
        /// 呼び出し側にテスト用の分岐を散らさずに済む。
        enum Services {
            static func calendar() -> CalendarServiceProtocol {
                isEnabled ? StubCalendarService() : CalendarService()
            }

            static func weather() -> WeatherServiceProtocol {
                isEnabled ? StubWeatherService() : WeatherService()
            }

            static func placeSearch() -> PlaceSearchServiceProtocol {
                isEnabled ? StubPlaceSearchService() : PlaceSearchService()
            }

            static func notification() -> NotificationServiceProtocol {
                isEnabled ? StubNotificationService() : NotificationService()
            }
        }
    }

    /// 固定の空き時間を返すカレンダー。権限を要求しない。
    ///
    /// シナリオに応じて空・拒否・失敗・無応答を演じ分ける。
    /// これが `HomeView` の4分岐（読込中 / エラー / 空 / 一覧）の入口になる。
    final class StubCalendarService: CalendarServiceProtocol {
        private var scenario: UITestScenario {
            UITestStubs.scenario
        }

        var hasAccess: Bool {
            scenario != .denied
        }

        func requestAccess() async throws -> Bool {
            scenario != .denied
        }

        func addEvent(title _: String, startDate _: Date, endDate _: Date, notes _: String?) throws {}

        func fetchFreeTimeSlots(
            from _: Date,
            to _: Date,
            minimumMinutes _: Int,
            activeHours _: ActiveHoursPreference
        ) async throws -> [FreeTimeSlot] {
            try await slots()
        }

        func fetchUpcomingFreeSlots(
            days _: Int,
            minimumMinutes _: Int,
            activeHours _: ActiveHoursPreference
        ) async throws -> [FreeTimeSlot] {
            try await slots()
        }

        private func slots() async throws -> [FreeTimeSlot] {
            switch scenario {
            case .empty:
                return []
            case .error:
                throw CalendarService.CalendarError.fetchFailed
            case .loading:
                // 読込中の画面を撮るための足止め。
                // 長すぎると XCUITest の「アプリが idle になるまで待つ」を塞いで
                // 起動そのものが失敗するため、撮影に足りる範囲に留める。
                try? await Task.sleep(nanoseconds: 30 * 1_000_000_000)
                return []
            case .standard, .denied, .seeded, .widget:
                return Self.fixedSlots()
            }
        }

        /// 実行した時間帯で結果が変わらないよう、当日の固定時刻で作る。
        /// 保存データの投入からも使うため internal。
        static func fixedSlots() -> [FreeTimeSlot] {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            func at(_ hour: Int) -> Date {
                calendar.date(byAdding: .hour, value: hour, to: today) ?? today
            }
            return [
                FreeTimeSlot(startDate: at(10), endDate: at(12)),
                FreeTimeSlot(startDate: at(14), endDate: at(16)),
                FreeTimeSlot(startDate: at(18), endDate: at(20))
            ]
        }
    }

    /// 固定の天気を返す。API キーもネットワークも要らない。
    final class StubWeatherService: WeatherServiceProtocol {
        private var fixed: WeatherData {
            WeatherData(
                temperature: 22.0,
                condition: .clouds,
                description: "",
                humidity: 50,
                windSpeed: 2.0,
                fetchedAt: Date()
            )
        }

        func fetchWeather(for _: String) async throws -> WeatherData {
            fixed
        }

        func fetchWeather(latitude _: Double, longitude _: Double) async throws -> WeatherData {
            fixed
        }
    }

    /// 権限ダイアログを出さない通知サービス。
    ///
    /// オンボーディングのレイアウトを撮るとき、システムのダイアログが被ると
    /// 画面が見えない。ダイアログそのものは `PermissionDialogTests` で別に撮る。
    final class StubNotificationService: NotificationServiceProtocol {
        func requestPermission() async throws -> Bool {
            true
        }

        func isAuthorized() async -> Bool {
            true
        }

        func scheduleSuggestionNotification(for _: Suggestion, leadTimeMinutes _: Int) {}
        func scheduleMorningNotification(hour _: Int, freeSlotCount _: Int) {}
        func cancelMorningNotification() {}
        func cancelNotification(for _: UUID) {}
        func cancelAllNotifications() {}
    }

    /// 固定のスポットを返す。MapKit も通信も使わない。
    final class StubPlaceSearchService: PlaceSearchServiceProtocol {
        func searchNearbyPlaces(
            for category: SuggestionCategory,
            near _: CLLocation
        ) async -> [NearbyPlace] {
            [UITestStubs.place(for: category)]
        }

        func findNearbyPlace(
            for category: SuggestionCategory,
            near _: CLLocation
        ) async -> NearbyPlace? {
            UITestStubs.place(for: category)
        }
    }
#endif
