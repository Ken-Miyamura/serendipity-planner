import MapKit
import SwiftUI

/// お気に入り詳細画面
struct FavoriteDetailView: View {
    let favorite: FavoriteSuggestion
    let onDelete: () -> Void

    @State private var showDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // ヘッダー
                headerSection

                // 説明
                descriptionSection

                // 場所情報
                if favorite.placeName != nil {
                    placeSection
                }

                // マップ
                if let latitude = favorite.latitude, let longitude = favorite.longitude {
                    mapSection(latitude: latitude, longitude: longitude)
                }

                // 追加日
                addedDateSection

                // 削除ボタン
                deleteButton
            }
            .padding()
        }
        .navigationTitle("お気に入りの詳細")
        .navigationBarTitleDisplayMode(.inline)
        .alert("お気に入りから削除", isPresented: $showDeleteConfirmation) {
            Button("削除", role: .destructive) {
                onDelete()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("このお気に入りを削除しますか？")
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: favorite.category.iconName)
                .font(.system(size: 48))
                .foregroundColor(Color.theme.color(for: favorite.category))
                .frame(width: 80, height: 80)
                .background(
                    Color.theme.color(for: favorite.category).opacity(0.1)
                )
                .cornerRadius(20)
                .accessibilityHidden(true)

            Text(favorite.title)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(favorite.category.displayName)
                .font(.subheadline)
                .foregroundColor(Color.theme.color(for: favorite.category))
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.theme.color(for: favorite.category).opacity(0.1))
                .cornerRadius(8)
        }
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("詳細")
                .font(.headline)

            Text(favorite.description)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.theme.secondaryBackground)
        .cornerRadius(12)
    }

    private var placeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let placeName = favorite.placeName {
                HStack(spacing: 8) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(Color.theme.color(for: favorite.category))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(placeName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        if let address = favorite.placeAddress {
                            Text(address)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    if let lat = favorite.latitude, let lon = favorite.longitude {
                        Button {
                            openInMaps(name: placeName, latitude: lat, longitude: lon)
                        } label: {
                            Image(systemName: "map.fill")
                                .font(.body)
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.theme.color(for: favorite.category))
                                .cornerRadius(8)
                        }
                        .accessibilityLabel("マップで開く")
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.theme.secondaryBackground)
        .cornerRadius(12)
    }

    private func mapSection(latitude: Double, longitude: Double) -> some View {
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 500,
            longitudinalMeters: 500
        )
        // MapAnnotation 用のダミーデータ
        let annotations = [MapAnnotationItem(id: favorite.id, coordinate: coordinate)]

        return Map(coordinateRegion: .constant(region), annotationItems: annotations) { item in
            MapAnnotation(coordinate: item.coordinate) {
                VStack(spacing: 2) {
                    Image(systemName: favorite.category.iconName)
                        .font(.caption)
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(Color.theme.color(for: favorite.category))
                        .clipShape(Circle())
                        .shadow(radius: 2)

                    Image(systemName: "triangle.fill")
                        .font(.system(size: 6))
                        .foregroundColor(Color.theme.color(for: favorite.category))
                        .rotationEffect(.degrees(180))
                        .offset(y: -4)
                }
            }
        }
        .frame(height: 180)
        .cornerRadius(12)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var addedDateSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "calendar")
                .foregroundColor(.secondary)
            Text("追加日: \(formattedDate)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.theme.secondaryBackground)
        .cornerRadius(12)
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            showDeleteConfirmation = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("お気に入りから削除")
            }
            .font(.subheadline)
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(12)
        }
        .accessibilityLabel("お気に入りから削除")
        .accessibilityHint("この提案をお気に入りから削除します")
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: favorite.addedDate)
    }

    private func openInMaps(name: String, latitude: Double, longitude: Double) {
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
        ])
    }
}

/// Map アノテーション用のヘルパー構造体
private struct MapAnnotationItem: Identifiable {
    let id: UUID
    let coordinate: CLLocationCoordinate2D
}
