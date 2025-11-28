import SwiftUI
import Charts
import GroBroDomain

/// Pie/donut chart showing distribution of event types
@available(iOS 18.0, macOS 15.0, *)
struct EventDistributionChart: View {

    let data: [EventDistributionData]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Event Distribution")
                    .font(.headline)

                Text("\(totalEvents) total events logged")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .center, spacing: 20) {
                // Pie Chart
                Chart(data) { item in
                    SectorMark(
                        angle: .value("Count", item.count),
                        innerRadius: .ratio(0.5),
                        angularInset: 1.5
                    )
                    .foregroundStyle(colorForEventType(item.eventType))
                    .accessibilityLabel("\(item.eventType.displayName)")
                    .accessibilityValue("\(item.count) events, \(String(format: "%.1f", item.percentage))%")
                }
                .frame(height: 180)

                // Legend
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(data) { item in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(colorForEventType(item.eventType))
                                .frame(width: 12, height: 12)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.eventType.displayName)
                                    .font(.caption)
                                    .fontWeight(.medium)

                                Text("\(item.count) (\(String(format: "%.0f", item.percentage))%)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color(red: 0.95, green: 0.95, blue: 0.95))
            .cornerRadius(12)
        }
    }

    private var totalEvents: Int {
        data.reduce(0) { $0 + $1.count }
    }

    // MARK: - Colorblind-Friendly Colors

    private func colorForEventType(_ type: EventType) -> Color {
        switch type {
        case .watering:
            return Color(red: 0.0, green: 0.45, blue: 0.70) // Blue
        case .feeding:
            return Color(red: 0.0, green: 0.62, blue: 0.45) // Teal
        case .flush:
            return Color(red: 0.90, green: 0.62, blue: 0.0) // Orange
        case .note:
            return Color(red: 0.83, green: 0.37, blue: 0.0) // Vermillion
        case .photo:
            return Color(red: 0.80, green: 0.47, blue: 0.65) // Magenta
        case .stress:
            return Color(red: 0.90, green: 0.0, blue: 0.0) // Red
        case .environment:
            return Color(red: 0.35, green: 0.70, blue: 0.90) // Sky Blue
        case .lightCheck:
            return Color(red: 0.95, green: 0.90, blue: 0.25) // Yellow
        }
    }
}

// MARK: - Preview

#Preview {
    let data = [
        EventDistributionData(eventType: .watering, count: 45, percentage: 45),
        EventDistributionData(eventType: .feeding, count: 25, percentage: 25),
        EventDistributionData(eventType: .photo, count: 15, percentage: 15),
        EventDistributionData(eventType: .note, count: 10, percentage: 10),
        EventDistributionData(eventType: .flush, count: 5, percentage: 5)
    ]

    if #available(iOS 18.0, macOS 15.0, *) {
        ScrollView {
            EventDistributionChart(data: data)
                .padding()
        }
    } else {
        Text("Charts require iOS 18.0 or later")
    }
}
