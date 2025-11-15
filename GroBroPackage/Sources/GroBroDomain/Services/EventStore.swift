import Foundation
import CoreData
import GroBroPersistence

/// Service responsible for CRUD operations on Event entities
@available(iOS 17.0, macOS 14.0, *)
@MainActor
public final class EventStore: ObservableObject {

    private let persistenceController: PersistenceController

    public init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }

    /// Fetch all events for a specific plant
    /// - Parameter plantId: The plant's UUID
    /// - Returns: Array of Event domain models sorted by timestamp descending
    public func fetchEvents(for plantId: UUID) throws -> [Event] {
        let request = EventEntity.fetchRequest()
        request.predicate = NSPredicate(format: "plantId == %@", plantId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \EventEntity.timestamp, ascending: false)]

        let entities = try persistenceController.viewContext.fetch(request)
        return entities.compactMap { toDomain($0) }
    }

    /// Fetch events for a plant filtered by event type
    /// - Parameters:
    ///   - plantId: The plant's UUID
    ///   - types: Array of EventTypes to filter by
    /// - Returns: Array of filtered Event domain models
    public func fetchEvents(for plantId: UUID, types: [EventType]) throws -> [Event] {
        let request = EventEntity.fetchRequest()
        let typeStrings = types.map { $0.rawValue }
        request.predicate = NSPredicate(
            format: "plantId == %@ AND type IN %@",
            plantId as CVarArg,
            typeStrings
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \EventEntity.timestamp, ascending: false)]

        let entities = try persistenceController.viewContext.fetch(request)
        return entities.compactMap { toDomain($0) }
    }

    /// Create a new event
    /// - Parameter event: The Event domain model to create
    /// - Returns: The created Event with persisted ID
    public func createEvent(_ event: Event) throws -> Event {
        let entity = EventEntity(context: persistenceController.viewContext)
        toEntity(event, entity: entity)

        try persistenceController.save()
        return toDomain(entity)!
    }

    /// Delete an event
    /// - Parameter id: The event's UUID
    public func deleteEvent(id: UUID) throws {
        let request = EventEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        let entities = try persistenceController.viewContext.fetch(request)
        guard let entity = entities.first else {
            throw EventStoreError.eventNotFound
        }

        persistenceController.viewContext.delete(entity)
        try persistenceController.save()
    }

    // MARK: - Mapping Helpers

    private struct EventMetadata: Codable {
        var source: EventSource?
        var environmentalData: EnvironmentalData?
        var lightMeasurement: LightMeasurementData?
    }

    private func toDomain(_ entity: EventEntity) -> Event? {
        guard let eventType = EventType(rawValue: entity.type) else {
            return nil
        }

        // Parse stress tags from comma-separated string
        let stressTags: [StressTag] = if let tagsString = entity.stressTags, !tagsString.isEmpty {
            tagsString.split(separator: ",")
                .compactMap { StressTag(rawValue: String($0)) }
        } else {
            []
        }

        let metadata: EventMetadata? = if let metadataString = entity.metadataJSON,
            let data = metadataString.data(using: .utf8) {
            try? JSONDecoder().decode(EventMetadata.self, from: data)
        } else {
            nil
        }

        return Event(
            id: entity.id,
            plantId: entity.plantId,
            type: eventType,
            timestamp: entity.timestamp,
            volumeLiters: entity.volumeLiters > 0 ? entity.volumeLiters : nil,
            nutrientProfileId: entity.nutrientProfileId,
            noteText: entity.noteText,
            photoAssetId: entity.photoAssetId,
            stressTags: stressTags,
            source: metadata?.source ?? .manual,
            environmentalData: metadata?.environmentalData,
            lightMeasurement: metadata?.lightMeasurement
        )
    }

    private func toEntity(_ event: Event, entity: EventEntity) {
        entity.id = event.id
        entity.plantId = event.plantId
        entity.type = event.type.rawValue
        entity.timestamp = event.timestamp
        entity.volumeLiters = event.volumeLiters ?? 0
        entity.nutrientProfileId = event.nutrientProfileId
        entity.noteText = event.noteText
        entity.photoAssetId = event.photoAssetId

        // Store stress tags as comma-separated string
        if !event.stressTags.isEmpty {
            entity.stressTags = event.stressTags.map { $0.rawValue }.joined(separator: ",")
        } else {
            entity.stressTags = nil
        }

        // Encode structured metadata as JSON string
        let metadata = EventMetadata(
            source: event.source,
            environmentalData: event.environmentalData,
            lightMeasurement: event.lightMeasurement
        )

        if let data = try? JSONEncoder().encode(metadata),
           let jsonString = String(data: data, encoding: .utf8) {
            entity.metadataJSON = jsonString
        } else {
            entity.metadataJSON = nil
        }
    }
}

public enum EventStoreError: Error, LocalizedError {
    case eventNotFound
    case saveFailed

    public var errorDescription: String? {
        switch self {
        case .eventNotFound:
            return "Event not found"
        case .saveFailed:
            return "Failed to save event"
        }
    }
}
