import SwiftUI
import GroBroDomain

/// Horizontal scrolling gallery of plant photos aligned to timeline
@available(iOS 18.0, macOS 15.0, *)
struct PhotoTimelineGallery: View {

    let photos: [PhotoTimelineItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Photo Timeline")
                    .font(.headline)

                Text("\(photos.count) photos captured")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Horizontal scrolling photo gallery
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(photos) { photo in
                        PhotoTimelineCard(photo: photo)
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 200)
            .background(Color(red: 0.95, green: 0.95, blue: 0.95))
            .cornerRadius(12)
        }
    }
}

// MARK: - Photo Timeline Card

@available(iOS 18.0, macOS 15.0, *)
struct PhotoTimelineCard: View {

    let photo: PhotoTimelineItem

    var body: some View {
        VStack(spacing: 8) {
            // Photo placeholder
            // In real implementation, use AsyncImage or photo loading
            RoundedRectangle(cornerRadius: 12)
                .fill(.green.opacity(0.3))
                .frame(width: 140, height: 140)
                .overlay {
                    Image(systemName: "camera.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.green)
                }
                .accessibilityLabel("Plant photo from day \(photo.ageInDays)")

            // Photo metadata
            VStack(spacing: 2) {
                Text("Day \(photo.ageInDays)")
                    .font(.caption)
                    .fontWeight(.semibold)

                Text(photo.timestamp.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let photos = (0..<8).map { index in
        PhotoTimelineItem(
            id: UUID(),
            photoAssetId: "photo-\(index)",
            timestamp: Calendar.current.date(byAdding: .day, value: -index * 7, to: Date())!,
            ageInDays: index * 7
        )
    }

    if #available(iOS 18.0, macOS 15.0, *) {
        ScrollView {
            PhotoTimelineGallery(photos: photos)
                .padding()
        }
    } else {
        Text("Charts require iOS 18.0 or later")
    }
}
