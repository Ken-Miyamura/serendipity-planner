import SwiftUI

struct FreeTimeCardView: View {
    let suggestion: Suggestion

    private var categoryColor: Color {
        Color.theme.color(for: suggestion.category)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Time slot header (date removed — today only)
            HStack {
                Text(suggestion.freeTimeSlot.timeRangeText)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text("\(suggestion.freeTimeSlot.durationMinutes)分")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.theme.secondaryBackground)
                    .cornerRadius(8)
            }

            // Suggestion content
            HStack(spacing: 12) {
                Image(systemName: suggestion.category.iconName)
                    .font(.title2)
                    .foregroundColor(categoryColor)
                    .frame(width: 44, height: 44)
                    .background(
                        categoryColor.opacity(0.2)
                    )
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(suggestion.title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    if let place = suggestion.nearbyPlace {
                        Label(
                            "\(place.name)（\(place.walkingTimeText)）",
                            systemImage: "mappin"
                        )
                        .font(.caption)
                        .foregroundColor(categoryColor)
                        .lineLimit(1)
                    } else {
                        Text(suggestion.weatherContext)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                if suggestion.isAccepted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(categoryColor)
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.theme.cardBackground)
        .cornerRadius(20)
        .shadow(color: Color.theme.walk.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}
