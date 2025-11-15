import SwiftUI
import CoreData

/// Basic plant detail view for v1 stories.
struct PlantDetailView: View {
    let plantID: UUID

    @Environment(\.managedObjectContext) private var context
    @StateObject private var viewModel = PlantDetailViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            Form {
                Section("Basics") {
                    Text("Stage: \(viewModel.stageText)")
                    Text("Age: \(viewModel.ageText)")
                    if let pot = viewModel.potSizeText {
                        Text("Pot: \(pot)")
                    }
                    if let substrate = viewModel.substrateText {
                        Text("Substrate: \(substrate)")
                    }
                }
            }
        }
        .navigationTitle(viewModel.name.isEmpty ? "Plant" : viewModel.name)
        .onAppear {
            viewModel.load(plantID: plantID, context: context)
        }
    }

    @ViewBuilder
    private var header: some View {
        HStack {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 72, height: 72)
                Image(systemName: "leaf.fill")
                    .foregroundColor(.green)
                    .font(.title)
            }
            VStack(alignment: .leading) {
                Text(viewModel.name.isEmpty ? "Plant" : viewModel.name)
                    .font(.title2)
                    .bold()
                Text(viewModel.stageText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top)
    }
}

// MARK: - View Model

final class PlantDetailViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var stageText: String = ""
    @Published var ageText: String = ""
    @Published var potSizeText: String?
    @Published var substrateText: String?

    func load(plantID: UUID, context: NSManagedObjectContext) {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Plant")
        request.predicate = NSPredicate(format: "id == %@", plantID as CVarArg)
        request.fetchLimit = 1

        do {
            guard let object = try context.fetch(request).first else {
                return
            }

            guard let plant = PlantStore.mapManagedObjectToPlant(object) else {
                return
            }

            name = plant.name
            stageText = plant.stage.displayName
            ageText = "\(plant.ageInDays) days"
            if let pot = plant.potSizeLiters {
                potSizeText = "\(pot) L"
            }
            substrateText = plant.substrateType?.displayName
        } catch {
            NSLog("Failed to load plant detail: \(error.localizedDescription)")
        }
    }
}

