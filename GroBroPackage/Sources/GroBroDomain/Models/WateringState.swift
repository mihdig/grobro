import Foundation

/// Represents the watering state for a plant including schedule and feedback
public struct WateringState: Identifiable, Sendable {
    public let id: UUID
    public let plantId: UUID
    public var intervalDays: Int
    public var lastWateringDate: Date?
    public var nextWateringDate: Date?

    public init(
        id: UUID = UUID(),
        plantId: UUID,
        intervalDays: Int,
        lastWateringDate: Date? = nil,
        nextWateringDate: Date? = nil
    ) {
        self.id = id
        self.plantId = plantId
        self.intervalDays = intervalDays
        self.lastWateringDate = lastWateringDate
        self.nextWateringDate = nextWateringDate
    }
}
