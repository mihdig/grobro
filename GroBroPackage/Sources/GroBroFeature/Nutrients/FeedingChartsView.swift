import SwiftUI
import GroBroDomain

/// Feeding chart browser with Smart Greenhouse design
@available(iOS 18.0, *)
public struct FeedingChartsView: View {

    @State private var scheduleService = FeedingScheduleService()
    @State private var selectedSchedule: FeedingSchedule?
    @State private var selectedWeek: WeeklyDosage?
    @State private var showCalculator = false
    @State private var useMetric = false

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                headerSection

                // Schedule Selection
                if !scheduleService.schedules.isEmpty {
                    scheduleSelectionSection
                }

                // Weekly Schedule Grid
                if let schedule = selectedSchedule {
                    weeklyScheduleSection(schedule: schedule)
                }

                // Educational Content
                if selectedSchedule != nil {
                    educationalSection
                }
            }
            .padding()
        }
        .background(Color.deepBackground)
        .navigationTitle("Feeding Charts")
        .task {
            await scheduleService.loadSchedules()
            // Auto-select first schedule
            if selectedSchedule == nil {
                selectedSchedule = scheduleService.schedules.first
            }
        }
        .sheet(isPresented: $showCalculator) {
            if let week = selectedWeek {
                calculatorSheet(for: week)
            }
        }
    }

    // MARK: - View Components

    private var headerSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "chart.bar.doc.horizontal.fill")
                        .foregroundStyle(Color.electricGreen)
                        .font(.title2)

                    Text("Professional Feeding Schedules")
                        .font(.title3.bold())
                        .foregroundStyle(Color.primaryText)

                    Spacer()

                    // Unit toggle
                    Button(action: { useMetric.toggle() }) {
                        Text(useMetric ? "mL/L" : "mL/Gal")
                            .font(.caption.bold())
                            .foregroundStyle(Color.cyanBright)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.cyanBright.opacity(0.2))
                            .cornerRadius(6)
                    }
                }

                Text("Science-backed feeding schedules from leading nutrient brands. Optimized for each growth stage.")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondaryText)

                if scheduleService.isLoading {
                    ProgressView()
                        .tint(Color.electricGreen)
                }
            }
        }
    }

    private var scheduleSelectionSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Select Nutrient Line")
                    .font(.headline)
                    .foregroundStyle(Color.primaryText)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(scheduleService.schedules) { schedule in
                            scheduleButton(schedule)
                        }
                    }
                }
            }
        }
    }

    private func scheduleButton(_ schedule: FeedingSchedule) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3)) {
                selectedSchedule = schedule
            }
        }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(schedule.brand.displayName)
                        .font(.caption.bold())
                        .foregroundStyle(
                            selectedSchedule?.id == schedule.id
                                ? Color.electricGreen
                                : Color.secondaryText
                        )

                    if schedule.productLine.requiresPro {
                        Text("PRO")
                            .font(.caption2.bold())
                            .foregroundStyle(Color.purpleNeon)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.purpleNeon.opacity(0.2))
                            .cornerRadius(3)
                    }
                }

                Text(schedule.productLine.displayName)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.primaryText)

                Text("\(schedule.weeks.count) weeks")
                    .font(.caption)
                    .foregroundStyle(Color.tertiaryText)
            }
            .padding()
            .frame(width: 160)
            .background(
                selectedSchedule?.id == schedule.id
                    ? Color.electricGreen.opacity(0.1)
                    : Color.deepBackground.opacity(0.3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        selectedSchedule?.id == schedule.id
                            ? Color.electricGreen
                            : Color.secondaryText.opacity(0.3),
                        lineWidth: selectedSchedule?.id == schedule.id ? 2 : 1
                    )
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    private func weeklyScheduleSection(schedule: FeedingSchedule) -> some View {
        GlassCard(elevation: .elevated) {
            VStack(alignment: .leading, spacing: 16) {
                // Schedule Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(schedule.name)
                            .font(.title3.bold())
                            .foregroundStyle(Color.primaryText)

                        Text(schedule.description)
                            .font(.subheadline)
                            .foregroundStyle(Color.secondaryText)
                    }

                    Spacer()
                }

                Divider()
                    .background(Color.secondaryText.opacity(0.3))

                // Products Legend
                productLegend(schedule: schedule)

                Divider()
                    .background(Color.secondaryText.opacity(0.3))

                // Weekly Grid
                VStack(spacing: 8) {
                    ForEach(schedule.weeks) { week in
                        weekRow(week: week, products: schedule.products)
                    }
                }
            }
        }
    }

    private func productLegend(schedule: FeedingSchedule) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Products")
                .font(.headline)
                .foregroundStyle(Color.primaryText)

            HStack(spacing: 12) {
                ForEach(schedule.products, id: \.self) { product in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(productColor(for: product))
                            .frame(width: 8, height: 8)

                        Text(product)
                            .font(.caption)
                            .foregroundStyle(Color.secondaryText)
                    }
                }
            }
        }
    }

    private func weekRow(week: WeeklyDosage, products: [String]) -> some View {
        Button(action: {
            selectedWeek = week
            showCalculator = true
        }) {
            VStack(alignment: .leading, spacing: 8) {
                // Week Header
                HStack {
                    Image(systemName: week.stage.icon)
                        .foregroundStyle(stageColor(week.stage))
                        .font(.caption)

                    Text("Week \(week.weekNumber)")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.primaryText)

                    Text("•")
                        .foregroundStyle(Color.tertiaryText)

                    Text(week.stageName)
                        .font(.subheadline)
                        .foregroundStyle(Color.secondaryText)

                    Spacer()

                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundStyle(Color.electricGreen)
                        .font(.caption)
                }

                // Dosages
                HStack(spacing: 8) {
                    ForEach(week.productDosages, id: \.productName) { dosage in
                        dosageChip(dosage: dosage)
                    }
                }

                // Notes
                if let notes = week.notes {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(Color.tertiaryText)
                        .padding(.top, 4)
                }
            }
            .padding()
            .background(Color.deepBackground.opacity(0.5))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.secondaryText.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func dosageChip(dosage: ScheduleProductDosage) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(productColor(for: dosage.productName))
                .frame(width: 6, height: 6)

            Text("\(formatDosage(dosage)) \(useMetric ? "mL/L" : "mL/gal")")
                .font(.caption.bold())
                .foregroundStyle(Color.electricGreen)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.electricGreen.opacity(0.1))
        .cornerRadius(8)
    }

    private var educationalSection: some View {
        Group {
            if let schedule = selectedSchedule {
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(Color.cyanBright)

                            Text("Feeding Strategy")
                                .font(.headline.bold())
                                .foregroundStyle(Color.primaryText)
                        }

                        Text("This schedule is optimized for \(schedule.productLine.displayName). Follow these guidelines for best results:")
                            .font(.subheadline)
                            .foregroundStyle(Color.secondaryText)

                        VStack(alignment: .leading, spacing: 8) {
                            educationalTip("Start with lower doses for young or sensitive plants")
                            educationalTip("Increase gradually - watch for nutrient burn")
                            educationalTip("Monitor pH and EC/PPM levels regularly")
                            educationalTip("Adjust based on plant response and environment")
                        }
                    }
                }

                // Safety Warnings
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(Color.warningOrange)

                            Text("Safety Guidelines")
                                .font(.headline.bold())
                                .foregroundStyle(Color.warningOrange)
                        }

                        ForEach(schedule.safetyNotes, id: \.self) { note in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .foregroundStyle(Color.warningOrange)
                                Text(note)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.secondaryText)
                            }
                        }
                    }
                }
            }
        }
    }

    private func educationalTip(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.electricGreen)
                .font(.caption)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.secondaryText)
        }
    }

    @ViewBuilder
    private func calculatorSheet(for week: WeeklyDosage) -> some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Week \(week.weekNumber) - \(week.stageName)")
                                .font(.title2.bold())
                                .foregroundStyle(Color.primaryText)

                            Text("Apply these dosages to your nutrient calculator")
                                .font(.subheadline)
                                .foregroundStyle(Color.secondaryText)

                            Divider()
                                .background(Color.secondaryText.opacity(0.3))

                            ForEach(week.productDosages, id: \.productName) { dosage in
                                HStack {
                                    Circle()
                                        .fill(productColor(for: dosage.productName))
                                        .frame(width: 8, height: 8)

                                    Text(dosage.productName)
                                        .font(.body)
                                        .foregroundStyle(Color.primaryText)

                                    Spacer()

                                    Text("\(formatDosage(dosage)) \(useMetric ? "mL/L" : "mL/gal")")
                                        .font(.body.bold())
                                        .foregroundStyle(Color.electricGreen)
                                }
                            }

                            if let notes = week.notes {
                                Divider()
                                    .background(Color.secondaryText.opacity(0.3))

                                Text(notes)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.tertiaryText)
                            }
                        }
                    }
                    .padding()

                    NavigationLink(destination: NutrientCalculatorView(prefillWeek: week)) {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                            Text("Use in Calculator")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.electricGreen, Color.neonGreen],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundStyle(.black)
                        .font(.headline)
                        .cornerRadius(12)
                        .shadow(color: Color.electricGreen.opacity(0.5), radius: 10)
                    }
                    .padding(.horizontal)
                }
            }
            .background(Color.deepBackground)
            .navigationTitle("Apply to Calculator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        showCalculator = false
                    }
                    .foregroundStyle(Color.secondaryText)
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func productColor(for productName: String) -> Color {
        let name = productName.lowercased()
        if name.contains("micro") {
            return Color.cyanBright
        } else if name.contains("grow") {
            return Color.electricGreen
        } else if name.contains("bloom") {
            return Color.purpleNeon
        } else {
            return Color.neonGreen
        }
    }

    private func stageColor(_ stage: GrowthStage) -> Color {
        switch stage {
        case .seedling:
            return Color.neonGreen
        case .earlyVegetative, .lateVegetative:
            return Color.electricGreen
        case .transition:
            return Color.cyanBright
        case .earlyFlowering, .midFlowering, .lateFlowering:
            return Color.purpleNeon
        case .flush:
            return Color.cyanBright
        }
    }

    private func formatDosage(_ dosage: ScheduleProductDosage) -> String {
        let value = useMetric ? dosage.mlPerLiter : dosage.mlPerGallon
        return String(format: "%.1f", value)
    }
}

// MARK: - Preview

#if DEBUG
@available(iOS 18.0, *)
#Preview {
    NavigationStack {
        FeedingChartsView()
    }
    .preferredColorScheme(.dark)
}
#endif
