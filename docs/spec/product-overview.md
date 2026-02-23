# Serendipity Planner - プロダクト概要

## アプリ概要

Serendipity Planner は、カレンダーの隙間時間を自動検出し、天気・位置情報・ユーザーの好みに基づいて「今の自分にぴったりの体験」を提案する iOS アプリです。

日々のスケジュールに偶然の発見（セレンディピティ）を取り入れることで、忙しい毎日に小さな楽しみを見つけるお手伝いをします。

### 主な特徴

- カレンダー連携による隙間時間の自動検出
- 天気・気温に応じた屋内/屋外アクティビティの提案
- 近隣スポットの検索と地図表示
- ユーザーの選択履歴に基づく学習・パーソナライズ
- 通知による隙間時間のリマインド

## 技術スタック

| カテゴリ | 技術 |
|---------|------|
| UI フレームワーク | SwiftUI |
| アーキテクチャ | MVVM (Model-View-ViewModel) |
| カレンダー連携 | EventKit |
| 天気情報 | OpenWeatherMap API |
| 地図・スポット検索 | MapKit (MKLocalSearch) |
| 位置情報 | CoreLocation |
| 通知 | UserNotifications |
| データ永続化 | UserDefaults + JSONEncoder/JSONDecoder |
| 最小対応 OS | iOS 17+ |
| 言語 | Japanese (ja) |
| Bundle ID | com.serendipity.planner |

## プロジェクト構成

```
SerendipityPlanner/
├── App/
│   ├── SerendipityPlannerApp.swift      # アプリエントリポイント
│   └── AppDelegate.swift                # 通知デリゲート
├── Models/
│   ├── Suggestion.swift                 # 提案・カテゴリ・WeightProfile・NearbyPlace
│   ├── FreeTimeSlot.swift               # 隙間時間スロット
│   ├── WeatherData.swift                # 天気データ・天気条件・API レスポンス
│   ├── UserPreference.swift             # ユーザー設定・学習重み計算
│   ├── UserSettings.swift               # アプリ設定（通知・オンボーディング）
│   └── SuggestionHistory.swift          # 提案履歴データ
├── Services/
│   ├── CalendarService.swift            # EventKit 連携・隙間時間検出
│   ├── WeatherService.swift             # OpenWeatherMap API 通信
│   ├── SuggestionEngine.swift           # 提案生成アルゴリズム
│   ├── PlaceSearchService.swift         # MapKit スポット検索
│   ├── LocationService.swift            # CoreLocation 位置情報管理
│   ├── NotificationService.swift        # 通知スケジューリング
│   ├── PreferenceService.swift          # 設定永続化・状態管理
│   └── HistoryService.swift             # 履歴管理（永続化・集計）
├── ViewModels/
│   ├── HomeViewModel.swift              # ホーム画面のデータフロー統括
│   ├── SuggestionDetailViewModel.swift  # 提案詳細の操作ロジック
│   ├── SettingsViewModel.swift          # 設定画面の状態管理
│   ├── OnboardingViewModel.swift        # オンボーディングフロー管理
│   └── HistoryViewModel.swift           # 履歴画面の状態管理
├── Views/
│   ├── ContentView.swift                # ルートビュー・依存注入起点
│   ├── Home/
│   │   ├── HomeView.swift               # ホーム画面
│   │   ├── SkyGradientView.swift        # 空のグラデーション背景
│   │   ├── FreeTimeCardView.swift       # 隙間時間カード
│   │   ├── AcceptedCardView.swift       # 受け入れ済みカード
│   │   └── WeatherBadgeView.swift       # 天気バッジ
│   ├── Suggestion/
│   │   ├── SuggestionDetailView.swift   # 提案詳細（地図・代替案）
│   │   └── SuggestionAcceptedView.swift # 受け入れアニメーション
│   ├── History/
│   │   ├── HistoryView.swift            # 履歴一覧（月ナビゲーション付き）
│   │   ├── HistorySummaryView.swift     # 月別カテゴリサマリー
│   │   └── HistoryRowView.swift         # 履歴行（カード形式）
│   ├── Settings/
│   │   ├── SettingsView.swift           # 設定画面
│   │   └── NotificationSettingsView.swift # 通知設定
│   ├── Onboarding/
│   │   ├── OnboardingContainerView.swift  # オンボーディングコンテナ
│   │   ├── WelcomePageView.swift          # ウェルカム画面
│   │   ├── InterestSelectionView.swift    # 興味選択画面
│   │   ├── CalendarPermissionView.swift   # カレンダー権限画面
│   │   ├── NotificationPermissionView.swift # 通知権限画面
│   │   └── LocationInputView.swift        # 位置情報権限画面
│   └── Common/
│       └── ErrorStateView.swift           # エラー表示
└── Utilities/
    ├── Constants.swift                    # 定数定義
    ├── SuggestionTemplates.swift          # 提案テンプレート
    └── Extensions/
        ├── Date+Extensions.swift          # Date 拡張
        └── Color+Theme.swift              # カラーテーマ拡張
```

## テスト構成

```
SerendipityPlannerTests/
├── CalendarServiceTests.swift       # 9 テスト（隙間時間検出・曜日別設定）
├── SuggestionEngineTests.swift      # 20 テスト（重み計算・学習システム・提案生成）
├── HistoryServiceTests.swift        # 9 テスト（履歴CRUD・月別フィルタ・集計）
└── HistoryViewModelTests.swift      # 12 テスト（月ナビゲーション・グルーピング・集計表示）
```

| テストスイート | テスト数 | カバー範囲 |
|--------------|---------|-----------|
| CalendarServiceTests | 9 | 隙間時間検出アルゴリズム、最小時間フィルタ、平日/休日の時間帯設定 |
| SuggestionEngineTests | 20 | 天気補正、時間帯補正、時間長補正、重み付き選択、学習重み計算 |
| HistoryServiceTests | 9 | 履歴保存・取得・削除・月別フィルタ・カテゴリ別集計 |
| HistoryViewModelTests | 12 | 月ナビゲーション・日付グルーピング・サマリー表示・空状態判定 |
