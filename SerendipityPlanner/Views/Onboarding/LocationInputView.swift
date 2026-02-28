import SwiftUI

struct LocationInputView: View {
    @EnvironmentObject private var locationService: LocationService
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Hero: Blob-masked illustration with floating location badge
            ZStack {
                // Soft blurred orange glow
                Circle()
                    .fill(OnboardingColors.orange.opacity(0.12))
                    .frame(width: 300, height: 300)
                    .blur(radius: 30)

                // Blob-masked illustration
                Image("LocationIllustration")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 250, height: 250)
                    .clipShape(LocationBlobMask())

                // Floating location pin badge
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white)
                        .frame(width: 48, height: 48)
                        .shadow(color: OnboardingColors.orange.opacity(0.2), radius: 10, x: 0, y: 5)
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 22))
                        .foregroundColor(.red)
                }
                .rotationEffect(.degrees(-12))
                .offset(x: 90, y: -80)
            }
            .frame(height: 280)

            Spacer().frame(maxHeight: 20)

            // Permission button or granted state
            if locationService.locationAuthorized {
                PermissionGrantedBadge(
                    accessibilityText: "位置情報は許可済みです"
                )

                if locationService.currentLocationName != "取得中..." {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(OnboardingColors.accentGreen)
                        Text(locationService.currentLocationName)
                            .font(.subheadline)
                            .foregroundColor(OnboardingColors.textSub)
                    }
                    .padding(.top, 6)
                }
            } else {
                PermissionActionButton(
                    icon: "location.fill",
                    label: "位置情報を許可する"
                ) {
                    locationService.requestPermission()
                }
            }

            PermissionDescription(
                text: "あなたの現在地に合わせて\n最適なプランを提案します"
            )

            Spacer()
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Blob Mask Shape (organic blob clip)

private struct LocationBlobMask: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: w * 0.72, y: h * 0.12))
        addUpperCurves(to: &path, w: w, h: h)
        addLowerCurves(to: &path, w: w, h: h)
        path.closeSubpath()
        return path
    }

    private func addUpperCurves(to path: inout Path, w: CGFloat, h: CGFloat) {
        path.addCurve(
            to: CGPoint(x: w * 0.91, y: h * 0.27),
            control1: CGPoint(x: w * 0.79, y: h * 0.15),
            control2: CGPoint(x: w * 0.87, y: h * 0.20)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.93, y: h * 0.50),
            control1: CGPoint(x: w * 0.94, y: h * 0.33),
            control2: CGPoint(x: w * 0.94, y: h * 0.42)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.83, y: h * 0.71),
            control1: CGPoint(x: w * 0.91, y: h * 0.57),
            control2: CGPoint(x: w * 0.88, y: h * 0.65)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.66, y: h * 0.85),
            control1: CGPoint(x: w * 0.79, y: h * 0.77),
            control2: CGPoint(x: w * 0.73, y: h * 0.82)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.45, y: h * 0.90),
            control1: CGPoint(x: w * 0.59, y: h * 0.88),
            control2: CGPoint(x: w * 0.52, y: h * 0.91)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.24, y: h * 0.81),
            control1: CGPoint(x: w * 0.38, y: h * 0.89),
            control2: CGPoint(x: w * 0.30, y: h * 0.85)
        )
    }

    private func addLowerCurves(to path: inout Path, w: CGFloat, h: CGFloat) {
        path.addCurve(
            to: CGPoint(x: w * 0.09, y: h * 0.65),
            control1: CGPoint(x: w * 0.18, y: h * 0.76),
            control2: CGPoint(x: w * 0.12, y: h * 0.71)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.05, y: h * 0.44),
            control1: CGPoint(x: w * 0.07, y: h * 0.59),
            control2: CGPoint(x: w * 0.05, y: h * 0.52)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.15, y: h * 0.22),
            control1: CGPoint(x: w * 0.06, y: h * 0.35),
            control2: CGPoint(x: w * 0.09, y: h * 0.28)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.38, y: h * 0.10),
            control1: CGPoint(x: w * 0.22, y: h * 0.16),
            control2: CGPoint(x: w * 0.29, y: h * 0.12)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.60, y: h * 0.08),
            control1: CGPoint(x: w * 0.47, y: h * 0.08),
            control2: CGPoint(x: w * 0.53, y: h * 0.07)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.72, y: h * 0.12),
            control1: CGPoint(x: w * 0.65, y: h * 0.09),
            control2: CGPoint(x: w * 0.69, y: h * 0.10)
        )
    }
}
