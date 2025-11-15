import SwiftUI
import Charts
import GroBroDomain

/// Bar chart showing watering frequency over time
@available(iOS 18.0, macOS 15.0, *)
struct WateringFrequencyChart: View {

    let dataPoints: [WateringDataPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Watering Frequency")
                    .font(.headline)

                Text("\(dataPoints.count) watering events • \(String(format: "%.1f", totalVolume))L total")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Chart
            Chart(dataPoints) { point in
                BarMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Count", point.count)
                )
                .foregroundStyle(.blue.gradient)
                .accessibilityLabel("Watered \(point.count) time\(point.count == 1 ? "" : "s") on \(point.date.formatted(date: .abbreviated, time: .omitted))")
                .accessibilityValue("\(String(format: "%.1f", point.totalVolume)) liters")
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 6)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let count = value.as(Int.self) {
                            Text("\(count)x")
                                .font(.caption)
                        }
                    }
                }
            }
            .frame(height: 200)
            .padding()
            .background(Color(red: 0.95, green: 0.95, blue: 0.95))
            .cornerRadius(12)
        }
    }

    private var totalVolume: Double {
        dataPoints.reduce(0) { $0 + $1.totalVolume }
    }
}

// MARK: - Preview

#Preview {
    let baseDate = Date()
    let dataPoints = (0..<15).map { day in
        WateringDataPoint(
            date: Calendar.current.date(byAdding: .day, value: -day * 2, to: baseDate)!,
            count: Int.random(in: 1...3),
            totalVolume: Double.random(in: 0.5...2.0)
        )
    }.reversed()

    if #available(iOS 18.0, *) {
        ScrollView {
            WateringFrequencyChart(dataPoints: Array(dataPoints))
                .padding()
        }
    } else {
        Text("Charts require iOS 18.0 or later")
    }
}
