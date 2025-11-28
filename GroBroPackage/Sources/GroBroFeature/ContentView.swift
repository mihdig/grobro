import SwiftUI
import GroBroDomain

/// Container for the Garden view with dependency injection
@available(iOS 17.0, *)
public struct GardenContainerView: View {
    @StateObject private var plantStore: PlantStore
    @StateObject private var eventStore: EventStore
    private var deepLink: Binding<DeepLinkDestination?>

    public init(
        plantStore: PlantStore,
        eventStore: EventStore,
        deepLink: Binding<DeepLinkDestination?> = .constant(nil)
    ) {
        _plantStore = StateObject(wrappedValue: plantStore)
        _eventStore = StateObject(wrappedValue: eventStore)
        self.deepLink = deepLink
    }

    public var body: some View {
        GardenView(
            viewModel: GardenViewModel(plantStore: plantStore, eventStore: eventStore),
            deepLink: deepLink
        )
    }
}
