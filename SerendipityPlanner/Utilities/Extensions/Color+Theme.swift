import SwiftUI

extension Color {
    static let theme = ThemeColors()
}

struct ThemeColors {
    let accent = Color("AccentColor")

    // カテゴリ色 — ソフトトーン（視認性を保ちつつ柔らかい印象）
    let cafe = Color(red: 0.65, green: 0.52, blue: 0.42)
    let walk = Color(red: 0.45, green: 0.68, blue: 0.58)
    let reading = Color(red: 0.50, green: 0.56, blue: 0.75)
    let music = Color(red: 0.65, green: 0.50, blue: 0.78)
    let art = Color(red: 0.82, green: 0.62, blue: 0.40)
    let fitness = Color(red: 0.80, green: 0.48, blue: 0.48)
    let shopping = Color(red: 0.82, green: 0.52, blue: 0.62)
    let gourmet = Color(red: 0.78, green: 0.65, blue: 0.38)
    let movie = Color(red: 0.50, green: 0.50, blue: 0.72)
    let meditation = Color(red: 0.45, green: 0.68, blue: 0.68)

    // 背景色
    let pageBackground = Color(red: 0.97, green: 0.96, blue: 0.94)
    let cardBackground = Color(red: 1.0, green: 0.99, blue: 0.97)
    let secondaryBackground = Color(red: 0.96, green: 0.95, blue: 0.93)

    func color(for category: SuggestionCategory) -> Color {
        switch category {
        case .cafe: return cafe
        case .walk: return walk
        case .reading: return reading
        case .music: return music
        case .art: return art
        case .fitness: return fitness
        case .shopping: return shopping
        case .gourmet: return gourmet
        case .movie: return movie
        case .meditation: return meditation
        }
    }
}
