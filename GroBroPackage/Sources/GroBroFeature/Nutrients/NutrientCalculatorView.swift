import SwiftUI
import GroBroDomain

/// Nutrient dosage calculator with Smart Greenhouse design
@available(iOS 18.0, *)
public struct NutrientCalculatorView: View {

    @State private var selectedBrand: NutrientBrand = .generalHydroponics
    @State private var reservoirAmount: Double = 5.0
    @State private var reservoirUnit: VolumeUnit = .gallons
    @State private var plantStage: PlantStage = .vegetative
    @State private var showProUpgrade = false
    @State private var prefillWeek: WeeklyDosage?

    private let calculator = NutrientCalculator()

    /// Initialize with optional feeding schedule week for pre-filling
    public init(prefillWeek: WeeklyDosage? = nil) {
        self._prefillWeek = State(initialValue: prefillWeek)
    }

    // Sample products (in real implementation, would load from database/JSON)
    private var sampleProducts: [(NutrientProduct, Double)] {
        // If we have a prefill week, use those dosages
        if let week = prefillWeek {
            return week.productDosages.map { dosage in
                let product = NutrientProduct(
                    name: dosage.productName,
                    brand: selectedBrand,
                    category: categoryForProduct(dosage.productName)
                )
                return (product, dosage.mlPerGallon)
            }
        }

        // Otherwise, use default sample products
        switch selectedBrand {
        case .generalHydroponics:
            return [
                (NutrientProduct(name: "FloraMicro", brand: .generalHydroponics, category: .micro), 5.0),
                (NutrientProduct(name: "FloraGro", brand: .generalHydroponics, category: .grow),
                 plantStage == .vegetative ? 10.0 : 5.0),
                (NutrientProduct(name: "FloraBloom", brand: .generalHydroponics, category: .bloom),
                 plantStage == .flowering ? 15.0 : 5.0)
            ]
        case .advancedNutrients:
            return [
                (NutrientProduct(name: "Micro", brand: .advancedNutrients, category: .micro), 4.0),
                (NutrientProduct(name: "Grow", brand: .advancedNutrients, category: .grow), 4.0),
                (NutrientProduct(name: "Bloom", brand: .advancedNutrients, category: .bloom), 4.0)
            ]
        case .foxFarm, .canna, .biobizz:
            // Pro brands - show placeholder
            return []
        }
    }

    private var calculatedDosages: [NutrientDosage] {
        let reservoir = ReservoirVolume(amount: reservoirAmount, unit: reservoirUnit)
        return calculator.calculateDosages(
            for: sampleProducts,
            reservoirVolume: reservoir
        )
    }

    private var estimatedPPM: Double {
        let reservoir = ReservoirVolume(amount: reservoirAmount, unit: reservoirUnit)
        return calculator.estimatePPM(
            from: calculatedDosages,
            reservoirVolume: reservoir
        )
    }

    private var ppmStatus: NutrientStatus {
        calculator.checkPPMStatus(estimatedPPM, for: plantStage)
    }


    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                headerSection

                // Input Controls
                inputSection

                // Calculated Dosages
                if !sampleProducts.isEmpty {
                    dosageResultsSection
                }

                // Pro Upgrade for gated brands
                if selectedBrand.requiresPro {
                    proUpgradeSection
                }

