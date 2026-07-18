import SwiftUI

/// SkyGradientView を背景に用いる画面向けの共通スタイル。
/// 夜間（evening/night）は背景が暗くなるため、テキストを明色へ切り替える判定を提供する。
///
/// conform するだけで `useLightText` が使えるようになる。
/// 天気条件など独自の判定が必要な画面（例: HomeView）は、自前の `useLightText` を
/// 定義してこの既定実装を隠すこと。
protocol SkyTextStyling {}

extension SkyTextStyling {
    /// 現在時刻の空グラデ背景で明色テキストを使うべきか
    var useLightText: Bool {
        TimePeriod.current().prefersLightText
    }
}
