import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var opacity: Double = 1.0

    private let accentColor = Color(red: 0.275, green: 0.608, blue: 0.459)
    private let pageBackground = Color(red: 0.97, green: 0.96, blue: 0.94)

    private var appIcon: UIImage {
        if let url = Bundle.main.url(forResource: "AppIcon60x60@2x", withExtension: "png"),
           let data = try? Data(contentsOf: url),
           let image = UIImage(data: data) {
            return image
        }
        return UIImage()
    }

    var body: some View {
        if isActive {
            ContentView()
        } else {
            ZStack {
                pageBackground
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    Image(uiImage: appIcon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)

                    Text("Serendipity Planner")
                        .font(.title)
                        .fontWeight(.medium)
                        .foregroundColor(accentColor)
                }
            }
            .opacity(opacity)
            .onAppear {
                // 1秒後にフェードアウトしてメイン画面に遷移
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        opacity = 0.0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        isActive = true
                    }
                }
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
