import SwiftUI
import GroBroDomain

/// Detail modal for environmental events showing full metrics and source device info
@available(iOS 18.0, macOS 15.0, *)
public struct EnvironmentalEventDetail: View {
    let event: Event
    let plantStage: PlantStage
    @Environment(\.dismiss) private var dismiss
    @State private var userSettings = UserSettings.shared

    public init(event: Event, plantStage: PlantStage) {
        self.event = event
        self.plantStage = plantStage
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.deepBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header with device info
                        deviceHeader

                        // Metrics section
                        if let envData = event.environmentalData {
                            metricsSection(envData)
                        }

                        // VPD explanation
                        vpdExplanation

                        // Historical context
                        historicalContext
                    }
                    .padding()
                }
            }
            .navigationTitle("Environmental Reading")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.electricGreen)
                }
            }
        }
    }

    private var deviceHeader: some View {
        GlassCard {
            VStack(spacing: 12) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 48))
                    .foregroundColor(.cyanBright)

                Text(event.environmentalData?.deviceName ?? "Environmental Sensor")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.primaryText)

                Text(event.timestamp, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondaryText)

                Text(event.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.tertiaryText)
            }
        }
    }

    private func metricsSection(_ envData: EnvironmentalData) -> some View {
        VStack(spacing: 16) {
            if let temp = envData.temperatureFahrenheit {
                MetricCard(
                    icon: "thermometer.medium",
                    label: "Temperature",
                    value: userSettings.formatTemperature(temp),
                    color: Color.temperatureColor(for: temp)
                )
            }

            if let humidity = envData.humidityPercent {
                MetricCard(
                    icon: "drop.fill",
                    label: "Humidity",
                    value: userSettings.formatHumidity(humidity),
                    color: .cyanBright
                )
            }

            if let vpd = envData.vpdKilopascal {
                MetricCard(
                    icon: "gauge.medium",
                    label: "VPD",
                    value: userSettings.formatVPD(vpd),
                    color: Color.vpdColor(for: vpd)
                )
            }
        }
    }

    private var vpdExplanation: some View {
        GlassCard(elevation: .subtle) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.infoCyan)
                    Text("What is VPD?")
                        .font(.headline)
                        .foregroundColor(.primaryText)
                }

                Text("Vapor Pressure Deficit (VPD) measures the difference between the moisture in the air and how much moisture the air can hold. Higher VPD means drier air, lower VPD means more humid.")
                    .font(.subheadline)
                    .foregroundColor(.secondaryText)
            }
        }
    }

    private var historicalContext: some View {
        GlassCard(elevation: .subtle) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Growth Stage: \(plantStage.displayName)")
                    .font(.headline)
                    .foregroundColor(.primaryText)

                let status = calculateStatus()
                HStack {
                    Circle()
                        .fill(status.color)
                        .frame(width: 12, height: 12)

                    Text(status.message)
                        .font(.subheadline)
                        .foregroundColor(.secondaryText)
                }
            }
        }
    }

    private func calculateStatus() -> (color: Color, message: String) {
        guard let envData = event.environmentalData,
              let temp = envData.temperatureFahrenheit,
              let humidity = envData.humidityPercent,
              let vpd = envData.vpdKilopascal else {
            return (.tertiaryText, "No data")
        }

        let status = EnvironmentalStatus.calculate(
            temp: temp,
            humidity: humidity,
            vpd: vpd,
            stage: plantStage
        )

        switch status {
        case .optimal:
            return (.successGreen, "Conditions are optimal for \(plantStage.displayName) stage")
        case .caution:
            return (.warningOrange, "Conditions are acceptable but not ideal")
        case .critical:
            return (.criticalRed, "Critical conditions - immediate action recommended")
        }
    }
}

// MARK: - Metric Card

@available(iOS 18.0, macOS 15.0, *)
private struct MetricCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        GlassCard {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(color)
                    .frame(width: 48)

                VStack(alignment: .leading, spacing: 4) {
                    Text(label)
                        .font(.subheadline)
                        .foregroundColor(.secondaryText)

                    Text(value)
                        .font(.system(size: 24, weight: .semibold, design: .monospaced))
                        .foregroundColor(.primaryText)
                }

                Spacer()
            }
        }
    }
}
