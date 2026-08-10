import Foundation

/// Apple のジオデータに含まれる地名テキストを表示してよいか判定する。
///
/// ## 背景
///
/// MapKit は端末の言語設定に従って地名を返すが、**すべての記録に全言語のデータが
/// 揃っているわけではない**。日本語端末でも一部の記録は英語のまま返る。
///
/// ```
/// 東京タワー → 東京都 港区        ← ja データあり
/// 皇居外苑   → Tokyo Chiyoda-Ku   ← ja データが無く英語で返る
/// ```
///
/// 一覧の中で1件だけ表記体系が変わると異物として目立つため、端末の言語と表記が
/// 一致しないものは表示から落とす。距離表示は必ず出るので、落としても情報が
/// ゼロになることはない。
///
/// ## 「ASCII が含まれていたら落とす」ではない
///
/// ロケール非依存に「英字が含まれていたら落とす」ルールにすると、英語端末で
/// 正しく英語が返っているケースまで全部消えてしまう。データ欠損は**どの言語でも**
/// 起きるため、判定は必ず端末の言語を基準に行う。
enum PlacemarkTextFilter {
    /// 主にラテン文字で表記する言語。これ以外は固有の文字体系を持つ扱いにする。
    private static let latinScriptLanguages: Set<String> = [
        "en", "es", "fr", "de", "it", "pt", "nl", "sv", "da", "no", "fi",
        "pl", "cs", "tr", "id", "vi", "ms", "ro", "hu", "hr", "sk", "sl"
    ]

    /// 端末の言語と表記体系が一致しているか。
    ///
    /// - ラテン文字の言語（en / es / fr など）: 非ラテン文字が混ざっていたら不一致
    /// - 固有文字体系の言語（ja / ko など）: ラテン文字だけで構成されていたら不一致
    ///
    /// 数字・記号・空白は判定に使わない（「1丁目」「Chiyoda-Ku」のような
    /// 混在表記を誤判定しないため）。
    static func matchesDeviceLanguage(
        _ text: String,
        languageCode: String = Locale.currentLanguageCode
    ) -> Bool {
        let letters = text.unicodeScalars.filter { CharacterSet.letters.contains($0) }
        // 判定材料が無い（数字と記号だけ等）ものは落とさない
        guard !letters.isEmpty else { return true }

        let hasNonLatin = letters.contains { !isLatin($0) }

        if latinScriptLanguages.contains(languageCode) {
            return !hasNonLatin
        }
        return hasNonLatin
    }

    /// 表示してよければそのまま返し、表記が一致しなければ nil を返す
    static func displayable(
        _ text: String?,
        languageCode: String = Locale.currentLanguageCode
    ) -> String? {
        guard let text, !text.isEmpty else { return nil }
        return matchesDeviceLanguage(text, languageCode: languageCode) ? text : nil
    }

    private static func isLatin(_ scalar: Unicode.Scalar) -> Bool {
        // 基本ラテン + ラテン拡張（アクセント付き文字を含む）
        switch scalar.value {
        case 0x0041 ... 0x005A, 0x0061 ... 0x007A, 0x00C0 ... 0x024F:
            true
        default:
            false
        }
    }
}
