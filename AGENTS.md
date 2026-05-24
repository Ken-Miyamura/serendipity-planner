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

## Project Structure

- iOS app (SwiftUI)
- Bundle ID: com.serendipity.planner
- Persistence: UserDefaults + JSONEncoder/JSONDecoder
- Language: Japanese (ja)
