.PHONY: setup format lint

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
