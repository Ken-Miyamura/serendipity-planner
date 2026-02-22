import Foundation

enum SuggestionCategory: String, CaseIterable, Codable {
    case cafe = "cafe"
    case walk = "walk"
    case reading = "reading"
    case music = "music"
    case art = "art"
    case fitness = "fitness"
    case shopping = "shopping"
    case gourmet = "gourmet"
    case movie = "movie"
    case meditation = "meditation"

    var displayName: String {
        switch self {
        case .cafe: return "カフェ"
        case .walk: return "散歩"
        case .reading: return "読書"
        case .music: return "音楽"
        case .art: return "アート"
        case .fitness: return "フィットネス"
        case .shopping: return "ショッピング"
        case .gourmet: return "グルメ"
        case .movie: return "映画"
        case .meditation: return "リラックス"
        }
    }

    var iconName: String {
        switch self {
        case .cafe: return "cup.and.saucer.fill"
        case .walk: return "figure.walk"
        case .reading: return "book.fill"
        case .music: return "music.note"
        case .art: return "paintpalette.fill"
        case .fitness: return "figure.run"
        case .shopping: return "bag.fill"
        case .gourmet: return "fork.knife"
        case .movie: return "film.fill"
        case .meditation: return "leaf.fill"
        }
    }

    var colorName: String {
        switch self {
        case .cafe: return "cafeColor"
        case .walk: return "walkColor"
        case .reading: return "readingColor"
        case .music: return "musicColor"
        case .art: return "artColor"
        case .fitness: return "fitnessColor"
        case .shopping: return "shoppingColor"
        case .gourmet: return "gourmetColor"
        case .movie: return "movieColor"
        case .meditation: return "meditationColor"
        }
    }

    var weightProfile: WeightProfile {
        switch self {
        case .cafe:
            return WeightProfile(
                isOutdoor: false,
                isIndoor: true,
                outdoorFriendlyMultiplier: 1.0,
                outdoorUnfriendlyMultiplier: 1.5,
                coldOrHotMultiplier: 1.3,
                comfortableTempMultiplier: 1.0,
                preferredHourRanges: [9...11, 14...16],
                penaltyHourRanges: [],
                preferredHourMultiplier: 1.3,
                penaltyHourMultiplier: 1.0,
                shortSlotMultiplier: 0.7
            )
        case .walk:
            return WeightProfile(
                isOutdoor: true,
                isIndoor: false,
                outdoorFriendlyMultiplier: 1.5,
                outdoorUnfriendlyMultiplier: 0.3,
                coldOrHotMultiplier: 1.0,
                comfortableTempMultiplier: 1.3,
                preferredHourRanges: [8...10, 16...18],
                penaltyHourRanges: [20...23],
                preferredHourMultiplier: 1.3,
                penaltyHourMultiplier: 0.5,
                shortSlotMultiplier: 0.5
            )
        case .reading:
            return WeightProfile(
                isOutdoor: false,
                isIndoor: true,
                outdoorFriendlyMultiplier: 1.0,
                outdoorUnfriendlyMultiplier: 1.3,
                coldOrHotMultiplier: 1.0,
                comfortableTempMultiplier: 1.0,
                preferredHourRanges: [19...23],
                penaltyHourRanges: [],
                preferredHourMultiplier: 1.3,
                penaltyHourMultiplier: 1.0,
                shortSlotMultiplier: 1.2
            )
        case .music:
            return WeightProfile(
                isOutdoor: false,
                isIndoor: true,
                outdoorFriendlyMultiplier: 1.0,
                outdoorUnfriendlyMultiplier: 1.3,
                coldOrHotMultiplier: 1.0,
                comfortableTempMultiplier: 1.0,
                preferredHourRanges: [14...17, 19...22],
                penaltyHourRanges: [],
                preferredHourMultiplier: 1.3,
                penaltyHourMultiplier: 1.0,
                shortSlotMultiplier: 0.6
            )
        case .art:
            return WeightProfile(
                isOutdoor: false,
                isIndoor: true,
                outdoorFriendlyMultiplier: 1.0,
                outdoorUnfriendlyMultiplier: 1.4,
                coldOrHotMultiplier: 1.0,
                comfortableTempMultiplier: 1.0,
                preferredHourRanges: [10...16],
                penaltyHourRanges: [20...23],
                preferredHourMultiplier: 1.3,
                penaltyHourMultiplier: 0.6,
                shortSlotMultiplier: 0.5
            )
        case .fitness:
            return WeightProfile(
                isOutdoor: true,
                isIndoor: true,
                outdoorFriendlyMultiplier: 1.3,
                outdoorUnfriendlyMultiplier: 0.8,
                coldOrHotMultiplier: 0.8,
                comfortableTempMultiplier: 1.3,
                preferredHourRanges: [7...10, 16...19],
                penaltyHourRanges: [22...23],
                preferredHourMultiplier: 1.3,
                penaltyHourMultiplier: 0.5,
                shortSlotMultiplier: 0.7
            )
        case .shopping:
            return WeightProfile(
                isOutdoor: false,
                isIndoor: true,
                outdoorFriendlyMultiplier: 1.1,
                outdoorUnfriendlyMultiplier: 1.3,
                coldOrHotMultiplier: 1.0,
                comfortableTempMultiplier: 1.0,
                preferredHourRanges: [11...18],
                penaltyHourRanges: [21...23],
                preferredHourMultiplier: 1.2,
                penaltyHourMultiplier: 0.5,
                shortSlotMultiplier: 0.6
            )
        case .gourmet:
            return WeightProfile(
                isOutdoor: false,
                isIndoor: true,
                outdoorFriendlyMultiplier: 1.0,
                outdoorUnfriendlyMultiplier: 1.3,
                coldOrHotMultiplier: 1.0,
                comfortableTempMultiplier: 1.0,
                preferredHourRanges: [11...13, 17...20],
                penaltyHourRanges: [6...9],
                preferredHourMultiplier: 1.4,
                penaltyHourMultiplier: 0.5,
                shortSlotMultiplier: 0.6
            )
        case .movie:
            return WeightProfile(
                isOutdoor: false,
                isIndoor: true,
                outdoorFriendlyMultiplier: 1.0,
                outdoorUnfriendlyMultiplier: 1.5,
                coldOrHotMultiplier: 1.2,
                comfortableTempMultiplier: 1.0,
                preferredHourRanges: [13...16, 18...21],
                penaltyHourRanges: [],
                preferredHourMultiplier: 1.3,
                penaltyHourMultiplier: 1.0,
                shortSlotMultiplier: 0.3
            )
        case .meditation:
            return WeightProfile(
                isOutdoor: true,
                isIndoor: true,
                outdoorFriendlyMultiplier: 1.3,
                outdoorUnfriendlyMultiplier: 1.0,
                coldOrHotMultiplier: 1.0,
                comfortableTempMultiplier: 1.2,
                preferredHourRanges: [7...10, 17...20],
                penaltyHourRanges: [],
                preferredHourMultiplier: 1.3,
                penaltyHourMultiplier: 1.0,
                shortSlotMultiplier: 0.8
            )
        }
    }

