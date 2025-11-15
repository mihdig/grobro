import Foundation

// MARK: - Status Enums

/// Hydration status classification
public enum HydrationStatus: String, Sendable, CaseIterable {
    case unknown
    case normal
    case possibleOverwatering
    case possibleUnderwatering

    public var displayName: String {
        switch self {
        case .unknown: return "Unknown"
        case .normal: return "Normal"
        case .possibleOverwatering: return "Possible Overwatering"
        case .possibleUnderwatering: return "Possible Underwatering"
        }
    }
}

/// Light stress status classification
public enum LightStressStatus: String, Sendable, CaseIterable {
    case unknown
    case none
    case possible

    public var displayName: String {
        switch self {
        case .unknown: return "Unknown"
        case .none: return "None Detected"
        case .possible: return "Possible"
        }
    }
}

/// Leaf condition status classification
public enum LeafConditionStatus: String, Sendable, CaseIterable {
    case unknown
    case normal
    case chlorosis
    case spots
    case necrosis

    public var displayName: String {
        switch self {
        case .unknown: return "Unknown"
        case .normal: return "Normal"
        case .chlorosis: return "Chlorosis (Yellowing)"
        case .spots: return "Spots Present"
        case .necrosis: return "Necrosis (Dead Tissue)"
        }
    }
}

/// Pests status classification
public enum PestsStatus: String, Sendable, CaseIterable {
    case unknown
    case notObvious
    case possible

    public var displayName: String {
        switch self {
        case .unknown: return "Unknown"
        case .notObvious: return "Not Obvious"
        case .possible: return "Possible"
        }
    }
}

// MARK: - DiagnosticsResult Model

/// Represents the result of a photo-based diagnostic run
public struct DiagnosticsResult: Identifiable, Sendable {
    public let id: UUID
    public let plantId: UUID
    public let eventId: UUID?
    public let createdAt: Date
    public let modelVersion: String
    public var hydrationStatus: HydrationStatus
    public var lightStressStatus: LightStressStatus
    public var leafConditionStatus: LeafConditionStatus
    public var pestsStatus: PestsStatus
    public var overallConfidence: Double?
    public var checklistItems: [String]

    public init(
        id: UUID = UUID(),
        plantId: UUID,
        eventId: UUID? = nil,
        createdAt: Date = Date(),
        modelVersion: String,
        hydrationStatus: HydrationStatus,
        lightStressStatus: LightStressStatus,
        leafConditionStatus: LeafConditionStatus,
        pestsStatus: PestsStatus,
        overallConfidence: Double? = nil,
        checklistItems: [String] = []
    ) {
        self.id = id
        self.plantId = plantId
        self.eventId = eventId
        self.createdAt = createdAt
        self.modelVersion = modelVersion
        self.hydrationStatus = hydrationStatus
        self.lightStressStatus = lightStressStatus
        self.leafConditionStatus = leafConditionStatus
        self.pestsStatus = pestsStatus
        self.overallConfidence = overallConfidence
        self.checklistItems = checklistItems
    }

    /// Computes an overall health summary
    public var healthSummary: String {
        var concerns: [String] = []

        if hydrationStatus == .possibleOverwatering || hydrationStatus == .possibleUnderwatering {
            concerns.append("hydration")
        }
        if lightStressStatus == .possible {
            concerns.append("light stress")
        }
        if leafConditionStatus != .normal && leafConditionStatus != .unknown {
            concerns.append("leaf condition")
        }
        if pestsStatus == .possible {
            concerns.append("pests")
        }

        if concerns.isEmpty {
            return "No obvious concerns detected"
        } else {
            return "Potential concerns: \(concerns.joined(separator: ", "))"
        }
    }
}
