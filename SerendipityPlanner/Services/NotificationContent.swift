import Foundation

/// 通知に載せる文言。
///
/// `UNMutableNotificationContent` の組み立てから切り離してあるのは、
/// **実際に配信される文字列そのもの**をテストから言語別に取り出せるようにするため。
/// 通知はアプリの画面と違い、出たところをスクリーンショットで押さえるのが難しい。
///
/// bundle とロケールを引数に取ることで、端末の言語を切り替えずに5言語ぶん検証できる。
/// どの翻訳を引くかを決めるのは **bundle** で、`locale` は数値などの整形にしか効かない。
/// 言語別に見るときは `<lang>.lproj` の bundle を渡すこと。
enum NotificationContent {
    /// 空き時間の直前に出す通知
    static func suggestion(
        _ suggestion: Suggestion,
        bundle: Bundle = .main,
        locale: Locale = .current
    ) -> (title: String, body: String) {
        (
            title: String(localized: "セレンディピティ", bundle: bundle, locale: locale),
            body: String(
                localized: "\(suggestion.freeTimeSlot.timeRangeText)に空き時間があります。\(suggestion.title)はいかがですか？",
                bundle: bundle,
                locale: locale
            )
        )
    }

    /// 朝に出すその日のまとめ通知
    static func morning(
        freeSlotCount: Int,
        bundle: Bundle = .main,
        locale: Locale = .current
    ) -> (title: String, body: String) {
        (
            title: String(localized: "おはようございます ☀️", bundle: bundle, locale: locale),
            body: String(
                localized: "今日の隙間時間：\(freeSlotCount)つ見つかりました。タップして提案を確認しましょう。",
                bundle: bundle,
                locale: locale
            )
        )
    }
}