    var searchQueries: [String] {
        switch self {
        case .cafe: return ["カフェ", "コーヒー"]
        case .walk: return ["公園", "散歩"]
        case .reading: return ["図書館", "書店", "ブックカフェ"]
        case .music: return ["音楽カフェ", "レコードショップ", "ライブハウス"]
        case .art: return ["ギャラリー", "美術館"]
        case .fitness: return ["ジム", "フィットネス", "ヨガ"]
        case .shopping: return ["雑貨", "ブティック", "ショッピング"]
        case .gourmet: return ["レストラン", "グルメ"]
        case .movie: return ["映画館", "シネマ"]
        case .meditation: return ["お寺", "スパ", "瞑想"]
        }
    }

    var weatherContextFormat: (outdoor: String, indoor: String, neutral: String) {
        switch self {
        case .cafe:
            return (
                outdoor: "%@。テラス席も気持ちよさそうです。",
                indoor: "%@の日は、温かいカフェでゆっくりしましょう。",
                neutral: "%@。カフェでほっとひと息つきましょう。"
            )
        case .walk:
            return (
                outdoor: "%@。お散歩日和です！",
                indoor: "%@ですが、少しの時間なら大丈夫。",
                neutral: "%@。気分転換に歩いてみましょう。"
            )
        case .reading:
            return (
                outdoor: "%@。読書にぴったりの天気です。",
                indoor: "%@。読書にぴったりの天気です。",
                neutral: "%@。読書にぴったりの天気です。"
            )
        case .music:
            return (
                outdoor: "%@。音楽を楽しむのにいい日ですね。",
                indoor: "%@の日は、音楽に浸って過ごしましょう。",
                neutral: "%@。音楽で気分を上げましょう。"
            )
        case .art:
            return (
                outdoor: "%@。アートに触れてインスピレーションを。",
                indoor: "%@の日こそ、美術館でゆっくり過ごしましょう。",
                neutral: "%@。アートに触れてみませんか。"
            )
        case .fitness:
            return (
                outdoor: "%@。体を動かすのに気持ちいい天気です！",
                indoor: "%@の日は、室内で体を動かしましょう。",
                neutral: "%@。運動でリフレッシュしましょう。"
            )
        case .shopping:
            return (
                outdoor: "%@。お出かけ日和、ショッピングを楽しんで。",
                indoor: "%@の日は、屋内でショッピングを楽しみましょう。",
                neutral: "%@。ショッピングで気分転換を。"
            )
        case .gourmet:
            return (
                outdoor: "%@。美味しいものを食べに出かけましょう。",
                indoor: "%@の日は、あったかいお店で美味しいものを。",
                neutral: "%@。グルメを楽しみましょう。"
            )
        case .movie:
            return (
                outdoor: "%@。映画館で素敵な作品に出会いましょう。",
                indoor: "%@の日こそ、映画館でゆっくり過ごしましょう。",
                neutral: "%@。映画を観てリフレッシュ。"
            )
        case .meditation:
            return (
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
