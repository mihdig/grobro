import SwiftUI
import Charts
import GroBroDomain

/// Growth timeline chart showing plant age with stage transitions
@available(iOS 18.0, macOS 15.0, *)
struct GrowthTimelineChart: View {

    let data: GrowthTimelineData

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Growth Timeline")
                    .font(.headline)

                Text("\(data.currentAge) days old • \(data.currentStage.displayName)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Chart
            Chart {
                // Stage bands as colored areas
                ForEach(Array(data.stageTransitions.enumerated()), id: \.element.id) { index, transition in
                    let nextTransition = index < data.stageTransitions.count - 1
                        ? data.stageTransitions[index + 1]
                        : nil

                    let endDay = nextTransition != nil
                        ? Calendar.current.dateComponents([.day], from: data.startDate, to: nextTransition!.date).day ?? data.currentAge
                        : data.currentAge

                    let startDay = Calendar.current.dateComponents([.day], from: data.startDate, to: transition.date).day ?? 0

                    // Area mark for stage duration
                    RectangleMark(
                        xStart: .value("Start", startDay),
                        xEnd: .value("End", endDay),
                        yStart: .value("Y Start", 0),
                        yEnd: .value("Y End", 1)
                    )
                    .foregroundStyle(colorForStage(transition.stage).opacity(0.3))
                    .accessibilityLabel("\(transition.stage.displayName) stage from day \(startDay) to day \(endDay)")

                    // Stage marker
                    if startDay > 0 {
                        RuleMark(x: .value("Day", startDay))
                            .foregroundStyle(colorForStage(transition.stage))
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
                            .annotation(position: .top, alignment: .center) {
                                Text(transition.stage.displayName)
                                    .font(.caption2)
                                    .foregroundStyle(colorForStage(transition.stage))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(colorForStage(transition.stage).opacity(0.2))
                                    .cornerRadius(4)
                            }
                    }
                }

                // Current age marker
                RuleMark(x: .value("Today", data.currentAge))
                    .foregroundStyle(.primary)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .annotation(position: .top) {
                        VStack(spacing: 2) {
                            Text("Today")
                                .font(.caption2)
                                .fontWeight(.semibold)
                            Text("Day \(data.currentAge)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .cornerRadius(6)
                    }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let day = value.as(Int.self) {
                            Text("Day \(day)")
                                .font(.caption)
                        }
                    }
                }
            }
            .chartYAxis(.hidden)
            .chartXScale(domain: 0...max(data.currentAge, 1))
            .frame(height: 150)
            .padding()
            .background(Color(red: 0.95, green: 0.95, blue: 0.95))
            .cornerRadius(12)

            // Legend
            HStack(spacing: 16) {
                ForEach(PlantStage.allCases, id: \.self) { stage in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(colorForStage(stage))
                            .frame(width: 8, height: 8)
                        Text(stage.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal)
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
        }
    }
}

// MARK: - Preview

#Preview {
    let startDate = Calendar.current.date(byAdding: .day, value: -45, to: Date())!
    let vegDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
    let flowerDate = Calendar.current.date(byAdding: .day, value: -10, to: Date())!

    let data = GrowthTimelineData(
        plantId: UUID(),
        startDate: startDate,
        currentAge: 45,
        currentStage: .flowering,
        stageTransitions: [
            StageTransition(stage: .seedling, date: startDate),
            StageTransition(stage: .vegetative, date: vegDate),
            StageTransition(stage: .flowering, date: flowerDate)
        ]
    )

    if #available(iOS 18.0, *) {
        ScrollView {
            GrowthTimelineChart(data: data)
                .padding()
        }
    } else {
        Text("Charts require iOS 18.0 or later")
    }
}
