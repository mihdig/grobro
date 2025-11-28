import SwiftUI
import GroBroDomain

/// Progress bar showing current DLI vs target range
@MainActor
public struct DLIProgressView: View {
    let current: Double
    let target: ClosedRange<Double>
    let photoperiod: Double

    public init(current: Double, target: ClosedRange<Double>, photoperiod: Double) {
        self.current = current
        self.target = target
        self.photoperiod = photoperiod
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Current vs Target
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current DLI")
                        .font(.system(size: 12))
                        .foregroundColor(.tertiaryText)

                    Text(String(format: "%.1f", current))
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(statusColor)

                    Text("mol/m²/day")
                        .font(.system(size: 12))
                        .foregroundColor(.secondaryText)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Target Range")
                        .font(.system(size: 12))
                        .foregroundColor(.tertiaryText)

                    Text("\(Int(target.lowerBound))-\(Int(target.upperBound))")
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(.electricGreen)

                    Text("mol/m²/day")
                        .font(.system(size: 12))
                        .foregroundColor(.secondaryText)
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.tertiaryText.opacity(0.2))
                        .frame(height: 16)

                    // Target range indicator (green zone)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.successGreen.opacity(0.3))
                        .frame(
                            width: targetRangeWidth(in: geometry.size.width),
                            height: 16
                        )
                        .offset(x: targetStartOffset(in: geometry.size.width))

                    // Current value indicator
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [statusColor, statusColor.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: progressWidth(in: geometry.size.width),
                            height: 16
                        )
                        .shadow(color: statusColor.opacity(0.5), radius: 4)

                    // Markers for target bounds
                    markerLine(at: targetStartOffset(in: geometry.size.width))
                    markerLine(at: targetStartOffset(in: geometry.size.width) + targetRangeWidth(in: geometry.size.width))
                }
            }
            .frame(height: 16)

            // Status message
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)

                Text(statusMessage)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondaryText)
            }
        }
    }

    private func markerLine(at offset: CGFloat) -> some View {
        Rectangle()
            .fill(Color.electricGreen)
            .frame(width: 2, height: 20)
            .offset(x: offset, y: -2)
    }

    private func progressWidth(in totalWidth: CGFloat) -> CGFloat {
        let maxDLI: Double = 60 // Reasonable max for display
        let fraction = min(current / maxDLI, 1.0)
        return totalWidth * CGFloat(fraction)
    }

    private func targetStartOffset(in totalWidth: CGFloat) -> CGFloat {
        let maxDLI: Double = 60
        let fraction = target.lowerBound / maxDLI
        return totalWidth * CGFloat(fraction)
    }

    private func targetRangeWidth(in totalWidth: CGFloat) -> CGFloat {
        let maxDLI: Double = 60
        let rangeFraction = (target.upperBound - target.lowerBound) / maxDLI
        return totalWidth * CGFloat(rangeFraction)
    }

    private var statusColor: Color {
        if target.contains(current) {
            return .successGreen
        } else if current < target.lowerBound {
            return .warningOrange
        } else {
            return .criticalRed
        }
    }

    private var statusMessage: String {
        if target.contains(current) {
            return "Optimal DLI for current stage ✓"
        } else if current < target.lowerBound {
            let deficit = target.lowerBound - current
            return String(format: "Increase by %.1f mol/m²/day (boost intensity or extend photoperiod)", deficit)
        } else {
            let excess = current - target.upperBound
            return String(format: "Reduce by %.1f mol/m²/day (lower intensity or shorten photoperiod)", excess)
        }
    }
}
