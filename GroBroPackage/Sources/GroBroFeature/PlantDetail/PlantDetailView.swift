import SwiftUI
import GroBroDomain

// MARK: - PlantDetailView

@available(iOS 17.0, *)
public struct PlantDetailView: View {
    @StateObject private var viewModel: PlantDetailViewModel
    @State private var selectedSection: DetailSection
    @State private var showingDiagnostics = false

    public enum DetailSection: String, CaseIterable, Identifiable {
        case overview = "Overview"
        case care = "Care"
        case environment = "Environment"
        case light = "Light"
        case diary = "Diary"

        public var id: String { rawValue }

        var icon: String {
            switch self {
            case .overview: return "info.circle"
            case .care: return "drop.fill"
            case .environment: return "thermometer.medium"
            case .light: return "sun.max"
            case .diary: return "calendar"
            }
        }
    }

    public init(viewModel: PlantDetailViewModel, initialTab: Int = 0) {
        _viewModel = StateObject(wrappedValue: viewModel)
        // Map old tab indices to new sections
        let section: DetailSection
        switch initialTab {
        case 1, 2: section = .care  // Watering or Diagnostics -> Care
        case 3: section = .environment
        case 4: section = .light
        case 5, 6: section = .diary  // Debug or Diary -> Diary
        default: section = .overview
        }
        _selectedSection = State(initialValue: section)
    }

