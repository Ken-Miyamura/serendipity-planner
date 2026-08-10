import MapKit

extension MKCoordinateRegion {
    /// 端末の地域設定に対応するフォールバック検索リージョン。
    ///
    /// 現在地が取れないときの検索バイアスに使う。以前は日本列島を覆う固定リージョンだったが、
    /// それだと位置情報を許可していない海外ユーザーの検索基点まで日本になってしまうため、
    /// 端末の地域設定から引くようにした。対応表に無い地域では世界全体を対象にする
    /// （バイアスをかけないほうが、誤った国に寄せるより害が小さい）。
    static func forCurrentLocaleRegion() -> MKCoordinateRegion {
        region(forCountryCode: Locale.currentRegionCode)
    }

    /// 地域コードに対応するリージョン。未知・未指定なら全世界を返す。
    static func region(forCountryCode code: String?) -> MKCoordinateRegion {
        guard let code, let region = regionsByCountryCode[code] else { return world }
        return region
    }

    /// バイアスをかけない全世界リージョン
    static let world = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 180, longitudeDelta: 360)
    )

    /// 配信対象地域の代表リージョン。span はその国土がおおむね収まる幅。
    /// 対応言語（ja / en / ko / es / fr）の主な地域をカバーする。
    private static let regionsByCountryCode: [String: MKCoordinateRegion] = [
        "JP": region(36.0, 137.5, 22),
        "KR": region(36.5, 127.8, 6),
        "US": region(39.8, -98.6, 45),
        "GB": region(54.0, -2.5, 11),
        "CA": region(56.0, -96.0, 45),
        "AU": region(-25.3, 133.8, 40),
        "ES": region(40.2, -3.7, 11),
        "MX": region(23.6, -102.5, 22),
        "AR": region(-38.4, -63.6, 33),
        "FR": region(46.6, 2.5, 11)
    ]

    private static func region(
        _ latitude: CLLocationDegrees,
        _ longitude: CLLocationDegrees,
        _ span: CLLocationDegrees
    ) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span)
        )
    }
}

extension Locale {
    /// 端末の地域コード（"JP" / "US" など）
    static var currentRegionCode: String? {
        if #available(iOS 16.0, *) {
            return Locale.current.region?.identifier
        }
        return Locale.current.regionCode
    }
}
