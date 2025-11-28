import SwiftUI
import GroBroDomain

/// Main view displaying comprehensive light recommendations
@MainActor
public struct LightRecommendationsView: View {
    let plant: Plant
    let currentPPFD: Double?
    let isPro: Bool

    @State private var customSchedule: LightSchedule?
    @State private var showScheduleEditor = false

    private let recommendationEngine = LightRecommendationEngine()
    private let dliCalculator = DLICalculator()

    public init(plant: Plant, currentPPFD: Double? = nil, isPro: Bool = false) {
        self.plant = plant
        self.currentPPFD = currentPPFD
        self.isPro = isPro
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Current stage indicator
                stageCard

                // Photoperiod recommendation
                photoperiodCard

                // PPFD recommendation
                ppfdCard

                // DLI tracking
                if let ppfd = currentPPFD {
                    dliCard(ppfd: ppfd)
                }

                // Spectrum recommendation (Pro)
                if isPro {
                    spectrumCard
                }

                // Educational tooltips
                educationalCard

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Light Recommendations")
    }

    private var recommendation: LightRecommendation {
        recommendationEngine.recommendation(
            for: plant.stage,
            lightType: plant.lightType ?? .fullSpectrumLED
        )
    }

    private var stageCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "leaf.fill")
                    .foregroundColor(.successGreen)

                Text("Current Stage: \(plant.stage.displayName)")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primaryText)

                Spacer()
            }

            if plant.stage == .vegetative || plant.stage == .flowering {
                Text("Recommendations auto-update when you transition to the next stage")
                    .font(.system(size: 12))
                    .foregroundColor(.secondaryText)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var photoperiodCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.electricGreen)

                Text("Light Schedule")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primaryText)

                Spacer()

                Button(action: { showScheduleEditor = true }) {
                    Text("Customize")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.infoCyan)
                }
            }

            // Schedule visualizer
            ScheduleVisualizerView(
                hoursOn: recommendation.hoursOn,
                hoursOff: recommendation.hoursOff,
                startTime: customSchedule?.startTime ?? Calendar.current.startOfDay(for: Date()).addingTimeInterval(6 * 3600)
            )

            // Recommendation text
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.infoCyan)
                        .font(.system(size: 14))

                    Text(scheduleExplanation)
                        .font(.system(size: 14))
                        .foregroundColor(.secondaryText)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var ppfdCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sun.max.fill")
                    .foregroundColor(.warningOrange)

                Text("Light Intensity (PPFD)")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primaryText)

                Spacer()

                Button(action: {}) {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(.infoCyan)
                }
            }

            // PPFD range display
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Target Range")
                        .font(.system(size: 12))
                        .foregroundColor(.tertiaryText)

                    Text("\(Int(recommendation.ppfdRange.lowerBound))-\(Int(recommendation.ppfdRange.upperBound))")
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(.electricGreen)

                    Text("μmol/m²/s")
                        .font(.system(size: 12))
                        .foregroundColor(.secondaryText)
                }

                if let ppfd = currentPPFD {
                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Current")
                            .font(.system(size: 12))
                            .foregroundColor(.tertiaryText)

                        Text("\(Int(ppfd))")
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundColor(ppfdStatusColor(ppfd))

                        Text("μmol/m²/s")
                            .font(.system(size: 12))
                            .foregroundColor(.secondaryText)
                    }
                }
            }

            // Status indicator
            if let ppfd = currentPPFD {
                HStack {
                    Circle()
                        .fill(ppfdStatusColor(ppfd))
                        .frame(width: 12, height: 12)

                    Text(ppfdStatusMessage(ppfd))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondaryText)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func dliCard(ppfd: Double) -> some View {
        let photoperiod = Double(customSchedule?.hoursOn ?? recommendation.hoursOn)
        let currentDLI = dliCalculator.calculateDLI(ppfd: ppfd, photoperiodHours: photoperiod)
        let dlisByPhotoperiod = dliCalculator.calculateDLIForCommonPhotoperiods(ppfd: ppfd)

        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.cyanBright)

                Text("Daily Light Integral (DLI)")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primaryText)

                Spacer()

                Button(action: {}) {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(.infoCyan)
                }
            }

            // DLI progress view
            DLIProgressView(
                current: currentDLI,
                target: recommendation.dliTarget,
                photoperiod: photoperiod
            )

            // DLI for different photoperiods (Photone-style)
            VStack(alignment: .leading, spacing: 8) {
                Text("DLI by Photoperiod")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondaryText)

                ForEach(["12/12", "18/6", "20/4", "24/0"], id: \.self) { photoperiod in
                    if let dli = dlisByPhotoperiod[photoperiod] {
                        photoperiodDLIRow(photoperiod: photoperiod, dli: dli)
                    }
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func photoperiodDLIRow(photoperiod: String, dli: Double) -> some View {
        HStack {
            Text(photoperiod)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.secondaryText)
                .frame(width: 60, alignment: .leading)

            ProgressView(value: min(dli / 50, 1.0))
                .tint(dliColor(dli))

            Text(String(format: "%.1f", dli))
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundColor(.primaryText)
                .frame(width: 50, alignment: .trailing)

            Text("mol/m²/d")
                .font(.system(size: 12))
                .foregroundColor(.tertiaryText)
        }
    }

    private var spectrumCard: some View {
        Group {
            if let spectrum = recommendation.spectrum {
                SpectrumChartView(recommendation: spectrum)
            }
        }
    }

    private var educationalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "book.fill")
                    .foregroundColor(.purpleNeon)

                Text("Why These Recommendations?")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primaryText)
            }

            VStack(alignment: .leading, spacing: 12) {
                educationalTip(
                    icon: "leaf.fill",
                    title: "Vegetative: 18/6",
                    description: "18+ hours of light prevents flowering and promotes strong vegetative growth"
                )

                educationalTip(
                    icon: "sparkles",
                    title: "Flowering: 12/12",
                    description: "12 hours of uninterrupted darkness triggers and maintains flowering"
                )

                educationalTip(
                    icon: "sun.max.fill",
                    title: "PPFD Matters",
                    description: "More light = faster growth, but too much causes stress and bleaching"
                )

                educationalTip(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "DLI = Total Daily Light",
                    description: "DLI measures total photons received per day. Higher DLI = more photosynthesis"
                )
            }
        }
        .padding()
        .background(Color.purpleNeon.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func educationalTip(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.electricGreen)
                .font(.system(size: 16))
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primaryText)

                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.secondaryText)
            }
        }
    }

    private var scheduleExplanation: String {
        switch plant.stage {
        case .seedling, .vegetative:
            return "18/6 schedule promotes vigorous vegetative growth"
        case .flowering:
            return "12/12 schedule triggers and maintains flowering"
        case .drying, .curing:
            return "No light needed during drying and curing"
        }
    }

    private func ppfdStatusColor(_ ppfd: Double) -> Color {
        if recommendation.ppfdRange.contains(ppfd) {
            return .successGreen
        } else if ppfd < recommendation.ppfdRange.lowerBound {
            return .warningOrange
        } else {
            return .criticalRed
        }
    }

    private func ppfdStatusMessage(_ ppfd: Double) -> String {
        if recommendation.ppfdRange.contains(ppfd) {
            return "Optimal intensity for \(plant.stage.displayName)"
        } else if ppfd < recommendation.ppfdRange.lowerBound {
            let diff = Int(recommendation.ppfdRange.lowerBound - ppfd)
            return "Increase intensity by ~\(diff) μmol/m²/s"
        } else {
            let diff = Int(ppfd - recommendation.ppfdRange.upperBound)
            return "Reduce intensity by ~\(diff) μmol/m²/s or increase distance"
        }
    }

    private func dliColor(_ dli: Double) -> Color {
        if recommendation.dliTarget.contains(dli) {
            return .successGreen
        } else if dli < recommendation.dliTarget.lowerBound {
            return .warningOrange
        } else {
            return .criticalRed
        }
    }
}
