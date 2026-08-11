import Foundation

extension DateFormatter {
    /// ロケールに応じた並び順・区切り・記号で日付を整形するフォーマッタを作る。
    ///
    /// `dateFormat` を直接指定すると "yyyy年M月" のように**日本語の並びが固定**されてしまい、
    /// 英語ロケールでも「2026年8月」と出てしまう。`dateFormat(fromTemplate:)` にテンプレート
    /// （スケルトン）を渡すと、含める要素だけを指定して並びは各ロケールに任せられる。
    ///
    /// ```
    /// localized(template: "yMMMM") → ja: 2026年8月 / en: August 2026
    /// localized(template: "MMMdE") → ja: 8月11日(火) / en: Tue, Aug 11
    /// ```
    ///
    /// - Parameter template: 含める日付要素のテンプレート（並び順は指定しない）
    static func localized(template: String, locale: Locale = .current) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = DateFormatter.dateFormat(
            fromTemplate: template,
            options: 0,
            locale: locale
        )
        return formatter
    }

    /// 時刻のみを表示するフォーマッタ。
    ///
    /// "HH:mm" の直書きは24時間表記を強制するため、12時間表記が既定のロケール
    /// （en-US など）で不自然になる。`timeStyle` に任せると各ロケールの慣習に従う。
    static func localizedTime(locale: Locale = .current) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }
}
