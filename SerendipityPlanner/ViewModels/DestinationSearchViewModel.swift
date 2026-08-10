import CoreLocation
import Foundation
import MapKit

/// 目的地検索シートの検索ロジック。
/// - 入力に応じて `MKLocalSearchCompleter` で候補を列挙する（候補は座標を持たない）
/// - 候補が選ばれたら `MKLocalSearch` で座標を解決して `TodayDestination` にする
/// - 現在地周辺の「おすすめエリア」を MapKit から動的に取得する
@MainActor
final class DestinationSearchViewModel: ObservableObject {
    @Published var query = ""
    @Published private(set) var candidates: [DestinationCandidate] = []
    @Published private(set) var isSearching = false
    /// IME 変換中（未確定）かどうか。確定待ちの間に「見つかりません」を出さないために使う。
    @Published private(set) var isComposing = false
    @Published private(set) var isResolving = false
    @Published var resolveErrorMessage: String?
    @Published private(set) var recommendedAreas: [TodayDestination] = []
    @Published private(set) var isLoadingRecommendations = false

    /// 現在地が取れないときのフォールバック検索リージョン。
    /// 端末の地域設定から代表点を引く（未知の地域では世界全体）。
    /// 日本固定にすると、位置情報を許可していない海外ユーザーの検索基点が日本になってしまう。
    private let fallbackRegion = MKCoordinateRegion.forCurrentLocaleRegion()

    /// おすすめエリアの最大表示件数
    private let maxRecommendations = 6

    /// 検索バイアスの基点となる現在地（シート表示時に取得）
    private var userLocation: CLLocation?

    private let completer = MKLocalSearchCompleter()
    private var completerDelegate: SearchCompleterDelegate?

    init() {
        let delegate = SearchCompleterDelegate(
            onUpdate: { [weak self] results in self?.handleCompleterResults(results) },
            onFailure: { [weak self] in self?.handleCompleterFailure() }
        )
        self.completerDelegate = delegate
        completer.delegate = delegate
        // 行き先として選べるもののみ。`.query` はカテゴリ検索の提案が混ざるため含めない
        completer.resultTypes = [.pointOfInterest, .address]
        completer.region = fallbackRegion
    }

    // MARK: - 検索

    /// 入力変更時に呼ぶ。
    /// - Parameter isComposing: IME 変換中（未確定）なら true。確定前の部分文字列で
    ///   誤った候補を出さないよう、変換中は候補取得をスキップする。
    func updateQuery(_ text: String, isComposing: Bool = false) {
        query = text
        self.isComposing = isComposing

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            completer.cancel()
            candidates = []
            isSearching = false
            return
        }

        // 変換中は表示だけ更新し、確定してから候補を取りに行く。
        // このとき直前の確定入力の候補を残すと、「渋谷」で検索したあとに
        // 「出雲大社」を打ち始めた場合など、別のクエリの候補が新しい入力の下に
        // 見えたまま選択できてしまう。進行中の取得ごと破棄する。
        guard !isComposing else {
            completer.cancel()
            candidates = []
            isSearching = false
            return
        }

