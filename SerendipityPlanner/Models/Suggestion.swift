import Foundation

enum SuggestionCategory: String, CaseIterable, Codable {
    case cafe
    case walk
    case reading
    case music
    case art
    case fitness
    case shopping
    case gourmet
    case movie
    case meditation

    var displayName: String {
        switch self {
        case .cafe: String(localized: "カフェ")
        case .walk: String(localized: "散歩")
        case .reading: String(localized: "読書")
        case .music: String(localized: "音楽")
        case .art: String(localized: "アート")
        case .fitness: String(localized: "フィットネス")
        case .shopping: String(localized: "ショッピング")
        case .gourmet: String(localized: "グルメ")
        case .movie: String(localized: "映画")
        case .meditation: String(localized: "リラックス")
        }
    }

    var iconName: String {
        switch self {
        case .cafe: "cup.and.saucer.fill"
        case .walk: "figure.walk"
        case .reading: "book.fill"
        case .music: "music.note"
        case .art: "paintpalette.fill"
        case .fitness: "figure.run"
        case .shopping: "bag.fill"
        case .gourmet: "fork.knife"
        case .movie: "film.fill"
        case .meditation: "leaf.fill"
        }
    }

    var colorName: String {
        switch self {
        case .cafe: "cafeColor"
        case .walk: "walkColor"
        case .reading: "readingColor"
        case .music: "musicColor"
        case .art: "artColor"
        case .fitness: "fitnessColor"
        case .shopping: "shoppingColor"
        case .gourmet: "gourmetColor"
        case .movie: "movieColor"
        case .meditation: "meditationColor"
        }
    }