                // Safety Warnings
                safetySection
            }
            .padding()
        }
        .background(Color.deepBackground)
        .navigationTitle("Nutrient Calculator")
        .sheet(isPresented: $showProUpgrade) {
            if #available(iOS 18.0, *) {
                UpgradeToProView()
            }
        }
    }

    // MARK: - View Components

    private var headerSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "leaf.fill")
                        .foregroundStyle(Color.electricGreen)
                        .font(.title2)

                    Text("Nutrient Dosage Calculator")
                        .font(.title3.bold())
                        .foregroundStyle(Color.primaryText)

                    Spacer()

                    // Info tooltip
                    Button(action: {}) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(Color.cyanBright)
                    }
                }

                Text("Calculate precise nutrient dosages for your reservoir size and growth stage")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondaryText)
            }
        }
    }

    private var inputSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                // Brand Selection
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Nutrient Brand")
                            .font(.headline)
                            .foregroundStyle(Color.primaryText)

                        if selectedBrand.requiresPro {
                            Text("PRO")
                                .font(.caption.bold())
                                .foregroundStyle(Color.purpleNeon)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.purpleNeon.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }

                    Picker("Brand", selection: $selectedBrand) {
                        ForEach(NutrientBrand.allCases, id: \.self) { brand in
                            HStack {
                                Text(brand.displayName)
                                if brand.requiresPro {
                                    Text("(Pro)")
                                        .foregroundStyle(Color.purpleNeon)
                                }
                            }
                            .tag(brand)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedBrand) { oldValue, newValue in
                        if newValue.requiresPro {
                            showProUpgrade = true
                        }
                    }
                }

                Divider()
                    .background(Color.secondaryText.opacity(0.3))

                // Reservoir Size
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reservoir Size")
                        .font(.headline)
                        .foregroundStyle(Color.primaryText)

                    HStack {
                        TextField("Amount", value: $reservoirAmount, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)

                        Picker("Unit", selection: $reservoirUnit) {
                            ForEach(VolumeUnit.allCases, id: \.self) { unit in
                                Text(unit.displayName).tag(unit)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }

                Divider()
                    .background(Color.secondaryText.opacity(0.3))

                // Plant Stage
                VStack(alignment: .leading, spacing: 8) {
                    Text("Growth Stage")
                        .font(.headline)
                        .foregroundStyle(Color.primaryText)

                    Picker("Stage", selection: $plantStage) {
                        ForEach(PlantStage.allCases, id: \.self) { stage in
                            Text(stage.displayName).tag(stage)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
    }

    private var dosageResultsSection: some View {
        GlassCard(isHighlighted: true, elevation: .elevated) {
            VStack(alignment: .leading, spacing: 16) {
                // Header with PPM status
                HStack {
                    Text("Calculated Dosages")
                        .font(.title3.bold())
                        .foregroundStyle(Color.primaryText)

                    Spacer()

                    ppmStatusBadge
                }

                // PPM Display
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Estimated PPM")
                            .font(.caption)
                            .foregroundStyle(Color.secondaryText)

                        Text("\(Int(estimatedPPM))")
                            .font(.title.bold())
                            .foregroundStyle(ppmStatusColor)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Target Range")
                            .font(.caption)
                            .foregroundStyle(Color.secondaryText)

                        let range = calculator.recommendedPPMRange(for: plantStage)
                        Text("\(Int(range.lowerBound))-\(Int(range.upperBound))")
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.tertiaryText)
                    }
                }
                .padding()
                .background(Color.electricGreen.opacity(0.1))
                .cornerRadius(12)

                Divider()
                    .background(Color.secondaryText.opacity(0.3))

                // Product Dosages
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(calculatedDosages) { dosage in
                        HStack {
                            Circle()
                                .fill(Color.electricGreen)
                                .frame(width: 8, height: 8)

                            Text(dosage.productName)
                                .font(.body)
                                .foregroundStyle(Color.primaryText)

                            Spacer()

                            Text(dosage.formattedAmount)
                                .font(.body.bold())
                                .foregroundStyle(Color.electricGreen)
                        }
                    }
                }

                // Save to Diary Button
                NeonButton.withIcon(
                    "Log Feeding Event",
                    systemImage: "plus.circle.fill",
                    style: .primary
                ) {
                    // TODO: Navigate to feeding event creation
                }
            }
        }
    }

    private var proUpgradeSection: some View {
        GlassCard {
            VStack(spacing: 12) {
                Image(systemName: "star.fill")
                    .font(.largeTitle)
                    .foregroundStyle(Color.purpleNeon)

                Text("Pro Feature")
                    .font(.headline)
                    .foregroundStyle(Color.primaryText)

                Text("Upgrade to GroBro Pro to access \(selectedBrand.displayName) feeding schedules")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondaryText)
                    .multilineTextAlignment(.center)

                NeonButton.withIcon(
                    "Upgrade to Pro",
                    systemImage: "arrow.up.circle.fill",
                    style: .secondary
                ) {
                    showProUpgrade = true
                }
            }
            .padding()
        }
    }

    private var safetySection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.warningOrange)

                    Text("Safety Guidelines")
                        .font(.headline.bold())
                        .foregroundStyle(Color.warningOrange)
                }

                VStack(alignment: .leading, spacing: 8) {
                    safetyItem("Always add nutrients to water, never water to nutrients")
                    safetyItem("Wear gloves when handling concentrated nutrients")
                    safetyItem("Mix in well-ventilated area")
                    safetyItem("Adjust pH AFTER adding all nutrients")
                    safetyItem("Let solution stabilize 15-30 minutes before final pH check")
                }

                if let warning = ppmStatus.warningMessage {
                    Divider()
                        .background(Color.warningOrange.opacity(0.3))

                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(Color.warningOrange)

                        Text(warning)
                            .font(.subheadline)
                            .foregroundStyle(Color.primaryText)
                    }
                }
            }
        }
    }

    private func safetyItem(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundStyle(Color.warningOrange)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.secondaryText)
        }
    }

    private var ppmStatusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(ppmStatusColor)
                .frame(width: 8, height: 8)

            Text(ppmStatus.displayName)
                .font(.caption.bold())
                .foregroundStyle(ppmStatusColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(ppmStatusColor.opacity(0.2))
        .cornerRadius(8)
    }

    private var ppmStatusColor: Color {
        switch ppmStatus {
        case .low:
            return Color.warningOrange
        case .optimal:
            return Color.electricGreen
        case .high:
            return Color.criticalRed
        }
    }

    // MARK: - Helper Methods

    private func categoryForProduct(_ productName: String) -> ProductCategory {
        let name = productName.lowercased()
        if name.contains("micro") {
            return .micro
        } else if name.contains("grow") {
            return .grow
        } else if name.contains("bloom") {
            return .bloom
        } else if name.contains("cal") || name.contains("mag") {
            return .calMag
        } else {
            return .baseNutrient
        }
    }
}

// MARK: - Preview

#if DEBUG
@available(iOS 18.0, *)
#Preview {
    NavigationStack {
        NutrientCalculatorView()
    }
    .preferredColorScheme(.dark)
}
#endif
