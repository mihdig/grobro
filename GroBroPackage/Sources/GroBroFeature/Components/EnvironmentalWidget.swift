import SwiftUI

/// Compact live environmental data display widget for AC Infinity integration
/// Shows real-time temperature, humidity, and VPD with status indicators
///
/// Usage:
/// ```swift
/// EnvironmentalWidget(
///     temperature: 78.4,
///     humidity: 62,
///     vpd: 1.15,
///     status: .optimal,
///     isConnected: true
/// )
/// ```
struct EnvironmentalWidget: View {
    let temperature: Double
    let humidity: Double
    let vpd: Double
    let status: EnvironmentStatus
    let isConnected: Bool

    @State private var isExpanded: Bool = false
    @State private var isPulsing: Bool = false

    enum EnvironmentStatus {
        case optimal
        case caution
        case critical
        case offline

        var color: Color {
            switch self {
            case .optimal: return .electricGreen
            case .caution: return .warningOrange
            case .critical: return .criticalRed
            case .offline: return .tertiaryText
            }
        }

        var label: String {
            switch self {
            case .optimal: return "Optimal"
            case .caution: return "Caution"
            case .critical: return "Critical"
            case .offline: return "Offline"
            }
        }
    }

    var body: some View {
        GlassCard(isHighlighted: status == .optimal && isExpanded) {
            VStack(spacing: isExpanded ? 12 : 0) {
                // Header
                HStack(spacing: 12) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .foregroundColor(isConnected ? Color.electricGreen : Color.tertiaryText)
                        .symbolEffect(.pulse, isActive: isConnected && isPulsing)

                    Text("Environment")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primaryText)

                    Spacer()

                    // Status indicator
                    HStack(spacing: 6) {
                        Circle()
                            .fill(status.color)
                            .frame(width: 8, height: 8)
                            .shadow(color: status.color.opacity(0.6), radius: isPulsing ? 6 : 4)

                        if isExpanded {
                            Text(status.label)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(status.color)
                        }
                    }

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.tertiaryText)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }

                // Expanded metrics
                if isExpanded {
                    Divider()
                        .background(Color.surfaceLight)
                        .transition(.opacity)

                    HStack(spacing: 16) {
                        MetricDisplay(
                            icon: "thermometer.medium",
                            value: String(format: "%.1f°F", temperature),
                            label: "Temp",
                            color: .temperatureColor(for: temperature)
                        )

                        Divider()
                            .frame(height: 60)
                            .background(Color.surfaceLight)

                        MetricDisplay(
                            icon: "drop.fill",
                            value: String(format: "%.0f%%", humidity),
                            label: "RH",
                            color: .cyanBright
                        )

                        Divider()
                            .frame(height: 60)
                            .background(Color.surfaceLight)

                        MetricDisplay(
                            icon: "gauge.medium",
                            value: String(format: "%.2f", vpd),
                            label: "VPD",
                            color: .vpdColor(for: vpd)
                        )
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                }
            }
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isExpanded.toggle()
            }
        }
        .onAppear {
            // Start pulsing animation for status indicator
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}

// MARK: - Metric Display Component

struct MetricDisplay: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .symbolRenderingMode(.hierarchical)

            Text(value)
                .font(.system(size: 18, weight: .semibold, design: .monospaced))
                .foregroundColor(.primaryText)
                .contentTransition(.numericText())

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.tertiaryText)
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Collapsed Variant

extension EnvironmentalWidget {
    /// Compact one-line summary variant
    static func compact(
        temperature: Double,
        humidity: Double,
        status: EnvironmentStatus,
        isConnected: Bool
    ) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 12))
                .foregroundColor(isConnected ? Color.electricGreen : Color.tertiaryText)

            Image(systemName: "thermometer.medium")
                .font(.system(size: 12))
            Text("\(Int(temperature))°F")
                .font(.system(size: 13, design: .monospaced))

            Image(systemName: "drop.fill")
                .font(.system(size: 12))
            Text("\(Int(humidity))%")
                .font(.system(size: 13, design: .monospaced))

            Circle()
                .fill(status.color)
                .frame(width: 6, height: 6)
        }
        .foregroundColor(.cyanBright)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.surfaceDark.opacity(0.7))
                .overlay(
                    Capsule()
                        .stroke(Color.electricGreen.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview

#Preview("Environmental Widget") {
    ZStack {
        Color.deepBackground
            .ignoresSafeArea()

        VStack(spacing: 24) {
            // Optimal state
            EnvironmentalWidget(
                temperature: 78.4,
                humidity: 62,
                vpd: 1.15,
                status: .optimal,
                isConnected: true
            )

            // Caution state
            EnvironmentalWidget(
                temperature: 85.2,
                humidity: 45,
                vpd: 1.58,
                status: .caution,
                isConnected: true
            )

            // Critical state
            EnvironmentalWidget(
                temperature: 92.0,
                humidity: 35,
                vpd: 2.1,
                status: .critical,
                isConnected: true
            )

            // Offline state
            EnvironmentalWidget(
                temperature: 0,
                humidity: 0,
                vpd: 0,
                status: .offline,
                isConnected: false
            )

            // Compact variant
            EnvironmentalWidget.compact(
                temperature: 78.4,
                humidity: 62,
                status: .optimal,
                isConnected: true
            )
        }
        .padding()
    }
}
