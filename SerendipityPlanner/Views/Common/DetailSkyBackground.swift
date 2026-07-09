import SwiftUI

/// 提案詳細・お気に入り詳細で共通利用する背景グラデ。
/// design 準拠の固定グラデ（淡い青 → 暖色グレー → クリーム #AED1EB→#EBE6D9→#F7F5F0）。
struct DetailSkyBackground: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: Color(red: 0.682, green: 0.820, blue: 0.922), location: 0),
                .init(color: Color(red: 0.922, green: 0.902, blue: 0.851), location: 0.34),
                .init(color: Color(red: 0.969, green: 0.961, blue: 0.941), location: 0.70)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
