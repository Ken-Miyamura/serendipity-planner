# Serendipity Planner - データフロー

## アプリ起動時のデータフロー

```mermaid
sequenceDiagram
    participant App as SerendipityPlannerApp
    participant CV as ContentView
    participant PFS as PreferenceService
    participant HV as HomeView
    participant HVM as HomeViewModel
    participant LS as LocationService
    participant WS as WeatherService
    participant CS as CalendarService
    participant SE as SuggestionEngine
    participant PS as PlaceSearchService
    participant NS as NotificationService

    App->>CV: 起動
    CV->>PFS: @StateObject 初期化
    PFS->>PFS: UserDefaults から設定読み込み

    alt オンボーディング未完了
        CV->>CV: OnboardingContainerView 表示
    else オンボーディング完了
        CV->>HV: MainTabView → HomeView
    end

    HV->>HVM: configure(preferenceService, locationService)
    HV->>HVM: loadData()

    HVM->>HVM: loadAcceptedSuggestions()
    Note over HVM: UserDefaults から当日分を復元

    HVM->>LS: requestCurrentLocation()
    LS-->>HVM: CLLocation?

    par 並列実行
        HVM->>WS: fetchWeather(lat, lon)
        WS-->>HVM: WeatherData
    and
        HVM->>CS: fetchFreeTimeSlots(from, to, min, hours)
        CS-->>HVM: [FreeTimeSlot]
    end

    HVM->>SE: generateSuggestion(slot, weather, preference)
    SE-->>HVM: [Suggestion]

    HVM->>NS: scheduleNotifications()

    loop 各提案に対して
        HVM->>PS: findNearbyPlace(category, location)
        PS-->>HVM: NearbyPlace?
    end
```

---

## 提案受け入れフロー

```mermaid
sequenceDiagram
    participant User as ユーザー
    participant SDV as SuggestionDetailView
    participant SDVM as SuggestionDetailViewModel
    participant PFS as PreferenceService
    participant CS as CalendarService
    participant HVM as HomeViewModel

    User->>SDV: 「受け入れる」タップ
    SDV->>SDVM: accept()

    SDVM->>SDVM: isAccepted = true
    SDVM->>PFS: recordSelection(category)
    Note over PFS: selectionCounts[category] += 1
    PFS->>PFS: UserDefaults に保存

    SDVM->>CS: addEvent(title, start, end, notes)
    Note over CS: デフォルトカレンダーにイベント追加

    SDV->>SDV: SuggestionAcceptedView 表示
    Note over SDV: チェックマーク<br/>アニメーション

    SDV-->>HVM: onAccept コールバック
    HVM->>HVM: acceptSuggestion()
    Note over HVM: suggestions → acceptedSuggestions に移動
    HVM->>HVM: saveAcceptedSuggestions()
    Note over HVM: UserDefaults に永続化
```

---

## データモデル一覧

| モデル | 型 | Codable | 主要プロパティ |
|-------|---|---------|-------------|
| Suggestion | struct | Yes | id, category, title, description, duration, freeTimeSlot, weatherContext, isAccepted, nearbyPlace |
| FreeTimeSlot | struct | Yes | id, startDate, endDate |
| WeatherData | struct | Yes | temperature, condition, description, humidity, windSpeed, fetchedAt |
| UserPreference | struct | Yes | preferredCategories, minimumFreeTimeMinutes, activeHours, selectionCounts |
| UserSettings | struct | Yes | hasCompletedOnboarding, notificationsEnabled, morningNotificationEnabled/Hour, beforeFreeTimeNotificationEnabled, notificationLeadTimeMinutes |
| NearbyPlace | struct | Yes | id, name, category, latitude, longitude, distance |
| FavoriteSuggestion | struct | Yes | id, title, category, description, placeName, latitude, longitude, placeAddress, addedDate |

### 補助型

| 型 | 種類 | 説明 |
|----|------|------|
| SuggestionCategory | enum | 10カテゴリの定義（cafe, walk, reading 等） |
| WeatherCondition | enum | 8天気条件の定義（clear, clouds, rain 等） |
| WeightProfile | struct | カテゴリ別の重み補正パラメータ |
| ActiveHoursConfig | struct | 開始/終了時刻のペア |
| ActiveHoursPreference | struct | 平日/休日の ActiveHoursConfig |

---

## UserDefaults キー一覧

| キー | 定数 | 格納データ | 型 |
|------|------|---------|---|
| `userSettings` | Constants.Storage.userSettingsKey | アプリ設定 | UserSettings (JSON) |
| `userPreference` | Constants.Storage.userPreferenceKey | ユーザー好み | UserPreference (JSON) |
| `weatherCache` | Constants.Storage.weatherCacheKey | 天気キャッシュ | WeatherData (JSON) |
| `acceptedSuggestions` | Constants.Storage.acceptedSuggestionsKey | 受け入れ済み提案 | [Suggestion] (JSON) |
| `favoriteSuggestions` | Constants.Storage.favoriteSuggestionsKey | お気に入り提案 | [FavoriteSuggestion] (JSON) |

天気キャッシュは座標ごとに別キーで保存されます（例: `weather_cache_coord_35.68_139.77`）。

---

## 状態管理パターン

### @Published（ViewModel → View）

ViewModel の `@Published` プロパティが変更されると、SwiftUI が自動的にビューを再描画します。

```
HomeViewModel
├── @Published freeTimeSlots: [FreeTimeSlot]
├── @Published suggestions: [Suggestion]
├── @Published acceptedSuggestions: [Suggestion]
├── @Published weather: WeatherData?
├── @Published isLoading: Bool
└── @Published errorMessage: String?
```

### @EnvironmentObject（グローバル状態の共有）

`PreferenceService` と `LocationService` は `@EnvironmentObject` としてビュー階層全体で共有されます。

```mermaid
graph TD
    CV[ContentView] -->|environmentObject| PFS[PreferenceService]
    CV -->|environmentObject| LS[LocationService]
    CV -->|environmentObject| FS[FavoriteService]

    PFS --> HV[HomeView]
    PFS --> SV[SettingsView]
    PFS --> OV[OnboardingContainerView]
    PFS --> SDV[SuggestionDetailView]

    LS --> HV
    LS --> SV
    LS --> SDV
    LS --> LIV[LocationInputView]
```

### @StateObject と @ObservedObject

| アノテーション | 使用場面 |
|-------------|---------|
| @StateObject | ViewModel の所有者（ビューが作成するインスタンス） |
| @ObservedObject | ViewModel の参照者（親ビューから渡されるインスタンス） |

---

## データクリーンアップ

### 天気キャッシュ

- 有効期限: 1 時間（`cacheExpirationSeconds = 3600`）
- `WeatherData.isExpired` で判定
- 期限切れの場合は API を再呼び出し

### 受け入れ済み提案

- アプリ起動時に `loadAcceptedSuggestions()` で当日分のみ復元
- 昨日以前のデータは自動削除
- 全件が古い場合は UserDefaults からキーごと削除
