import SwiftUI
import Charts
import GroBroDomain

/// Horizontal bar chart comparing time spent in each growth stage
@available(iOS 18.0, macOS 15.0, *)
struct StageDurationChart: View {

    let data: [StageDurationData]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Stage Duration")
                    .font(.headline)

                Text("Days spent in each growth phase")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Chart
            Chart(data) { item in
                BarMark(
                    x: .value("Days", item.durationDays),
                    y: .value("Stage", item.stage.displayName)
                )
                .foregroundStyle(colorForStage(item.stage).gradient)
                .annotation(position: .trailing, alignment: .leading) {
                    Text("\(item.durationDays) days")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)
                }
                .accessibilityLabel("\(item.stage.displayName) stage")
                .accessibilityValue("\(item.durationDays) days")
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let days = value.as(Int.self) {
                            Text("\(days)d")
                                .font(.caption)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let stage = value.as(String.self) {
                            Text(stage)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
            .frame(height: CGFloat(data.count * 60))
            .padding()
            .background(Color(red: 0.95, green: 0.95, blue: 0.95))
            .cornerRadius(12)
        }
    }

    // MARK: - Color Mapping

    private func colorForStage(_ stage: PlantStage) -> Color {
        switch stage {
        case .seedling:
            return .green
        case .vegetative:
            return .blue
        case .flowering:
            return .purple
        case .drying:
            return .orange
        case .curing:
            return .brown
        }
    }
}

// MARK: - Preview

#Preview {
    let startDate = Date().addingTimeInterval(-60 * 24 * 60 * 60) // 60 days ago
    let data = [
        StageDurationData(
            stage: .seedling,
            durationDays: 14,
            startDate: startDate,
            endDate: startDate.addingTimeInterval(14 * 24 * 60 * 60)
        ),
        StageDurationData(
            stage: .vegetative,
            durationDays: 30,
            startDate: startDate.addingTimeInterval(14 * 24 * 60 * 60),
            endDate: startDate.addingTimeInterval(44 * 24 * 60 * 60)
        ),
        StageDurationData(
            stage: .flowering,
            durationDays: 16,
            startDate: startDate.addingTimeInterval(44 * 24 * 60 * 60),
            endDate: Date()
        )
    ]

    if #available(iOS 18.0, macOS 15.0, *) {
        ScrollView {
            StageDurationChart(data: data)
                .padding()
        }
    } else {
        Text("Charts require iOS 18.0 or later")
    }
}
