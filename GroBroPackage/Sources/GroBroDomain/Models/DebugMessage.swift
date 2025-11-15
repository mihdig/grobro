import Foundation

/// Represents a message in the debug console chat
public struct DebugMessage: Identifiable, Sendable {
    public let id: UUID
    public let plantId: UUID
    public let timestamp: Date
    public let isUserMessage: Bool
    public let content: String

    public init(
        id: UUID = UUID(),
        plantId: UUID,
        timestamp: Date = Date(),
        isUserMessage: Bool,
        content: String
    ) {
        self.id = id
        self.plantId = plantId
        self.timestamp = timestamp
        self.isUserMessage = isUserMessage
        self.content = content
    }
}