    var weightProfile: WeightProfile {
        switch self {
        case .cafe:
            WeightProfile(
                isOutdoor: false,
                isIndoor: true,
                outdoorFriendlyMultiplier: 1.0,
                outdoorUnfriendlyMultiplier: 1.5,
                coldOrHotMultiplier: 1.3,
                comfortableTempMultiplier: 1.0,
                preferredHourRanges: [9 ... 11, 14 ... 16],
                penaltyHourRanges: [],
                preferredHourMultiplier: 1.3,
                penaltyHourMultiplier: 1.0,
                shortSlotMultiplier: 0.7
            )
        case .walk:
            WeightProfile(
                isOutdoor: true,
                isIndoor: false,
                outdoorFriendlyMultiplier: 1.5,
                outdoorUnfriendlyMultiplier: 0.3,
                coldOrHotMultiplier: 1.0,
                comfortableTempMultiplier: 1.3,
                preferredHourRanges: [8 ... 10, 16 ... 18],
                penaltyHourRanges: [20 ... 23],
                preferredHourMultiplier: 1.3,
                penaltyHourMultiplier: 0.5,
                shortSlotMultiplier: 0.5
            )
        case .reading:
            WeightProfile(
                isOutdoor: false,
                isIndoor: true,
                outdoorFriendlyMultiplier: 1.0,
                outdoorUnfriendlyMultiplier: 1.3,
                coldOrHotMultiplier: 1.0,
                comfortableTempMultiplier: 1.0,
                preferredHourRanges: [19 ... 23],
                penaltyHourRanges: [],
                preferredHourMultiplier: 1.3,
                penaltyHourMultiplier: 1.0,
                shortSlotMultiplier: 1.2
            )
        case .music:
            WeightProfile(
                isOutdoor: false,
                isIndoor: true,
                outdoorFriendlyMultiplier: 1.0,
                outdoorUnfriendlyMultiplier: 1.3,
                coldOrHotMultiplier: 1.0,
                comfortableTempMultiplier: 1.0,
                preferredHourRanges: [14 ... 17, 19 ... 22],
                penaltyHourRanges: [],
                preferredHourMultiplier: 1.3,
                penaltyHourMultiplier: 1.0,
                shortSlotMultiplier: 0.6
            )
        case .art:
            WeightProfile(
                isOutdoor: false,
                isIndoor: true,
                outdoorFriendlyMultiplier: 1.0,
                outdoorUnfriendlyMultiplier: 1.4,
                coldOrHotMultiplier: 1.0,
                comfortableTempMultiplier: 1.0,
                preferredHourRanges: [10 ... 16],
                penaltyHourRanges: [20 ... 23],
                preferredHourMultiplier: 1.3,
                penaltyHourMultiplier: 0.6,
                shortSlotMultiplier: 0.5
            )
        case .fitness:
            WeightProfile(
                isOutdoor: true,
                isIndoor: true,
                outdoorFriendlyMultiplier: 1.3,
                outdoorUnfriendlyMultiplier: 0.8,
                coldOrHotMultiplier: 0.8,
                comfortableTempMultiplier: 1.3,
                preferredHourRanges: [7 ... 10, 16 ... 19],
                penaltyHourRanges: [22 ... 23],
                preferredHourMultiplier: 1.3,
                penaltyHourMultiplier: 0.5,
                shortSlotMultiplier: 0.7
            )
        case .shopping:
            WeightProfile(
                isOutdoor: false,
                isIndoor: true,
                outdoorFriendlyMultiplier: 1.1,
                outdoorUnfriendlyMultiplier: 1.3,
                coldOrHotMultiplier: 1.0,
                comfortableTempMultiplier: 1.0,
                preferredHourRanges: [11 ... 18],
                penaltyHourRanges: [21 ... 23],
                preferredHourMultiplier: 1.2,
                penaltyHourMultiplier: 0.5,
                shortSlotMultiplier: 0.6
            )
        case .gourmet:
            WeightProfile(
                isOutdoor: false,
                isIndoor: true,
                outdoorFriendlyMultiplier: 1.0,
                outdoorUnfriendlyMultiplier: 1.3,
                coldOrHotMultiplier: 1.0,
                comfortableTempMultiplier: 1.0,
                preferredHourRanges: [11 ... 13, 17 ... 20],
                penaltyHourRanges: [6 ... 9],
                preferredHourMultiplier: 1.4,
                penaltyHourMultiplier: 0.5,
                shortSlotMultiplier: 0.6
            )
        case .movie:
            WeightProfile(
                isOutdoor: false,
                isIndoor: true,
                outdoorFriendlyMultiplier: 1.0,
                outdoorUnfriendlyMultiplier: 1.5,
                coldOrHotMultiplier: 1.2,
                comfortableTempMultiplier: 1.0,
                preferredHourRanges: [13 ... 16, 18 ... 21],
                penaltyHourRanges: [],
                preferredHourMultiplier: 1.3,
                penaltyHourMultiplier: 1.0,
                shortSlotMultiplier: 0.3
            )
        case .meditation:
            WeightProfile(
                isOutdoor: true,
                isIndoor: true,
                outdoorFriendlyMultiplier: 1.3,
                outdoorUnfriendlyMultiplier: 1.0,
                coldOrHotMultiplier: 1.0,
                comfortableTempMultiplier: 1.2,
                preferredHourRanges: [7 ... 10, 17 ... 20],
                penaltyHourRanges: [],
                preferredHourMultiplier: 1.3,
                penaltyHourMultiplier: 1.0,
                shortSlotMultiplier: 0.8
            )
        }
    }

    // スポット検索のカテゴリ定義は `SuggestionCategory+PlaceSearch.swift` を参照。
    // 日本語キーワードでは海外で成立しないため、POI カテゴリベースに移行した。

