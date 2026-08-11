import SwiftUI

/// マップアプリ選択のボトムシート。
/// `.confirmationDialog` は文脈によって画面上部に popover 表示されてしまうことがあるため、
/// 常に下から表示されることを保証する `sheet` として実装する。
struct MapAppPickerSheet: View {
    /// 経路の出発点。nil のときは現在地が出発点になる。
    let origin: MapPoint?
    /// 経路の到着点（提案スポット / お気に入りスポット）。
    let destination: MapPoint
    /// 解決済みの現在地。ブラウザ経路で出発点を明示するために使う（#40）。
    var currentLocation: MapPoint?

    @Environment(\.dismiss) private var dismiss

    private var apps: [MapApp] {
        MapLauncher.availableApps()
    }

    var body: some View {
        VStack(spacing: 12) {
            Capsule()
                .fill(Color.secondary.opacity(0.35))
                .frame(width: 36, height: 5)
                .padding(.top, 8)

            Text("マップアプリで開く")
                .font(.headline)
                .padding(.bottom, 4)

            ForEach(apps) { app in
                Button {
                    MapLauncher.openDirections(
                        app,
                        origin: origin,
                        destination: destination,
                        currentLocation: currentLocation
                    )
                    dismiss()
                } label: {
                    Text(app.displayName)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(Color.theme.walk)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.theme.secondaryBackground)
                        .cornerRadius(12)
                }
                .accessibilityLabel(app.displayName)
            }

            Button {
                dismiss()
            } label: {
                Text("キャンセル")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .padding(.top, 2)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
        .frame(maxHeight: .infinity, alignment: .top)
        .modifier(PickerSheetDetents(appCount: apps.count))
    }
}

/// iOS 16+ では内容に合わせた高さのボトムシートに、iOS 15 ではフルシートにフォールバックする。
private struct PickerSheetDetents: ViewModifier {
    let appCount: Int

    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.presentationDetents([.height(CGFloat(appCount) * 62 + 150)])
        } else {
            content
        }
    }
}
