import SwiftUI

// MARK: - RGBColor Helper

struct RGBColor {
    var r: Double
    var g: Double
    var b: Double

    var color: Color {
        Color(red: r, green: g, blue: b)
    }

    func blended(toward target: RGBColor, amount: Double) -> RGBColor {
        let t = min(max(amount, 0), 1)
        return RGBColor(
            r: r + (target.r - r) * t,
            g: g + (target.g - g) * t,
            b: b + (target.b - b) * t
        )
    }

    func darkened(by amount: Double) -> RGBColor {
        let factor = 1 - min(max(amount, 0), 1)
        return RGBColor(r: r * factor, g: g * factor, b: b * factor)
    }

    func lightened(by amount: Double) -> RGBColor {
        let t = min(max(amount, 0), 1)
        return RGBColor(
            r: r + (1 - r) * t,
            g: g + (1 - g) * t,
            b: b + (1 - b) * t
        )
    }
}

// MARK: - TimePeriod

enum TimePeriod {
    case dawn       // 5-7
    case morning    // 7-10
    case daytime    // 10-16
    case goldenHour // 16-18
    case evening    // 18-21
    case night      // 21-5

    static func current() -> TimePeriod {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<7: return .dawn
        case 7..<10: return .morning
        case 10..<16: return .daytime
        case 16..<18: return .goldenHour
        case 18..<21: return .evening
        default: return .night
        }
    }

    var prefersLightText: Bool {
        switch self {
        case .evening, .night: return true
        default: return false
        }
    }
}

// MARK: - SkyColorPalette

struct SkyColorPalette {
    let top: RGBColor
    let middle: RGBColor
    let bottom: RGBColor

    static let pageBackgroundRGB = RGBColor(r: 0.97, g: 0.96, b: 0.94)

    static func base(for period: TimePeriod) -> SkyColorPalette {
        switch period {
        case .dawn:
            return SkyColorPalette(
                top: RGBColor(r: 0.88, g: 0.70, b: 0.75),
                middle: RGBColor(r: 0.95, g: 0.85, b: 0.80),
                bottom: pageBackgroundRGB
            )
        case .morning:
            return SkyColorPalette(
                top: RGBColor(r: 0.68, g: 0.82, b: 0.92),
                middle: RGBColor(r: 0.92, g: 0.90, b: 0.85),
                bottom: pageBackgroundRGB
            )
        case .daytime:
            return SkyColorPalette(
                top: RGBColor(r: 0.58, g: 0.78, b: 0.94),
                middle: RGBColor(r: 0.82, g: 0.90, b: 0.96),
                bottom: pageBackgroundRGB
            )
        case .goldenHour:
            return SkyColorPalette(
                top: RGBColor(r: 0.92, g: 0.72, b: 0.52),
                middle: RGBColor(r: 0.90, g: 0.75, b: 0.68),
                bottom: pageBackgroundRGB
            )
        case .evening:
            return SkyColorPalette(
                top: RGBColor(r: 0.35, g: 0.28, b: 0.55),
                middle: RGBColor(r: 0.65, g: 0.42, b: 0.52),
                bottom: pageBackgroundRGB
            )
        case .night:
            return SkyColorPalette(
                top: RGBColor(r: 0.12, g: 0.12, b: 0.28),
                middle: RGBColor(r: 0.22, g: 0.18, b: 0.35),
                bottom: pageBackgroundRGB
            )
        }
    }

    static func adjusted(for condition: WeatherCondition?, period: TimePeriod) -> SkyColorPalette {
        let base = self.base(for: period)
        guard let condition = condition else { return base }

        switch condition {
        case .clear, .unknown:
            return base

        case .clouds:
            let gray = RGBColor(r: 0.65, g: 0.65, b: 0.67)
            return SkyColorPalette(
                top: base.top.blended(toward: gray, amount: 0.30),
                middle: base.middle.blended(toward: gray, amount: 0.30),
                bottom: base.bottom
            )

        case .rain, .drizzle:
            let blueGray = RGBColor(r: 0.50, g: 0.55, b: 0.65)
            return SkyColorPalette(
                top: base.top.blended(toward: blueGray, amount: 0.35).darkened(by: 0.15),
                middle: base.middle.blended(toward: blueGray, amount: 0.35).darkened(by: 0.15),
                bottom: base.bottom
            )

        case .thunderstorm:
            let purpleGray = RGBColor(r: 0.40, g: 0.35, b: 0.50)
            return SkyColorPalette(
                top: base.top.blended(toward: purpleGray, amount: 0.40).darkened(by: 0.30),
                middle: base.middle.blended(toward: purpleGray, amount: 0.40).darkened(by: 0.30),
                bottom: base.bottom
            )

        case .snow:
            let paleBlueWhite = RGBColor(r: 0.90, g: 0.92, b: 0.96)
            return SkyColorPalette(
                top: base.top.blended(toward: paleBlueWhite, amount: 0.40).lightened(by: 0.15),
                middle: base.middle.blended(toward: paleBlueWhite, amount: 0.40).lightened(by: 0.15),
                bottom: base.bottom
            )

        case .mist:
            let foggyWhite = RGBColor(r: 0.85, g: 0.85, b: 0.87)
            return SkyColorPalette(
                top: base.top.blended(toward: foggyWhite, amount: 0.50),
                middle: base.middle.blended(toward: foggyWhite, amount: 0.50),
                bottom: base.bottom
            )
        }
    }
}

// MARK: - SkyGradientView

struct SkyGradientView: View {
    let weatherCondition: WeatherCondition?

    @State private var appeared = false

    private var period: TimePeriod { TimePeriod.current() }

    private var palette: SkyColorPalette {
        SkyColorPalette.adjusted(for: weatherCondition, period: period)
    }

    private var showSun: Bool {
        switch period {
        case .dawn, .morning, .daytime, .goldenHour: return true
        case .evening, .night: return false
        }
    }

    private var celestialOpacity: Double {
        switch period {
        case .dawn: return 0.10
        case .morning, .daytime: return 0.12
        case .goldenHour: return 0.15
        case .evening: return 0.08
        case .night: return 0.10
        }
    }

    private var celestialColor: Color {
        if showSun {
            return Color(red: 1.0, green: 0.95, blue: 0.80)
        } else {
            return Color(red: 0.85, green: 0.88, blue: 0.95)
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: palette.top.color, location: 0.0),
                    .init(color: palette.middle.color, location: 0.4),
                    .init(color: palette.bottom.color, location: 0.85)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Celestial body decoration (sun or moon)
            GeometryReader { geo in
                RadialGradient(
                    colors: [
                        celestialColor.opacity(celestialOpacity),
                        celestialColor.opacity(0)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: geo.size.width * 0.35
                )
                .frame(width: geo.size.width * 0.7, height: geo.size.width * 0.7)
                .position(
                    x: geo.size.width * 0.8,
                    y: geo.size.height * 0.12
                )
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.easeIn(duration: 0.8)) {
                appeared = true
            }
        }
    }
}
