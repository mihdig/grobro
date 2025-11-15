import SwiftUI
import GroBroDomain

/// View for creating a feeding event with full nutrient calculator
@available(iOS 18.0, *)
public struct NutrientEventCreationView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var selectedBrand: NutrientBrand = .generalHydroponics
    @State private var reservoirAmount: Double = 5.0
    @State private var reservoirUnit: VolumeUnit = .gallons
    @State private var plantStage: PlantStage = .vegetative
    @State private var feedPH: Double = 6.0
    @State private var runoffPH: Double?
    @State private var runoffPPM: Double?
    @State private var noteText: String = ""
    @State private var showProUpgrade = false
    @State private var showingSaveError = false

    private let plantId: UUID
    private let eventStore: EventStore
    private let calculator = NutrientCalculator()

    public init(plantId: UUID, eventStore: EventStore) {
        self.plantId = plantId
        self.eventStore = eventStore
    }

    // Sample products (in real implementation, would load from database/JSON)
    private var sampleProducts: [(NutrientProduct, Double)] {
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
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Calculator Section
                    calculatorSection

                    // Additional Measurements
                    measurementsSection

                    // Notes
                    notesSection

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
            .navigationTitle("Log Feeding")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Color.secondaryText)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEvent()
                    }
                    .foregroundStyle(Color.electricGreen)
                    .disabled(selectedBrand.requiresPro)
                }
            }
            .sheet(isPresented: $showProUpgrade) {
                if #available(iOS 18.0, *) {
                    UpgradeToProView()
                }
            }
            .alert("Save Failed", isPresented: $showingSaveError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Failed to save feeding event. Please try again.")
            }
        }
    }

    // MARK: - View Components

    private var calculatorSection: some View {
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

                if !sampleProducts.isEmpty {
                    Divider()
                        .background(Color.secondaryText.opacity(0.3))

                    // Calculated Dosages Display
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Calculated Dosages")
                                .font(.headline)
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
                                    .font(.title2.bold())
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

                        // Product Dosages
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(calculatedDosages) { dosage in
                                HStack {
                                    Circle()
                                        .fill(Color.electricGreen)
                                        .frame(width: 6, height: 6)

                                    Text(dosage.productName)
                                        .font(.subheadline)
                                        .foregroundStyle(Color.primaryText)

                                    Spacer()

                                    Text(dosage.formattedAmount)
                                        .font(.subheadline.bold())
                                        .foregroundStyle(Color.electricGreen)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var measurementsSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Additional Measurements")
                    .font(.headline)
                    .foregroundStyle(Color.primaryText)

                // Feed pH
                VStack(alignment: .leading, spacing: 8) {
                    Text("Feed pH")
                        .font(.subheadline)
                        .foregroundStyle(Color.secondaryText)

                    HStack {
                        TextField("pH", value: $feedPH, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)

                        Text("(Typical: 5.5-6.5)")
                            .font(.caption)
                            .foregroundStyle(Color.tertiaryText)
                    }
                }

                // Runoff pH (optional)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Runoff pH (Optional)")
                        .font(.subheadline)
                        .foregroundStyle(Color.secondaryText)

                    TextField("pH", value: Binding(
                        get: { runoffPH ?? 0 },
                        set: { runoffPH = $0 > 0 ? $0 : nil }
                    ), format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
                }

                // Runoff PPM (optional)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Runoff PPM (Optional)")
                        .font(.subheadline)
                        .foregroundStyle(Color.secondaryText)

                    TextField("PPM", value: Binding(
                        get: { runoffPPM ?? 0 },
                        set: { runoffPPM = $0 > 0 ? $0 : nil }
                    ), format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
                }
            }
        }
    }

    private var notesSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes")
                    .font(.headline)
                    .foregroundStyle(Color.primaryText)

                TextEditor(text: $noteText)
                    .frame(minHeight: 80)
                    .scrollContentBackground(.hidden)
                    .background(Color.deepBackground.opacity(0.3))
                    .cornerRadius(8)
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

                VStack(alignment: .leading, spacing: 6) {
                    safetyItem("Always add nutrients to water, never water to nutrients")
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
                .frame(width: 6, height: 6)

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

    // MARK: - Save Logic

    private func saveEvent() {
        // Create nutrient event data
        let productDosages = calculatedDosages.map { dosage in
            ProductDosage(
                productName: dosage.productName,
                amount: dosage.amount,
                unit: dosage.unit.displayName
            )
        }

        let nutrientData = NutrientEventData(
            brand: selectedBrand.displayName,
            productLine: selectedBrand == .generalHydroponics ? "Flora Series" : nil,
            dosages: productDosages,
            feedPPM: estimatedPPM,
            feedEC: calculator.ppmToEC(estimatedPPM, scale: .scale500),
            runoffPPM: runoffPPM,
            feedPH: feedPH,
            runoffPH: runoffPH,
            reservoirVolumeLiters: ReservoirVolume(amount: reservoirAmount, unit: reservoirUnit).liters
        )

        // Create event
        let event = Event(
            plantId: plantId,
            type: .feeding,
            volumeLiters: ReservoirVolume(amount: reservoirAmount, unit: reservoirUnit).liters,
            noteText: noteText.isEmpty ? nil : noteText,
            nutrientData: nutrientData
        )

        do {
            _ = try eventStore.createEvent(event)
            dismiss()
        } catch {
            print("Failed to save feeding event: \(error)")
            showingSaveError = true
        }
    }
}

// MARK: - Preview

#if DEBUG
@available(iOS 18.0, *)
#Preview {
    NutrientEventCreationView(
        plantId: UUID(),
        eventStore: EventStore()
    )
    .preferredColorScheme(.dark)
}
#endif