    public var body: some View {
        ZStack {
            Color.deepBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Section Picker
                sectionPicker
                    .padding(.horizontal)
                    .padding(.top, 8)

                // Content
                ScrollView {
                    sectionContent
                        .padding(.top, 16)
                }
            }
        }
        .navigationTitle(viewModel.plant.name)
        .inlineNavigationTitle()
        .sheet(isPresented: $showingDiagnostics) {
            DiagnosticsView(viewModel: viewModel.makeDiagnosticsViewModel())
        }
        #if DEBUG
        .toolbar {
            ToolbarItem(placement: .automatic) {
                NavigationLink {
                    DebugConsoleView(viewModel: viewModel.makeDebugConsoleViewModel())
                } label: {
                    Image(systemName: "ladybug")
                        .foregroundColor(.tertiaryText)
                }
            }
        }
        #endif
    }

    // MARK: - Section Picker

    private var sectionPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DetailSection.allCases) { section in
                    sectionButton(for: section)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private func sectionButton(for section: DetailSection) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedSection = section
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: section.icon)
                    .font(.system(size: 14, weight: .medium))
                Text(section.rawValue)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(selectedSection == section ? .deepBackground : .primaryText)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(selectedSection == section ? Color.electricGreen : Color.surfaceLight)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(section.rawValue) section")
        .accessibilityAddTraits(selectedSection == section ? .isSelected : [])
    }

    // MARK: - Section Content

    @ViewBuilder
    private var sectionContent: some View {
        switch selectedSection {
        case .overview:
            overviewSection
        case .care:
            careSection
        case .environment:
            EnvironmentTabView(plantId: viewModel.plant.id)
        case .light:
            LightMeterView(plant: viewModel.plant)
        case .diary:
            DiaryView(viewModel: viewModel.makeDiaryViewModel())
        }
    }

    // MARK: - Overview Section

    private var overviewSection: some View {
        VStack(spacing: 20) {
            // Plant Photo
            plantPhotoView

            // Plant Info Card
            GlassCard(elevation: .standard) {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.plant.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primaryText)

                            if let strainName = viewModel.plant.strainName {
                                Text(strainName)
                                    .font(.subheadline)
                                    .foregroundColor(.secondaryText)
                            }
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Day \(viewModel.plant.ageInDays)")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.electricGreen)

                            Text("Age")
                                .font(.caption)
                                .foregroundColor(.tertiaryText)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(viewModel.plant.name), Day \(viewModel.plant.ageInDays)")

                    Divider()
                        .background(Color.surfaceLight)

                    // Growing Details
                    VStack(spacing: 12) {
                        DetailRow(
                            label: "Stage",
                            value: viewModel.plant.stage.displayName,
                            valueColor: .electricGreen
                        )

                        if let potSize = viewModel.plant.potSizeLiters {
                            DetailRow(
                                label: "Pot Size",
                                value: "\(String(format: "%.1f", potSize))L"
                            )
                        }

                        if let substrate = viewModel.plant.substrateType {
                            DetailRow(
                                label: "Substrate",
                                value: substrate.displayName
                            )
                        }

                        if let lightHours = viewModel.plant.lightHoursPerDay {
                            DetailRow(
                                label: "Light Hours",
                                value: "\(String(format: "%.1f", lightHours))h/day"
                            )
                        }
                    }

                    if let notes = viewModel.plant.notes, !notes.isEmpty {
                        Divider()
                            .background(Color.surfaceLight)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.headline)
                                .foregroundColor(.primaryText)

                            Text(notes)
                                .font(.body)
                                .foregroundColor(.secondaryText)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 20)
    }

    private var plantPhotoView: some View {
        GlassCard(elevation: .subtle, cornerRadius: 20, padding: 0) {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color.electricGreen.opacity(0.2), Color.sageGreen.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 220)
                .overlay {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 72))
                        .foregroundColor(.electricGreen)
                        .shadow(color: .electricGreen.opacity(0.5), radius: 20)
                }
        }
        .padding(.horizontal)
        .accessibilityLabel("Plant photo placeholder for \(viewModel.plant.name)")
    }

    // MARK: - Care Section (Watering + Diagnostics)

    private var careSection: some View {
        VStack(spacing: 20) {
            // Watering Status Card
            wateringStatusCard

            // Watering Feedback Card
            if viewModel.wateringStatus != nil {
                wateringFeedbackCard
            }

            // Diagnostics Card
            diagnosticsCard
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
    }

    private var wateringStatusCard: some View {
        GlassCard(elevation: .standard) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "drop.fill")
                        .font(.title2)
                        .foregroundColor(.cyanBright)

                    Text("Watering Schedule")
                        .font(.headline)
                        .foregroundColor(.primaryText)
                }

                if let status = viewModel.wateringStatus {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "drop.fill")
                                .foregroundColor(status.isOverdue ? .criticalRed : .cyanBright)
                                .font(.title)

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text(status.statusMessage)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(status.isOverdue ? .criticalRed : .cyanBright)

                                Text("Next watering")
                                    .font(.caption)
                                    .foregroundColor(.tertiaryText)
                            }
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Watering status: \(status.statusMessage)")

                        Divider()
                            .background(Color.surfaceLight)

                        HStack {
                            Text("Next watering date:")
                                .font(.subheadline)
                                .foregroundColor(.secondaryText)

                            Spacer()

                            Text(status.nextWateringDate, style: .date)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primaryText)
                        }
                    }
                } else {
                    Text("No watering events logged yet. Log your first watering in the Diary section.")
                        .font(.body)
                        .foregroundColor(.secondaryText)
                }
            }
        }
    }

    private var wateringFeedbackCard: some View {
        GlassCard(elevation: .subtle) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Last Watering Feedback")
                    .font(.headline)
                    .foregroundColor(.primaryText)

                Text("How was the timing of your last watering?")
                    .font(.subheadline)
                    .foregroundColor(.secondaryText)

                VStack(spacing: 12) {
                    FeedbackButton(
                        title: "Too Early",
                        subtitle: "Soil was still wet",
                        icon: "arrow.up.circle.fill",
                        color: .warningOrange
                    ) {
                        viewModel.applyWateringFeedback(.tooEarly)
                    }

                    FeedbackButton(
                        title: "Just Right",
                        subtitle: "Perfect timing",
                        icon: "checkmark.circle.fill",
                        color: .successGreen
                    ) {
                        viewModel.applyWateringFeedback(.justRight)
                    }

                    FeedbackButton(
                        title: "Too Late",
                        subtitle: "Soil was very dry",
                        icon: "arrow.down.circle.fill",
                        color: .criticalRed
                    ) {
                        viewModel.applyWateringFeedback(.tooLate)
                    }
                }
            }
        }
    }

    private var diagnosticsCard: some View {
        GlassCard(isHighlighted: false, elevation: .standard) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "stethoscope")
                        .font(.title2)
                        .foregroundColor(.purpleNeon)

                    Text("Plant Health Check")
                        .font(.headline)
                        .foregroundColor(.primaryText)
                }

                Text("Take a photo of your plant to check for potential issues like hydration problems, light stress, leaf conditions, or pests.")
                    .font(.body)
                    .foregroundColor(.secondaryText)

                NeonButton.withIcon("Check Plant Health", systemImage: "camera.fill", style: .primary) {
                    showingDiagnostics = true
                }
                .accessibilityHint("Opens camera to diagnose plant health issues")

                // Recent Checks placeholder
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                        .background(Color.surfaceLight)

                    Text("Recent Checks")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primaryText)

                    Text("No diagnostics history yet.")
                        .font(.caption)
                        .foregroundColor(.tertiaryText)
                }
                .padding(.top, 8)
            }
        }
    }
}

// MARK: - FeedbackButton

@available(iOS 17.0, *)
struct FeedbackButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.primaryText)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.tertiaryText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.surfaceLight)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title): \(subtitle)")
        .accessibilityHint("Double tap to provide feedback")
    }
}

// MARK: - DetailRow

@available(iOS 17.0, *)
struct DetailRow: View {
    let label: String
    let value: String
    var valueColor: Color = .primaryText

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondaryText)

            Spacer()

            Text(value)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(valueColor)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Previews

#if DEBUG
@available(iOS 17.0, *)
#Preview("PlantDetailView - Overview") {
    NavigationStack {
        PlantDetailView(
            viewModel: PlantDetailViewModel.preview()
        )
    }
    .preferredColorScheme(.dark)
}

@available(iOS 17.0, *)
#Preview("PlantDetailView - Care") {
    NavigationStack {
        PlantDetailView(
            viewModel: PlantDetailViewModel.preview(),
            initialTab: 1
        )
    }
    .preferredColorScheme(.dark)
}
#endif
