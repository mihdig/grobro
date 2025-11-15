import SwiftUI
import GroBroDomain

/// Environmental event row component for diary timeline
/// Shows device-sourced environmental data with glassmorphic cyan styling
@available(iOS 18.0, macOS 15.0, *)
public struct EnvironmentalEventRow: View {
    let event: Event
    let plantStage: PlantStage
    @State private var userSettings = UserSettings.shared

    public init(event: Event, plantStage: PlantStage) {
        self.event = event
        self.plantStage = plantStage
    }

    public var body: some View {
        GlassCard(elevation: .subtle, cornerRadius: 12, padding: 12) {
            HStack(spacing: 12) {
                // Device badge icon
                deviceIcon
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(Color.cyanBright.opacity(0.1))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(deviceName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondaryText)

                        Spacer()

                        // Status indicator with glow
                        Circle()
                            .fill(statusColor)
                            .frame(width: 8, height: 8)
                            .shadow(color: statusColor.opacity(0.6), radius: 4)
                    }

                    // Environmental metrics
                    if let envData = event.environmentalData {
                        HStack(spacing: 16) {
                            if let temp = envData.temperatureFahrenheit {
                                CompactMetricDisplay(
                                    icon: "thermometer.medium",
                                    value: userSettings.formatTemperature(temp),
                                    color: Color.temperatureColor(for: temp)
                                )
                            }

                            if let humidity = envData.humidityPercent {
                                CompactMetricDisplay(
                                    icon: "drop.fill",
                                    value: userSettings.formatHumidity(humidity),
                                    color: .cyanBright
                                )
                            }

                            if let vpd = envData.vpdKilopascal {
                                CompactMetricDisplay(
                                    icon: "gauge.medium",
                                    value: userSettings.formatVPD(vpd),
                                    color: Color.vpdColor(for: vpd)
                                )
                            }
                        }
                    }

                    // Timestamp
                    Text(event.timestamp, style: .relative)
                        .font(.system(size: 12))
                        .foregroundColor(.tertiaryText)
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            // Correlation badge (if applicable)
            if let correlation = event.correlation {
                Text(correlation.message)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.warningOrange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.warningOrange.opacity(0.2))
                    )
                    .offset(x: -8, y: 8)
            }
        }
    }

    // MARK: - Computed Properties

    private var deviceIcon: some View {
        Group {
            switch event.source {
            case .acInfinity:
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .foregroundColor(.cyanBright)
            case .vivosun:
                Image(systemName: "sensor.fill")
                    .foregroundColor(.cyanBright)
            case .manual:
                Image(systemName: "hand.tap.fill")
                    .foregroundColor(.sageGreen)
            default:
                Image(systemName: "sensor")
                    .foregroundColor(.cyanBright)
            }
        }
    }

    private var deviceName: String {
        event.environmentalData?.deviceName ?? {
            switch event.source {
            case .acInfinity: return "AC Infinity"
            case .vivosun: return "Vivosun"
            case .manual: return "Manual Entry"
            default: return "Sensor"
            }
        }()
    }

    private var statusColor: Color {
        guard let envData = event.environmentalData,
              let temp = envData.temperatureFahrenheit,
              let humidity = envData.humidityPercent,
              let vpd = envData.vpdKilopascal else {
            return .tertiaryText
        }

        let status = EnvironmentalStatus.calculate(
            temp: temp,
            humidity: humidity,
            vpd: vpd,
            stage: plantStage
        )

        switch status {
        case .optimal: return .successGreen
        case .caution: return .warningOrange
        case .critical: return .criticalRed
        }
    }
}

// MARK: - Metric Display Component

/// Small compact metric display with icon and value (used in event rows)
@available(iOS 18.0, macOS 15.0, *)
private struct CompactMetricDisplay: View {
    let icon: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.primaryText)
        }
    }
}

// MARK: - Preview

#Preview("Environmental Event Row") {
    if #available(iOS 18.0, macOS 15.0, *) {
        ZStack {
            Color.deepBackground
                .ignoresSafeArea()

            VStack(spacing: 16) {
                // Optimal event
                EnvironmentalEventRow(
                    event: Event(
                        plantId: UUID(),
                        type: .environment,
                        timestamp: Date(),
                        source: .acInfinity,
                        environmentalData: EnvironmentalData(
                            temperatureFahrenheit: 75,
                            humidityPercent: 60,
                            vpdKilopascal: 1.0,
                            deviceName: "Controller 69",
                            visualStyle: .automatic
                        )
                    ),
                    plantStage: .vegetative
                )

                // Caution event
                EnvironmentalEventRow(
                    event: Event(
                        plantId: UUID(),
                        type: .environment,
                        timestamp: Date().addingTimeInterval(-3600),
                        source: .vivosun,
                        environmentalData: EnvironmentalData(
                            temperatureFahrenheit: 85,
                            humidityPercent: 45,
                            vpdKilopascal: 1.5,
                            deviceName: "Grow Tent 1",
                            visualStyle: .automatic
                        )
                    ),
                    plantStage: .flowering
                )

                // Critical event
                EnvironmentalEventRow(
                    event: Event(
                        plantId: UUID(),
                        type: .environment,
                        timestamp: Date().addingTimeInterval(-7200),
                        source: .manual,
                        environmentalData: EnvironmentalData(
                            temperatureFahrenheit: 95,
                            humidityPercent: 30,
                            vpdKilopascal: 2.2,
                            deviceName: nil,
                            visualStyle: .manual
                        )
                    ),
                    plantStage: .seedling
                )
            }
            .padding()
        }
    } else {
        Text("Requires iOS 18.0+")
    }
}
