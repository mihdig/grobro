import SwiftUI
import GroBroDomain

/// Circular 24-hour clock visualization of light schedule
@MainActor
public struct ScheduleVisualizerView: View {
    let hoursOn: Int
    let hoursOff: Int
    let startTime: Date

    public init(hoursOn: Int, hoursOff: Int, startTime: Date) {
        self.hoursOn = hoursOn
        self.hoursOff = hoursOff
        self.startTime = startTime
    }

    public var body: some View {
        VStack(spacing: 16) {
            // Circular clock visualization
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.tertiaryText.opacity(0.3), lineWidth: 20)

                // Light period arc
                Circle()
                    .trim(from: lightStartFraction, to: lightEndFraction)
                    .stroke(
                        LinearGradient(
                            colors: [.electricGreen, .neonGreen],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: .electricGreen.opacity(0.5), radius: 8)

                // Center text
                VStack(spacing: 4) {
                    Text("\(hoursOn)/\(hoursOff)")
                        .font(.system(size: 40, weight: .bold, design: .monospaced))
                        .foregroundColor(.electricGreen)

                    Text("Lights on/off")
                        .font(.system(size: 13))
                        .foregroundColor(.secondaryText)
                }
            }
            .frame(height: 200)

            // Time labels
            HStack {
                timeLabel(
                    icon: "sunrise.fill",
                    label: "Lights On",
                    time: startTime,
                    color: .electricGreen
                )

                Spacer()

                timeLabel(
                    icon: "sunset.fill",
                    label: "Lights Off",
                    time: offTime,
                    color: .tertiaryText
                )
            }
        }
    }

    private func timeLabel(icon: String, label: String, time: Date, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(label)
                    .font(.system(size: 12))
            }
            .foregroundColor(color)

            Text(time, format: .dateTime.hour().minute())
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundColor(.primaryText)
        }
    }

    private var offTime: Date {
        Calendar.current.date(byAdding: .hour, value: hoursOn, to: startTime) ?? startTime
    }

    // Calculate the start fraction for the light period on the 24-hour circle
    private var lightStartFraction: CGFloat {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: startTime)
        let minute = calendar.component(.minute, from: startTime)
        let totalMinutes = Double(hour * 60 + minute)
        return CGFloat(totalMinutes / (24 * 60))
    }

    // Calculate the end fraction for the light period
    private var lightEndFraction: CGFloat {
        let startFraction = lightStartFraction
        let lightPeriodFraction = CGFloat(hoursOn) / 24.0
        var endFraction = startFraction + lightPeriodFraction

        // Handle wrap-around past midnight
        if endFraction > 1.0 {
            endFraction -= 1.0
        }

        return endFraction
    }
}
