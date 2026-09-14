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

        /// 東京駅。スポット検索が確実に結果を返す場所を選ぶ。
        static let location = CLLocation(latitude: 35.6812, longitude: 139.7671)
        static let locationName = "Marunouchi"

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
        }
    }

    /// 固定の空き時間を返すカレンダー。権限を要求しない。
    final class StubCalendarService: CalendarServiceProtocol {
        var hasAccess: Bool {
            true
        }

        func requestAccess() async throws -> Bool {
            true
        }

        func addEvent(title _: String, startDate _: Date, endDate _: Date, notes _: String?) throws {}

        func fetchFreeTimeSlots(
            from _: Date,
            to _: Date,
            minimumMinutes _: Int,
            activeHours _: ActiveHoursPreference
        ) async throws -> [FreeTimeSlot] {
            Self.fixedSlots()
        }

        func fetchUpcomingFreeSlots(
            days _: Int,
            minimumMinutes _: Int,
            activeHours _: ActiveHoursPreference
        ) async throws -> [FreeTimeSlot] {
            Self.fixedSlots()
        }

        /// 実行した時間帯で結果が変わらないよう、当日の固定時刻で作る
        private static func fixedSlots() -> [FreeTimeSlot] {
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
#endif
