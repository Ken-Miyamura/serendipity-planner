import SwiftUI

struct LocationInputView: View {
    @EnvironmentObject private var locationService: LocationService
    @ObservedObject var viewModel: OnboardingViewModel

    private let cardBackground = Color.theme.cardBackground
    private let iconColor = Color(red: 0.275, green: 0.608, blue: 0.459)

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon with circle background
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 88, height: 88)
                Image(systemName: "location.fill")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(iconColor)
            }

            Text("位置情報の許可")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            // Description card
            VStack(spacing: 16) {
                Text("現在地に基づいて天気情報や\n近くのおすすめスポットを提案します")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                if locationService.locationAuthorized {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(iconColor)
                            .font(.title3)
                        Text("位置情報が許可されました")
                            .font(.headline)
                            .foregroundColor(iconColor)
                    }
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(iconColor.opacity(0.1))
                    )

                    if locationService.currentLocationName != "取得中..." {
                        HStack(spacing: 8) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(iconColor)
                            Text(locationService.currentLocationName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 4)
                    }
                } else {
                    Button {
                        locationService.requestPermission()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "location")
                            Text("位置情報を許可する")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(iconColor)
                        )
                        .shadow(color: iconColor.opacity(0.3), radius: 8, x: 0, y: 4)
                    }

                    Text("位置情報はスポット提案と天気取得にのみ使用されます")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(cardBackground)
            )
            .shadow(color: Color.gray.opacity(0.08), radius: 8, x: 0, y: 2)
            .padding(.horizontal, 8)

            Spacer()
        }
        .padding()
    }
}
