import SwiftUI
import GroBroDomain

#if os(iOS)

/// Manual light distance entry fallback for devices without ARKit
@MainActor
public struct ManualDistanceEntryView: View {
    @Environment(\.dismiss) private var dismiss
    let plant: Plant
    @Binding var lightType: LightType
    let onSave: (Double, LightType) -> Void

    @State private var distanceInches: String = ""
    @State private var showRecommendation = false

    public init(
        plant: Plant,
        lightType: Binding<LightType>,
        onSave: @escaping (Double, LightType) -> Void
    ) {
        self.plant = plant
        _lightType = lightType
        self.onSave = onSave

        if let existing = plant.lightDistance {
            _distanceInches = State(initialValue: "\(Int(existing))")
        }
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Info card
                infoCard

                // Light type picker
                lightTypePicker

                // Distance input
                distanceInput

                // Recommendation card
                if let distance = Double(distanceInches), distance > 0 {
                    recommendationCard(for: distance)
                }

                // Educational tips
                tipsCard

                Spacer()

                // Save button
                saveButton
            }
            .padding()
        }
        .navigationTitle("Manual Distance Entry")
        .inlineNavigationTitle()
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.infoCyan)
                Text("Measure Light Distance")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primaryText)
            }

            Text("Use a measuring tape or ruler to measure the distance from your light source to the top of your plant canopy.")
                .font(.system(size: 14))
                .foregroundColor(.secondaryText)
        }
        .padding()
        .background(Color.infoCyan.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var lightTypePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Light Type")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondaryText)

            Picker("Light Type", selection: $lightType) {
                ForEach(LightType.allCases) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.menu)
            .padding()
            .background(Color.tertiaryText.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var distanceInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Distance (inches)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondaryText)

            HStack {
                TextField("Enter distance", text: $distanceInches)
                    .decimalKeyboard()
                    .font(.system(size: 24, weight: .semibold, design: .monospaced))
                    .foregroundColor(.primaryText)
                    .padding()
                    .background(Color.tertiaryText.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Text("\"")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.secondaryText)
            }

            if let distance = Double(distanceInches), distance > 0 {
                Text("\(Int((distance * 2.54).rounded())) cm")
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(.cyanBright)
            }
        }
    }

    private func recommendationCard(for distance: Double) -> some View {
        let engine = LightDistanceRecommendationEngine()
        let recommendation = engine.evaluate(distance: distance, lightType: lightType, stage: plant.stage)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: statusIcon(recommendation.status))
                    .foregroundColor(statusColor(recommendation.status))

                Text("Recommendation")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primaryText)
            }

            Text(recommendation.message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondaryText)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Optimal Range")
                        .font(.system(size: 12))
                        .foregroundColor(.tertiaryText)

                    Text("\(Int(recommendation.optimalRange.lowerBound))-\(Int(recommendation.optimalRange.upperBound))\"")
                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                        .foregroundColor(.electricGreen)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Your Distance")
                        .font(.system(size: 12))
                        .foregroundColor(.tertiaryText)

                    Text("\(Int(distance))\"")
                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                        .foregroundColor(statusColor(recommendation.status))
                }
            }
        }
        .padding()
        .background(statusColor(recommendation.status).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(statusColor(recommendation.status).opacity(0.3), lineWidth: 1)
        )
    }

    private var tipsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.warningOrange)
                Text("Tips")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primaryText)
            }

            VStack(alignment: .leading, spacing: 8) {
                tipRow(icon: "exclamationmark.triangle.fill", text: "Too close can cause light burn (bleaching)", color: .warningOrange)
                tipRow(icon: "arrow.down.circle.fill", text: "Too far reduces growth rate and yields", color: .infoCyan)
                tipRow(icon: "chart.line.uptrend.xyaxis", text: "Adjust distance as plant grows", color: .successGreen)
            }
        }
        .padding()
        .background(Color.tertiaryText.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func tipRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)
                .frame(width: 16)

            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.secondaryText)
        }
    }

    private var saveButton: some View {
        Button(action: saveMeasurement) {
            Text("Save Measurement")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.deepBackground)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    isValidDistance ?
                    LinearGradient(
                        colors: [.electricGreen, .neonGreen],
                        startPoint: .leading,
                        endPoint: .trailing
                    ) : LinearGradient(
                        colors: [.tertiaryText, .tertiaryText],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!isValidDistance)
    }

    private var isValidDistance: Bool {
        guard let distance = Double(distanceInches) else { return false }
        return distance > 0 && distance < 120 // Reasonable max of 10 feet
    }

    private func saveMeasurement() {
        guard let distance = Double(distanceInches) else { return }
        onSave(distance, lightType)
        dismiss()
    }

    private func statusIcon(_ status: LightDistanceRecommendationEngine.DistanceStatus) -> String {
        switch status {
        case .optimal:
            return "checkmark.circle.fill"
        case .tooClose:
            return "exclamationmark.triangle.fill"
        case .tooFar:
            return "arrow.down.circle.fill"
        }
    }

    private func statusColor(_ status: LightDistanceRecommendationEngine.DistanceStatus) -> Color {
        switch status {
        case .optimal:
            return .successGreen
        case .tooClose:
            return .warningOrange
        case .tooFar:
            return .infoCyan
        }
    }
}

#endif
