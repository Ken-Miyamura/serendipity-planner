import SwiftUI

struct WeatherBadgeView: View {
    let weather: WeatherData

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: weather.condition.iconName)
                .foregroundColor(iconColor)
            Text(weather.temperatureText)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(weather.condition.displayName)、\(weather.temperatureText)")
    }

    private var iconColor: Color {
        switch weather.condition {
        case .clear: Color(red: 0.82, green: 0.68, blue: 0.32)
        case .clouds: Color(red: 0.60, green: 0.60, blue: 0.62)
        case .rain, .drizzle: Color(red: 0.48, green: 0.58, blue: 0.78)
        case .thunderstorm: Color(red: 0.62, green: 0.48, blue: 0.76)
        case .snow: Color(red: 0.58, green: 0.72, blue: 0.82)
        case .mist: Color(red: 0.62, green: 0.62, blue: 0.64)
        case .unknown: .secondary
        }
    }
}
