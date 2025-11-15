import SwiftUI
import CoreData

/// Root Garden view. In early stories this acts as the main app shell.
struct GardenView: View {
    @Environment(\.managedObjectContext) private var context
    @StateObject private var viewModel = GardenViewModel()

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("GroBro Garden")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            viewModel.isPresentingCreatePlant = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
        }
        .sheet(isPresented: $viewModel.isPresentingCreatePlant) {
            PlantCreationView { request in
                viewModel.handleCreatePlant(request: request, context: context)
            }
        }
        .onAppear {
            viewModel.loadPlants(context: context)
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.plants.isEmpty {
            VStack(spacing: 12) {
                Text("No plants yet")
                    .font(.headline)
                Text("Tap + to create your first plant and start your grow diary.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            .padding()
        } else {
            List(viewModel.plants) { plant in
                NavigationLink {
                    PlantDetailView(plantID: plant.id)
                } label: {
                    PlantCardView(plant: plant)
                }
            }
        }
    }
}

// MARK: - View Model

final class GardenViewModel: ObservableObject {
    @Published var plants: [Plant] = []
    @Published var isPresentingCreatePlant = false

    func loadPlants(context: NSManagedObjectContext) {
        let store = PlantStore(context: context)
        do {
            plants = try store.fetchAllActivePlants()
        } catch {
            NSLog("Failed to load plants: \(error.localizedDescription)")
            plants = []
        }
    }

    func handleCreatePlant(request: PlantCreationRequest, context: NSManagedObjectContext) {
        let store = PlantStore(context: context)
        do {
            try store.createPlant(
                name: request.name,
                strainName: request.strainName,
                stage: request.stage,
                potSizeLiters: request.potSizeLiters,
                substrateType: request.substrateType
            )
            loadPlants(context: context)
            isPresentingCreatePlant = false
        } catch {
            NSLog("Failed to create plant: \(error.localizedDescription)")
        }
    }
}

// MARK: - Supporting Views

private struct PlantCardView: View {
    let plant: Plant

    var body: some View {
        HStack {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 56, height: 56)
                Image(systemName: "leaf")
                    .foregroundColor(.green)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(plant.name)
                    .font(.headline)
                Text(plant.stage.displayName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("\(plant.ageInDays) days")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Plant Creation

struct PlantCreationRequest {
    var name: String = ""
    var strainName: String?
    var stage: PlantStage = .seedling
    var potSizeLiters: Double?
    var substrateType: SubstrateType? = .soil
}

private struct PlantCreationView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var request = PlantCreationRequest()

    let onSave: (PlantCreationRequest) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Basics") {
                    TextField("Name", text: $request.name)
                    TextField("Strain (optional)", text: Binding($request.strainName, replacingNilWith: ""))
                }

                Section("Stage") {
                    Picker("Stage", selection: $request.stage) {
                        ForEach(PlantStage.allCases, id: \.self) { stage in
                            Text(stage.displayName).tag(stage)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Container & Substrate") {
                    TextField("Pot size (L)", value: $request.potSizeLiters, format: .number)
                        .keyboardType(.decimalPad)
                    Picker("Substrate", selection: Binding($request.substrateType, defaultValue: .soil)) {
                        ForEach(SubstrateType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(Optional(type))
                        }
                    }
                }
            }
            .navigationTitle("Add Plant")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard !request.name.trimmingCharacters(in: .whitespaces).isEmpty else {
                            return
                        }
                        onSave(request)
                    }
                }
            }
        }
    }
}

// MARK: - Helpers

private extension Binding where Value == String? {
    init(_ source: Binding<String?>, replacingNilWith replacement: String) {
        self.init(
            get: { source.wrappedValue ?? replacement },
            set: { newValue in
                source.wrappedValue = newValue.isEmpty ? nil : newValue
            }
        )
    }
}

private extension Binding where Value == SubstrateType? {
    init(_ source: Binding<SubstrateType?>, defaultValue: SubstrateType) {
        self.init(
            get: { source.wrappedValue ?? defaultValue },
            set: { newValue in
                source.wrappedValue = newValue
            }
        )
    }
}

