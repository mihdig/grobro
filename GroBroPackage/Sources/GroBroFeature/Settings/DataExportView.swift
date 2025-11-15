import SwiftUI
import GroBroDomain

@available(iOS 17.0, macOS 14.0, *)
public struct DataExportView: View {

    @Environment(ProEntitlementManager.self) private var proManager
    @StateObject private var viewModel: DataExportViewModel
    @State private var showUpgradeSheet = false

    public init(
        plantStore: PlantStore = PlantStore(),
        eventStore: EventStore = EventStore(),
        exportService: DataExportService = DataExportService()
    ) {
        _viewModel = StateObject(
            wrappedValue: DataExportViewModel(
                plantStore: plantStore,
                eventStore: eventStore,
                exportService: exportService
            )
        )
    }

    public var body: some View {
        List {
            if !proManager.hasAccess(to: .dataExport) {
                lockedStateSection
            } else {
                scopeSection
                if viewModel.scope == .singlePlant {
                    plantSelectionSection
                }
                if viewModel.scope == .dateRange {
                    dateRangeSection
                }

                formatSection
                optionsSection
                actionSection

                if let exportURL = viewModel.lastExportURL {
                    shareSection(exportURL: exportURL)
                }
            }
        }
        .navigationTitle("Data Export")
        .alert("Error", isPresented: Binding(
            get: { viewModel.showError },
            set: { _ in viewModel.errorMessage = nil }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            if let message = viewModel.errorMessage {
                Text(message)
            }
        }
        .onAppear {
            viewModel.loadPlants()
        }
        .sheet(isPresented: $showUpgradeSheet) {
            if #available(iOS 18.0, macOS 15.0, *) {
                UpgradeToProView()
            } else {
                UpgradePromptView()
            }
        }
    }

    // MARK: - Sections

    private var lockedStateSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Data export is a Pro feature.")
                    .font(.headline)

