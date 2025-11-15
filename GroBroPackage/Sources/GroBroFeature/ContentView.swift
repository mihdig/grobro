import SwiftUI
import GroBroDomain

/// Container for the Garden view with dependency injection
@available(iOS 17.0, *)
public struct GardenContainerView: View {
    @StateObject private var plantStore: PlantStore
    @StateObject private var eventStore: EventStore

    public init(plantStore: PlantStore, eventStore: EventStore) {
        _plantStore = StateObject(wrappedValue: plantStore)
        _eventStore = StateObject(wrappedValue: eventStore)
    }

    public var body: some View {
        GardenView(viewModel: GardenViewModel(plantStore: plantStore, eventStore: eventStore))
    }
}
