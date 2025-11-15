import Foundation
import GroBroDomain

@MainActor
public final class PlantCreationViewModel: ObservableObject {
    @Published public var name: String = ""
    @Published public var strainName: String = ""
    @Published public var stage: PlantStage = .seedling
    @Published public var potSizeLiters: Double? = nil
    @Published public var substrateType: SubstrateType? = nil
    @Published public var notes: String = ""
    @Published public var showError: Bool = false
    @Published public var errorMessage: String = ""

    private let plantStore: PlantStore
    public var onPlantCreated: ((Plant) -> Void)?

    public init(plantStore: PlantStore) {
        self.plantStore = plantStore
    }

    public var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public func savePlant() {
        guard isValid else { return }

        let plant = Plant(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            strainName: strainName.isEmpty ? nil : strainName.trimmingCharacters(in: .whitespacesAndNewlines),
            stage: stage,
            potSizeLiters: potSizeLiters,
            substrateType: substrateType,
            notes: notes.isEmpty ? nil : notes
        )

        do {
            let createdPlant = try plantStore.createPlant(plant)
            onPlantCreated?(createdPlant)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
