import SwiftUI

struct CalendarPermissionView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Hero: Illustration with orange blob behind
            ZStack {
                CalendarBlob()
                    .fill(OnboardingColors.orange.opacity(0.35))
                    .frame(width: 280, height: 260)

                Image("CalendarIllustration")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 240, height: 240)
            }
            .frame(height: 280)

            Spacer().frame(maxHeight: 20)

            // Permission button or granted state
            if viewModel.calendarPermissionGranted {
                PermissionGrantedBadge(
                    accessibilityText: "カレンダーへのアクセスは許可済みです"
                )
            } else {
                PermissionActionButton(
                    icon: "checkmark.circle.fill",
                    label: "カレンダーを許可する"
                ) {
                    Task {
                        await viewModel.requestCalendarPermission()
                    }
                }

                if let error = viewModel.permissionError, error.contains("カレンダー") {
                    PermissionErrorView(error: error)
                }
            }

            PermissionDescription(
                text: "カレンダーの予定を確認して\n空き時間を自動で検出し、\nあなたに合った体験を提案します"
            )

            Spacer()
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Calendar Blob Shape

private struct CalendarBlob: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()

        path.move(to: CGPoint(x: w * 0.50, y: h * 0.02))
        path.addCurve(
            to: CGPoint(x: w * 0.92, y: h * 0.25),
            control1: CGPoint(x: w * 0.72, y: h * 0.0),
            control2: CGPoint(x: w * 0.88, y: h * 0.10)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.95, y: h * 0.65),
            control1: CGPoint(x: w * 0.98, y: h * 0.38),
            control2: CGPoint(x: w * 1.0, y: h * 0.55)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.55, y: h * 0.95),
            control1: CGPoint(x: w * 0.90, y: h * 0.80),
            control2: CGPoint(x: w * 0.75, y: h * 0.95)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.10, y: h * 0.70),
            control1: CGPoint(x: w * 0.35, y: h * 0.95),
            control2: CGPoint(x: w * 0.12, y: h * 0.88)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.08, y: h * 0.30),
            control1: CGPoint(x: w * 0.08, y: h * 0.55),
            control2: CGPoint(x: w * 0.02, y: h * 0.42)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.50, y: h * 0.02),
            control1: CGPoint(x: w * 0.15, y: h * 0.15),
            control2: CGPoint(x: w * 0.30, y: h * 0.04)
        )
        path.closeSubpath()
        return path
    }
}
