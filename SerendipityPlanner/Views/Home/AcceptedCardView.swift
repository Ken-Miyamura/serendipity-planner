import SwiftUI

struct AcceptedCardView: View {
    let suggestion: Suggestion

    private var categoryColor: Color {
        Color.theme.color(for: suggestion.category)
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: suggestion.category.iconName)
                .font(.body)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(categoryColor)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(suggestion.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Label(
                        suggestion.freeTimeSlot.timeRangeText,
                        systemImage: "clock"
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)

                    if let place = suggestion.nearbyPlace {
                        Label(
                            "\(place.name)(\(place.walkingTimeText))",
                            systemImage: "mappin"
                        )
                        .font(.caption)
                        .foregroundColor(categoryColor)
                        .lineLimit(1)
                    }
                }
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.body)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.theme.cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.theme.walk.opacity(0.06), radius: 4, x: 0, y: 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        var label = "受け入れ済み、\(suggestion.title)、\(suggestion.freeTimeSlot.timeRangeText)"
        if let place = suggestion.nearbyPlace {
            label += "、\(place.name)"
        }
        return label
    }
}