        isSearching = true
        // MKLocalSearchCompleter は逐次入力向けに設計されており、内部で更新を間引く。
        // そのため呼び出し側でデバウンスは行わない。
        completer.queryFragment = trimmed
    }

    private func handleCompleterResults(_ results: [MKLocalSearchCompletion]) {
        // 結果が届くまでに入力がクリアされていたら捨てる
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        // 直前のフラグメントに対する結果が変換開始後に届くことがある。
        // そのまま反映すると変換中に古い候補が復活するため捨てる。
        guard !isComposing else { return }
        isSearching = false
        candidates = results.map(DestinationCandidate.init(completion:))
    }

    private func handleCompleterFailure() {
        isSearching = false
        candidates = []
    }

    // MARK: - 座標の解決

    /// 選ばれた候補の座標を解決して目的地にする。失敗時は nil を返しエラーを表示する。
    func resolve(_ candidate: DestinationCandidate) async -> TodayDestination? {
        isResolving = true
        defer { isResolving = false }

        let request = MKLocalSearch.Request(completion: candidate.completion)
        guard let response = try? await MKLocalSearch(request: request).start(),
              let item = response.mapItems.first
        else {
            resolveErrorMessage = String(localized: "場所の情報を取得できませんでした。通信状況を確認してもう一度お試しください。")
            return nil
        }

        let placemark = item.placemark
        // 候補一覧で見えていた表記をそのまま引き継ぐ（選んだものと表示がズレないようにする）
        let subtitle = candidate.subtitle.isEmpty
            ? [placemark.administrativeArea, placemark.locality].compactMap(\.self).joined(separator: " ")
            : candidate.subtitle

        return TodayDestination(
            name: item.name ?? candidate.title,
            subtitle: subtitle.isEmpty ? String(localized: "周辺のスポットを提案") : subtitle,
            latitude: placemark.coordinate.latitude,
            longitude: placemark.coordinate.longitude
        )
    }

    // MARK: - おすすめエリア（現在地ベース）

    /// 現在地周辺の行き先候補を取得する。位置が無ければ空にする（固定データは持たない）。
    func loadRecommendedAreas(near location: CLLocation?) async {
        // 検索バイアスにも使うため現在地を保持する
        userLocation = location
        completer.region = searchRegion()

        guard let location else {
            recommendedAreas = []
            return
        }

        isLoadingRecommendations = true
        defer { isLoadingRecommendations = false }

        // 近隣の街・エリアに届くよう、提案検索より広いリージョンを使う
        let region = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.45, longitudeDelta: 0.45)
        )

        var collected: [TodayDestination] = []
        var seenNames = Set<String>()

        for query in RecommendationQueries.current {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query
            request.region = region
            guard let response = try? await MKLocalSearch(request: request).start() else { continue }

            for item in response.mapItems {
                guard let destination = Self.recommendedDestination(from: item, userLocation: location),
                      seenNames.insert(destination.name).inserted else { continue }
                collected.append(destination)
            }
        }

        // 現在地から近い順に並べ、上限件数で打ち切る
        recommendedAreas = Array(
            collected
                .sorted { location.distance(from: $0.location) < location.distance(from: $1.location) }
                .prefix(maxRecommendations)
        )
    }

    /// 候補列挙のバイアス基点。現在地があれば現在地を中心に広めにバイアスし、
    /// 近場を優先しつつ広域の地名検索も可能にする。取れなければ端末の地域設定にフォールバックする。
    ///
    /// span を狭めると遠方の固有名詞が近場の同名スポットに化けるため（例: 厳島神社が新宿区の
    /// 厳嶋神社になる）、この幅は狭めないこと。
    private func searchRegion() -> MKCoordinateRegion {
        guard let userLocation else { return fallbackRegion }
        return MKCoordinateRegion(
            center: userLocation.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 16, longitudeDelta: 16)
        )
    }

    // MARK: - 変換

    /// おすすめエリアの MKMapItem を今日の目的地へ変換する（現在地からの距離を補足に含める）
    private static func recommendedDestination(
        from item: MKMapItem,
        userLocation: CLLocation
    ) -> TodayDestination? {
        guard let name = item.name else { return nil }
        let placemark = item.placemark
        let coordinate = placemark.coordinate
        let distance = userLocation.distance(
            from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        )
        // Apple のジオデータには言語ごとの欠損があり、日本語端末でも一部の記録は
        // 英語のまま返る（例: 丸の内で皇居外苑だけ "Tokyo"）。一覧の中で1件だけ
        // 表記が変わると異物として目立つため、端末の言語と合わないものは落とす。
        // 距離は必ず出るので、落としても情報がゼロにはならない。
        let region = PlacemarkTextFilter.displayable(placemark.administrativeArea)
            ?? PlacemarkTextFilter.displayable(placemark.locality)
        let distanceText = Self.distanceText(meters: distance)
        let subtitle = region.map { String(localized: "\($0)・\(distanceText)") } ?? distanceText

        return TodayDestination(
            name: name,
            subtitle: subtitle,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
    }

    /// 現在地からの距離。単位はロケールに従う（m/km または ft/mi）。
    /// 「現在地から約」の文言自体は #32 で String Catalog に移す。
    private static func distanceText(meters: Double) -> String {
        String(localized: "現在地から約\(LocalizedUnits.distance(meters: meters))")
    }
}

// MARK: - Completer デリゲート

/// `MKLocalSearchCompleterDelegate` は NSObject を要求するため、ViewModel 本体とは分けて橋渡しする。
private final class SearchCompleterDelegate: NSObject, MKLocalSearchCompleterDelegate {
    private let onUpdate: @MainActor ([MKLocalSearchCompletion]) -> Void
    private let onFailure: @MainActor () -> Void

    init(
        onUpdate: @escaping @MainActor ([MKLocalSearchCompletion]) -> Void,
        onFailure: @escaping @MainActor () -> Void
    ) {
        self.onUpdate = onUpdate
        self.onFailure = onFailure
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let results = completer.results
        Task { @MainActor in self.onUpdate(results) }
    }

    func completer(_: MKLocalSearchCompleter, didFailWithError _: Error) {
        Task { @MainActor in self.onFailure() }
    }
}
