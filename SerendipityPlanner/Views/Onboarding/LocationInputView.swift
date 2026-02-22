import SwiftUI

struct LocationInputView: View {
    @EnvironmentObject private var locationService: LocationService
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "location.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)

            Text("位置情報の許可")
                .font(.title2)
                .fontWeight(.bold)

            Text("現在地に基づいて天気情報や\n近くのおすすめスポットを提案します")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if locationService.locationAuthorized {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("位置情報が許可されました")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
                .padding()

                if locationService.currentLocationName != "取得中..." {
                    HStack(spacing: 8) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.accentColor)
                        Text(locationService.currentLocationName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Button {
                    locationService.requestPermission()
                } label: {
                    Label("位置情報を許可する", systemImage: "location")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)

                Text("位置情報はスポット提案と天気取得にのみ使用されます")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding()
    }
}
