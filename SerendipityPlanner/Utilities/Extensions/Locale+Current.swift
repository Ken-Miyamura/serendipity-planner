import Foundation

/// 端末のロケール設定を取り出す。
///
/// iOS 16 で `Locale.languageCode` / `Locale.regionCode` が非推奨になり
/// `language.languageCode` / `region` に変わったため、deploymentTarget が iOS 15 の間は
/// 呼び出し側に分岐が漏れないようここへ集約する。
extension Locale {
    /// 端末の言語コード（"ja" / "en" など）。地域やスクリプトは含まない。
    static var currentLanguageCode: String {
        if #available(iOS 16.0, *) {
            return Locale.current.language.languageCode?.identifier ?? "en"
        }
        return Locale.current.languageCode ?? "en"
    }

    /// 端末の地域コード（"JP" / "US" など）
    static var currentRegionCode: String? {
        if #available(iOS 16.0, *) {
            return Locale.current.region?.identifier
        }
        return Locale.current.regionCode
    }
}
