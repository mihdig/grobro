import Foundation
import GroBroDomain

@MainActor
public final class DiaryViewModel: ObservableObject {
    @Published public var events: [Event] = []
    @Published public var selectedTypes: Set<EventType> = Set(EventType.allCases)
    @Published public var showError: Bool = false
    @Published public var errorMessage: String = ""

    public let plantId: UUID
    public let eventStore: EventStore

    public var filteredEvents: [Event] {
        events.filter { selectedTypes.contains($0.type) }
    }

    public init(plantId: UUID, eventStore: EventStore) {
        self.plantId = plantId
        self.eventStore = eventStore
    }

    public func loadEvents() {
        do {
            events = try eventStore.fetchEvents(for: plantId)
        } catch {
            errorMessage = "Failed to load events: \(error.localizedDescription)"
            showError = true
        }
    }

    public func toggleFilter(_ type: EventType) {
        if selectedTypes.contains(type) {
            selectedTypes.remove(type)
        } else {
            selectedTypes.insert(type)
        }
    }

    public func deleteEvents(at offsets: IndexSet) {
        let eventsToDelete = offsets.map { filteredEvents[$0] }

        for event in eventsToDelete {
            do {
                try eventStore.deleteEvent(id: event.id)
            } catch {
                errorMessage = "Failed to delete event: \(error.localizedDescription)"
                showError = true
            }
        }

        loadEvents()
    }

    public func makeEventCreationViewModel(type: EventType) -> EventCreationViewModel {
        let viewModel = EventCreationViewModel(plantId: plantId, eventType: type, eventStore: eventStore)
        viewModel.onEventCreated = { [weak self] _ in
            self?.loadEvents()
        }
        return viewModel
    }
}
