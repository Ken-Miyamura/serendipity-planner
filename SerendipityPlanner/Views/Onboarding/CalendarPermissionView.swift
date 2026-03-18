import SwiftUI

struct CalendarPermissionView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Hero: Illustration with orange blob behind
            ZStack {
                CalendarBlob()
                    .fill(OnboardingColors.orange.opacity(0.35))
                    .frame(width: 320, height: 300)

                Image("CalendarIllustration")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 280, height: 280)
            }
            .frame(height: 320)
            .offset(y: appeared ? 0 : -30)
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.8), value: appeared)

            Spacer().frame(maxHeight: 16)

            if let error = viewModel.permissionError, error.contains("カレンダー") {
                PermissionErrorView(error: error)
            }

            PermissionDescription(
                headline: "カレンダーと連携",
                text: "予定を確認して空き時間を自動で検出し、\nあなたに合った体験を提案します"
            )
            .offset(y: appeared ? 0 : -20)
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.8).delay(0.3), value: appeared)

            Spacer()
        }
        .padding(.horizontal, 4)
        .onChange(of: viewModel.currentPage) { page in
            if page == 2 {
                appeared = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    appeared = true
                }
                if !viewModel.calendarPermissionGranted {
                    Task {
                        try? await Task.sleep(nanoseconds: 600_000_000)
                        await viewModel.requestCalendarPermission()
                    }
                }
            } else {
                appeared = false
            }
        }
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