    /// 天気の文脈を差し込む提案文。`%@` に天気語が入る。
    ///
    /// String Catalog 経由なので、ロケールごとに**語順ごと差し替えられる**。
    /// 英語なら "It's sunny — the terrace looks lovely." のように天気語を
    /// 文中や文末に置いてよい。日本語の並びに引きずられないこと。
    var weatherContextFormat: (outdoor: String, indoor: String, neutral: String) {
        switch self {
        case .cafe:
            (
                outdoor: String(localized: "%@。テラス席も気持ちよさそうです。"),
                indoor: String(localized: "%@の日は、温かいカフェでゆっくりしましょう。"),
                neutral: String(localized: "%@。カフェでほっとひと息つきましょう。")
            )
        case .walk:
            (
                outdoor: String(localized: "%@。お散歩日和です！"),
                indoor: String(localized: "%@ですが、少しの時間なら大丈夫。"),
                neutral: String(localized: "%@。気分転換に歩いてみましょう。")
            )
        case .reading:
            (
                outdoor: String(localized: "%@。読書にぴったりの天気です。"),
                indoor: String(localized: "%@。読書にぴったりの天気です。"),
                neutral: String(localized: "%@。読書にぴったりの天気です。")
            )
        case .music:
            (
                outdoor: String(localized: "%@。音楽を楽しむのにいい日ですね。"),
                indoor: String(localized: "%@の日は、音楽に浸って過ごしましょう。"),
                neutral: String(localized: "%@。音楽で気分を上げましょう。")
            )
        case .art:
            (
                outdoor: String(localized: "%@。アートに触れてインスピレーションを。"),
                indoor: String(localized: "%@の日こそ、美術館でゆっくり過ごしましょう。"),
                neutral: String(localized: "%@。アートに触れてみませんか。")
            )
        case .fitness:
            (
                outdoor: String(localized: "%@。体を動かすのに気持ちいい天気です！"),
                indoor: String(localized: "%@の日は、室内で体を動かしましょう。"),
                neutral: String(localized: "%@。運動でリフレッシュしましょう。")
            )
        case .shopping:
            (
                outdoor: String(localized: "%@。お出かけ日和、ショッピングを楽しんで。"),
                indoor: String(localized: "%@の日は、屋内でショッピングを楽しみましょう。"),
                neutral: String(localized: "%@。ショッピングで気分転換を。")
            )
        case .gourmet:
            (
                outdoor: String(localized: "%@。美味しいものを食べに出かけましょう。"),
                indoor: String(localized: "%@の日は、あったかいお店で美味しいものを。"),
                neutral: String(localized: "%@。グルメを楽しみましょう。")
            )
        case .movie:
            (
                outdoor: String(localized: "%@。映画館で素敵な作品に出会いましょう。"),
                indoor: String(localized: "%@の日こそ、映画館でゆっくり過ごしましょう。"),
                neutral: String(localized: "%@。映画を観てリフレッシュ。")
            )
        case .meditation:
            (
                outdoor: String(localized: "%@。自然の中でリラックスしましょう。"),
                indoor: String(localized: "%@の日は、静かな場所で心を落ち着けましょう。"),
                neutral: String(localized: "%@。リラックスタイムを楽しんで。")
            )
        }
    }
}

struct WeightProfile {
    let isOutdoor: Bool
    let isIndoor: Bool
    let outdoorFriendlyMultiplier: Double
    let outdoorUnfriendlyMultiplier: Double
    let coldOrHotMultiplier: Double
    let comfortableTempMultiplier: Double
    let preferredHourRanges: [ClosedRange<Int>]
    let penaltyHourRanges: [ClosedRange<Int>]
    let preferredHourMultiplier: Double
    let penaltyHourMultiplier: Double
    let shortSlotMultiplier: Double
}

struct NearbyPlace: Identifiable, Codable {
    let id: UUID
    let name: String
    let category: SuggestionCategory
    let latitude: Double
    let longitude: Double
    let distance: Int // meters

    init(id: UUID = UUID(), name: String, category: SuggestionCategory, latitude: Double, longitude: Double, distance: Int) {
        self.id = id
        self.name = name
        self.category = category
        self.latitude = latitude
        self.longitude = longitude
        self.distance = distance
    }

    var distanceText: String {
        LocalizedUnits.distance(meters: Double(distance))
    }

    var walkingTimeMinutes: Int {
        max(1, distance / 80) // ~80m/min walking speed
    }

    var walkingTimeText: String {
        String(localized: "徒歩\(walkingTimeMinutes)分")
    }
}

struct Suggestion: Identifiable, Codable {
    let id: UUID
    let category: SuggestionCategory
    let title: String
    let description: String
    let duration: Int // minutes
    let freeTimeSlot: FreeTimeSlot
    let weatherContext: String
    var isAccepted: Bool
    var nearbyPlace: NearbyPlace?

    init(
        id: UUID = UUID(),
        category: SuggestionCategory,
        title: String,
        description: String,
        duration: Int,
        freeTimeSlot: FreeTimeSlot,
        weatherContext: String,
        isAccepted: Bool = false,
        nearbyPlace: NearbyPlace? = nil
    ) {
        self.id = id
        self.category = category
        self.title = title
        self.description = description
        self.duration = duration
        self.freeTimeSlot = freeTimeSlot
        self.weatherContext = weatherContext
        self.isAccepted = isAccepted
        self.nearbyPlace = nearbyPlace
    }
}
