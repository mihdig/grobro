import SwiftUI
import GroBroDomain

/// Spectrum recommendation chart (Pro feature)
@MainActor
public struct SpectrumChartView: View {
    let recommendation: SpectrumRecommendation

    public init(recommendation: SpectrumRecommendation) {
        self.recommendation = recommendation
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "light.spectrum.horizontal")
                    .foregroundColor(.purpleNeon)

                Text("Spectrum Recommendation")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primaryText)

                Spacer()

                // Pro badge
                proBadge
            }

            // Spectrum bar chart
            HStack(spacing: 12) {
                spectrumBar(
                    label: "Blue",
                    percentage: recommendation.bluePercentage,
                    color: .cyanBright,
                    range: "400-500nm"
                )

                spectrumBar(
                    label: "Green",
                    percentage: 20, // Typically lower, constant across stages
                    color: .sageGreen,
                    range: "500-600nm"
                )

                spectrumBar(
                    label: "Red",
                    percentage: recommendation.redPercentage,
                    color: .criticalRed,
                    range: "600-700nm"
                )
            }
            .frame(height: 180)

            // Description
            Text(recommendation.description)
                .font(.system(size: 14))
                .foregroundColor(.secondaryText)
                .padding(.top, 4)

            // Kelvin recommendation
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recommended Color Temperature")
                        .font(.system(size: 12))
                        .foregroundColor(.tertiaryText)

                    Text("\(recommendation.kelvin.lowerBound)-\(recommendation.kelvin.upperBound)K")
                        .font(.system(size: 18, weight: .semibold, design: .monospaced))
                        .foregroundColor(.electricGreen)
                }

                Spacer()

                kelvinIndicator
            }
            .padding(.top, 8)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        colors: [.purpleNeon.opacity(0.5), .cyanBright.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    private func spectrumBar(
        label: String,
        percentage: Double,
        color: Color,
        range: String
    ) -> some View {
        VStack(spacing: 8) {
            // Bar
            GeometryReader { geometry in
                VStack {
                    Spacer()

                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.8), color],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: geometry.size.height * CGFloat(percentage / 100))
                        .shadow(color: color.opacity(0.5), radius: 4)
                }
            }

            // Percentage label
            Text("\(Int(percentage))%")
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(.primaryText)

            // Wavelength range
            Text(range)
                .font(.system(size: 10))
                .foregroundColor(.tertiaryText)

            // Color label
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
        }
    }

    private var proBadge: some View {
        Text("PRO")
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.deepBackground)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                LinearGradient(
                    colors: [.purpleNeon, .cyanBright],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var kelvinIndicator: some View {
        HStack(spacing: 4) {
            ForEach(kelvinColorGradient, id: \.0) { kelvin, color in
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: 20, height: 40)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.primaryText.opacity(0.3), lineWidth: 1)
        )
    }

    // Color gradient approximation for Kelvin temperatures
    private var kelvinColorGradient: [(Int, Color)] {
        [
            (2700, Color(red: 1.0, green: 0.6, blue: 0.3)),   // Warm orange-red
            (3000, Color(red: 1.0, green: 0.7, blue: 0.4)),   // Warm white
            (4000, Color(red: 1.0, green: 0.85, blue: 0.7)),  // Neutral
            (5000, Color(red: 1.0, green: 0.95, blue: 0.9)),  // Cool white
            (6500, Color(red: 0.9, green: 0.95, blue: 1.0))   // Daylight blue
        ]
    }
}
