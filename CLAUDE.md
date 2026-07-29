# Serendipity Planner - Development Rules

## Build & Run

- 開発タスクが完了したら、必ずシミュレーターで再ビルド＆起動して確認する
- ビルド＆起動コマンド:
  ```
  xcodebuild -scheme SerendipityPlanner -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build && \
  xcrun simctl terminate "iPhone 17 Pro" com.serendipity.planner; \
  xcrun simctl install "iPhone 17 Pro" $(xcodebuild -scheme SerendipityPlanner -showBuildSettings 2>/dev/null | grep -m1 'BUILT_PRODUCTS_DIR' | awk '{print $3}')/SerendipityPlanner.app && \
  xcrun simctl launch "iPhone 17 Pro" com.serendipity.planner
  ```

## 動作確認（必須）

**起動確認で終わらせない。変更した画面まで実際に遷移し、変更した操作をタップして確かめる。**

- シート・ダイアログ・ピッカーを変更したら、**開いた中身が表示されていること**をスクリーンショットで確認する。
  「提示された」だけでは不十分 — 中身が空の白紙シートが出るバグを v2.0.0 でリリースした実績がある。
- 画面遷移を変更したら、遷移先が描画されていることまで確認する。
- 外部アプリ連携（マップ等）を変更したら、連携先が起動するところまで確認する。
- **確認できていない項目は「未確認」と正直に報告する。** 推測で「動くはず」と書かない。

### シミュレーターの操作方法

タップは Simulator のアクセシビリティ経由で自動化できる（論理座標 402x874 pt で指定）:

```sh
PX=200; PY=417   # タップしたい論理座標
POS=$(osascript -e 'tell application "System Events" to tell process "Simulator" to get position of window 1')
SIZ=$(osascript -e 'tell application "System Events" to tell process "Simulator" to get size of window 1')
WX=${POS%%,*}; WY=${POS##*, }; WW=${SIZ%%,*}; WH=${SIZ##*, }
SX=$(echo "$WX + $PX * $WW / 402" | bc -l); SY=$(echo "$WY + $PY * $WH / 874" | bc -l)
osascript -e 'tell application "Simulator" to activate' -e "tell application \"System Events\" to click at {${SX%.*}, ${SY%.*}}"
```

スクリーンショット: `xcrun simctl io "iPhone 17 Pro" screenshot out.png`
（スクショの表示座標 → 論理座標は `論理 = 表示 * 402 / 表示画像の幅`）

## Project Structure

- iOS app (SwiftUI)
- Bundle ID: com.serendipity.planner
- Persistence: UserDefaults + JSONEncoder/JSONDecoder
- Language: Japanese (ja)
