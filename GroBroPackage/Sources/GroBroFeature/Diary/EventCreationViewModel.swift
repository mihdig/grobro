import Foundation
import GroBroDomain

@MainActor
public final class EventCreationViewModel: ObservableObject {
    @Published public var volumeLiters: Double? = nil
    @Published public var noteText: String = ""
    @Published public var stressTags: Set<StressTag> = []

    public let plantId: UUID
    public let eventType: EventType
    private let eventStore: EventStore
    public var onEventCreated: ((Event) -> Void)?

    public init(plantId: UUID, eventType: EventType, eventStore: EventStore) {
        self.plantId = plantId
        self.eventType = eventType
        self.eventStore = eventStore
    }

    public func saveEvent() {
        let event = Event(
            plantId: plantId,
            type: eventType,
            volumeLiters: volumeLiters,
            noteText: noteText.isEmpty ? nil : noteText,
            stressTags: Array(stressTags)
        )

        do {
            let createdEvent = try eventStore.createEvent(event)
            onEventCreated?(createdEvent)
        } catch {
            print("Failed to save event: \(error)")
        }
    }
}
