import Foundation

/// 距離・気温の表示をロケールに合わせる。
///
/// 以前は `"%.0f°C"` / `"%.1fkm"` のように単位を文字列に直書きしていたため、
/// 華氏・マイル圏（米国・英国など）で誤った単位が表示される状態だった。
/// `MeasurementFormatter` はロケールの単位系に応じて自動で換算・表記する。
enum LocalizedUnits {
    /// 気温。API からは常に摂氏で受け取り、表示時にロケールへ換算する。
    ///
    /// API のリクエスト単位まで切り替えると、保存済みの値がどちらの単位なのか
    /// 判別できなくなる（キャッシュをまたぐと壊れる）。データは摂氏で統一し、
    /// 変換は表示の直前に一度だけ行う。
    static func temperature(celsius: Double, locale: Locale = .current) -> String {
        let measurement = Measurement(value: celsius, unit: UnitTemperature.celsius)
        let formatter = MeasurementFormatter()
        formatter.locale = locale
        formatter.unitOptions = .naturalScale
        formatter.numberFormatter.maximumFractionDigits = 0
        return formatter.string(from: measurement)
    }

    /// 距離。メートル単位で受け取り、ロケールに応じて m/km あるいは ft/mi で表示する。
    static func distance(meters: Double, locale: Locale = .current) -> String {
        let measurement = Measurement(value: meters, unit: UnitLength.meters)
        let formatter = MeasurementFormatter()
        formatter.locale = locale
        formatter.unitOptions = .naturalScale
        // 近距離は端数を出さず、1km/1mile を超えたら小数第1位まで出す
        formatter.numberFormatter.maximumFractionDigits = meters >= 1000 ? 1 : 0
        return formatter.string(from: measurement)
    }
}
