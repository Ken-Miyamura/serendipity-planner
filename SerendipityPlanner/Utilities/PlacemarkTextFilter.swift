import Foundation

/// Apple のジオデータに含まれる地名テキストを表示してよいか判定する。
///
/// ## 何を解こうとしているか
///
/// MapKit は端末の言語設定に従って地名を返す。これ自体は正しい挙動で、日本語設定のまま
/// パリへ行けばラテン文字の地名が返るのが期待どおり（Apple マップと同じ）。
///
/// 問題は **Apple 側のデータ欠損**のほう。日本国内では ja データが揃っているのに一部の記録
/// だけ欠けていて、同じ一覧の中で1件だけ表記が変わる。
///
/// ```
/// 和田倉噴水公園 / 東京都・現在地から約612 m
/// 将門塚        / 東京都・現在地から約783 m
/// 皇居外苑      / Tokyo・現在地から約854 m   ← ここだけ浮く
/// ```
///
/// ## 端末の言語ではなく「一覧の多数派」で判定する
///
/// 「端末の言語と表記体系が合わないものを落とす」という**絶対判定にしてはいけない**。
/// パリでは ja データがほぼ存在しないため全件がラテン文字になり、絶対判定だと地域名が
/// 全滅する（実測で6件すべてが距離のみになった）。海外でラテン文字が出るのは正常なので、
/// これは過剰な除去。
///
/// そこで**その一覧の多数派の表記体系**を基準にし、そこから外れた行だけ落とす。
///
/// - 東京: 多数派が日本語 → "Tokyo" の1件だけ落ちる
/// - パリ: 多数派がラテン文字 → 全件そのまま残る
///
/// 「英字が含まれていたら落とす」というロケール非依存のルールも同じ理由で不可。
enum PlacemarkTextFilter {
    /// 地名テキストの表記体系
    enum Script {
        /// ラテン文字（英語・スペイン語・フランス語など）
        case latin
        /// ラテン文字以外（日本語・韓国語など）
        case nonLatin
    }

    /// テキストの表記体系。判定材料（文字）が無ければ nil。
    ///
    /// 数字・記号・空白は判定に使わない。「1丁目」「Chiyoda-Ku」のような混在表記を
    /// 誤判定しないため、**文字が1つでも非ラテンなら非ラテン**として扱う。
    static func script(of text: String) -> Script? {
        let letters = text.unicodeScalars.filter { CharacterSet.letters.contains($0) }
        guard !letters.isEmpty else { return nil }
        return letters.contains { !isLatin($0) } ? .nonLatin : .latin
    }

    /// 一覧の中で多数派の表記体系。判定できない場合や同数の場合は nil を返す。
    ///
    /// nil のときは何も落とさない。基準が決まらない状態で落とすと、情報を減らすだけになるため。
    static func dominantScript(in texts: [String]) -> Script? {
        let scripts = texts.compactMap(script(of:))
        guard !scripts.isEmpty else { return nil }

        let latin = scripts.filter { $0 == .latin }.count
        let nonLatin = scripts.count - latin
        if latin == nonLatin { return nil }
        return latin > nonLatin ? .latin : .nonLatin
    }

    /// 多数派に沿っていれば表示してよい。
    /// 基準が無い（`dominant` が nil）場合や判定材料が無い場合は落とさない。
    static func isDisplayable(_ text: String, dominant: Script?) -> Bool {
        guard let dominant, let script = script(of: text) else { return true }
        return script == dominant
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
