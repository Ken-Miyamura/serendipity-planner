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
        case .cafe: "カフェ"
        case .walk: "散歩"
        case .reading: "読書"
        case .music: "音楽"
        case .art: "アート"
        case .fitness: "フィットネス"
        case .shopping: "ショッピング"
        case .gourmet: "グルメ"
        case .movie: "映画"
        case .meditation: "リラックス"
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

    var searchQueries: [String] {
        switch self {
        case .cafe: ["カフェ", "コーヒー"]
        case .walk: ["公園", "散歩"]
        case .reading: ["図書館", "書店", "ブックカフェ"]
        case .music: ["音楽カフェ", "レコードショップ", "ライブハウス"]
        case .art: ["ギャラリー", "美術館"]
        case .fitness: ["ジム", "フィットネス", "ヨガ"]
        case .shopping: ["雑貨", "ブティック", "ショッピング"]
        case .gourmet: ["レストラン", "グルメ"]
        case .movie: ["映画館", "シネマ"]
        case .meditation: ["お寺", "スパ", "瞑想"]
        }
    }

    var weatherContextFormat: (outdoor: String, indoor: String, neutral: String) {
        switch self {
        case .cafe:
            (
                outdoor: "%@。テラス席も気持ちよさそうです。",
                indoor: "%@の日は、温かいカフェでゆっくりしましょう。",
                neutral: "%@。カフェでほっとひと息つきましょう。"
            )
        case .walk:
            (
                outdoor: "%@。お散歩日和です！",
                indoor: "%@ですが、少しの時間なら大丈夫。",
                neutral: "%@。気分転換に歩いてみましょう。"
            )
        case .reading:
            (
                outdoor: "%@。読書にぴったりの天気です。",
                indoor: "%@。読書にぴったりの天気です。",
                neutral: "%@。読書にぴったりの天気です。"
            )
        case .music:
            (
                outdoor: "%@。音楽を楽しむのにいい日ですね。",
                indoor: "%@の日は、音楽に浸って過ごしましょう。",
                neutral: "%@。音楽で気分を上げましょう。"
            )
        case .art:
            (
                outdoor: "%@。アートに触れてインスピレーションを。",
                indoor: "%@の日こそ、美術館でゆっくり過ごしましょう。",
                neutral: "%@。アートに触れてみませんか。"
            )
        case .fitness:
            (
                outdoor: "%@。体を動かすのに気持ちいい天気です！",
                indoor: "%@の日は、室内で体を動かしましょう。",
                neutral: "%@。運動でリフレッシュしましょう。"
            )
        case .shopping:
            (
                outdoor: "%@。お出かけ日和、ショッピングを楽しんで。",
                indoor: "%@の日は、屋内でショッピングを楽しみましょう。",
                neutral: "%@。ショッピングで気分転換を。"
            )
        case .gourmet:
            (
                outdoor: "%@。美味しいものを食べに出かけましょう。",
                indoor: "%@の日は、あったかいお店で美味しいものを。",
                neutral: "%@。グルメを楽しみましょう。"
            )
        case .movie:
            (
                outdoor: "%@。映画館で素敵な作品に出会いましょう。",
                indoor: "%@の日こそ、映画館でゆっくり過ごしましょう。",
                neutral: "%@。映画を観てリフレッシュ。"
            )
        case .meditation:
            (
                outdoor: "%@。自然の中でリラックスしましょう。",
                indoor: "%@の日は、静かな場所で心を落ち着けましょう。",
                neutral: "%@。リラックスタイムを楽しんで。"
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
        if distance >= 1000 {
            return String(format: "%.1fkm", Double(distance) / 1000.0)
        }
        return "\(distance)m"
    }

    var walkingTimeMinutes: Int {
        max(1, distance / 80) // ~80m/min walking speed
    }

    var walkingTimeText: String {
        "徒歩\(walkingTimeMinutes)分"
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
