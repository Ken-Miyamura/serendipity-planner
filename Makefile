SCHEME = SerendipityPlanner
DESTINATION = platform=iOS Simulator,name=iPhone 17 Pro
SIMULATOR = iPhone 17 Pro
BUNDLE_ID = com.serendipity.planner
BUILT_PRODUCTS_DIR = $(shell xcodebuild -scheme $(SCHEME) -destination '$(DESTINATION)' -showBuildSettings 2>/dev/null | grep -m1 'BUILT_PRODUCTS_DIR' | awk '{print $$3}')

.PHONY: setup format lint build run clean clean-build

# Git hooks と開発ツールをセットアップ
setup:
	git config core.hooksPath .githooks
	@echo "Git hooks を設定しました (.githooks/)"
	@command -v swiftformat > /dev/null || echo "swiftformat が未インストールです: brew install swiftformat"
	@command -v swiftlint > /dev/null || echo "swiftlint が未インストールです: brew install swiftlint"
	@echo "セットアップ完了"

# SwiftFormat で自動整形
format:
	swiftformat .

# SwiftFormat + SwiftLint チェック
lint:
	swiftformat --lint .
	swiftlint lint --strict

# ビルドのみ（シミュレーター起動なし）
build:
	xcodebuild -scheme $(SCHEME) -destination '$(DESTINATION)' build

# ビルド＆シミュレーター起動
run:
	xcodebuild -scheme $(SCHEME) -destination '$(DESTINATION)' build
	-xcrun simctl boot "$(SIMULATOR)" 2>/dev/null || true
	open -a Simulator
	-xcrun simctl terminate "$(SIMULATOR)" $(BUNDLE_ID)
	xcrun simctl install "$(SIMULATOR)" $(BUILT_PRODUCTS_DIR)/$(SCHEME).app
	xcrun simctl launch "$(SIMULATOR)" $(BUNDLE_ID)

# ビルドキャッシュを削除
clean:
	xcodebuild -scheme $(SCHEME) clean
	rm -rf ~/Library/Developer/Xcode/DerivedData/$(SCHEME)-*

# クリーンビルド＆シミュレーター起動
clean-build: clean
	xcodebuild -scheme $(SCHEME) -destination '$(DESTINATION)' build
	-xcrun simctl boot "$(SIMULATOR)" 2>/dev/null || true
	open -a Simulator
	-xcrun simctl terminate "$(SIMULATOR)" $(BUNDLE_ID)
	xcrun simctl install "$(SIMULATOR)" $(BUILT_PRODUCTS_DIR)/$(SCHEME).app
	xcrun simctl launch "$(SIMULATOR)" $(BUNDLE_ID)