                Text("Upgrade to GroBro Pro to export your plants and diary history as CSV or JSON for backup and external analysis.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button {
                    showUpgradeSheet = true
                } label: {
                    HStack {
                        Spacer()
                        Text("Upgrade to Pro")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 4)
            }
            .padding(.vertical, 8)
        }
    }

    private var scopeSection: some View {
        Section("Scope") {
            Picker("Scope", selection: $viewModel.scope) {
                ForEach(DataExportViewModel.ExportScope.allCases) { scope in
                    Text(scope.displayName).tag(scope)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var plantSelectionSection: some View {
        Section("Plant") {
            if viewModel.plants.isEmpty {
                Text("No plants available to export. Create a plant first.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Picker("Plant", selection: $viewModel.selectedPlantId) {
                    ForEach(viewModel.plants) { plant in
                        Text(plant.name).tag(Optional(plant.id))
                    }
                }
            }
        }
    }

    private var dateRangeSection: some View {
        Section("Date Range") {
            DatePicker(
                "From",
                selection: $viewModel.startDate,
                displayedComponents: [.date]
            )

            DatePicker(
                "To",
                selection: $viewModel.endDate,
                in: viewModel.startDate...,
                displayedComponents: [.date]
            )
        }
    }

    private var formatSection: some View {
        Section("Format") {
            Picker("Format", selection: $viewModel.format) {
                ForEach(DataExportViewModel.ExportFormat.allCases) { format in
                    Text(format.displayName).tag(format)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var optionsSection: some View {
        Section("Options") {
            Toggle("Anonymize plant names", isOn: $viewModel.anonymizePlantNames)
            Text("When enabled, plant names are exported as \"Plant 1\", \"Plant 2\", etc. Notes are exported as entered.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var actionSection: some View {
        Section {
            Button {
                viewModel.startExport()
            } label: {
                HStack {
                    if viewModel.isExporting {
                        ProgressView(value: viewModel.progress)
                            .frame(width: 80)
                    }
                    Text(viewModel.isExporting ? "Exporting..." : "Generate Export")
                        .fontWeight(.semibold)
                    Spacer()
                }
            }
            .disabled(viewModel.isExporting)

            if viewModel.isExporting {
                Text("Export runs on device and may take a few seconds for large gardens.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func shareSection(exportURL: URL) -> some View {
        Section("Share") {
            ShareLink(item: exportURL) {
                Label("Share Export", systemImage: "square.and.arrow.up")
            }

            Text(exportURL.lastPathComponent)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - View Model

@available(iOS 17.0, macOS 14.0, *)
@MainActor
final class DataExportViewModel: ObservableObject {

    enum ExportScope: String, CaseIterable, Identifiable {
        case singlePlant
        case allPlants
        case dateRange

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .singlePlant:
                return "Single Plant"
            case .allPlants:
                return "All Plants"
            case .dateRange:
                return "Date Range"
            }
        }
    }

    enum ExportFormat: String, CaseIterable, Identifiable {
        case csv
        case json

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .csv:
                return "CSV"
            case .json:
                return "JSON"
            }
        }

        var domainFormat: DataExportService.Format {
            switch self {
            case .csv:
                return .csv
            case .json:
                return .json
            }
        }
    }

    // MARK: - Published State

    @Published var plants: [Plant] = []
    @Published var scope: ExportScope = .allPlants
    @Published var selectedPlantId: UUID?
    @Published var startDate: Date
    @Published var endDate: Date
    @Published var format: ExportFormat = .csv
    @Published var anonymizePlantNames: Bool = false

    @Published var isExporting: Bool = false
    @Published var progress: Double = 0
    @Published var lastExportURL: URL?
    @Published var errorMessage: String?

    var showError: Bool {
        errorMessage != nil
    }

    // MARK: - Dependencies

    private let plantStore: PlantStore
    private let eventStore: EventStore
    private let exportService: DataExportService

    // MARK: - Initialization

    init(
        plantStore: PlantStore,
        eventStore: EventStore,
        exportService: DataExportService
    ) {
        self.plantStore = plantStore
        self.eventStore = eventStore
        self.exportService = exportService

        let now = Date()
        self.startDate = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now
        self.endDate = now
    }

    // MARK: - Public API

    func loadPlants() {
        do {
            let fetchedPlants = try plantStore.fetchPlants()
            plants = fetchedPlants

            if selectedPlantId == nil {
                selectedPlantId = fetchedPlants.first?.id
            }
        } catch {
            errorMessage = "Failed to load plants: \(error.localizedDescription)"
        }
    }

    func startExport() {
        guard !isExporting else { return }

        Task {
            await runExport()
        }
    }

    // MARK: - Internal

    private func runExport() async {
        guard !plants.isEmpty else {
            errorMessage = "There are no plants to export yet."
            return
        }

        let selectedPlants: [Plant]
        switch scope {
        case .allPlants:
            selectedPlants = plants
        case .singlePlant:
            guard let id = selectedPlantId,
                  let plant = plants.first(where: { $0.id == id }) else {
                errorMessage = "Please select a plant to export."
                return
            }
            selectedPlants = [plant]
        case .dateRange:
            selectedPlants = plants
        }

        if scope == .dateRange, startDate > endDate {
            errorMessage = "Start date must be before end date."
            return
        }

        isExporting = true
        progress = 0
        lastExportURL = nil
        errorMessage = nil

        let events: [Event]
        do {
            events = try fetchEvents(for: selectedPlants)
        } catch {
            isExporting = false
            errorMessage = "Failed to load events: \(error.localizedDescription)"
            return
        }

        let dateRange: ClosedRange<Date>? = scope == .dateRange ? startDate...endDate : nil

        let options = DataExportService.Options(
            format: format.domainFormat,
            anonymizePlantNames: anonymizePlantNames,
            dateRange: dateRange
        )

        do {
            let url = try await exportService.export(
                plants: selectedPlants,
                events: events,
                options: options
            ) { [weak self] progress in
                guard let self else { return }
                Task { @MainActor in
                    self.progress = progress
                }
            }

            await MainActor.run {
                self.lastExportURL = url
                self.isExporting = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Export failed: \(error.localizedDescription)"
                self.isExporting = false
            }
        }
    }

    private func fetchEvents(for plants: [Plant]) throws -> [Event] {
        var allEvents: [Event] = []
        for plant in plants {
            let events = try eventStore.fetchEvents(for: plant.id)
            allEvents.append(contentsOf: events)
        }
        // Sort by timestamp ascending for deterministic ordering
        return allEvents.sorted { $0.timestamp < $1.timestamp }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DataExportView()
            .environment(ProEntitlementManager())
    }
}

