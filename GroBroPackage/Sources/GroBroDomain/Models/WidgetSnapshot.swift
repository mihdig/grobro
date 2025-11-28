import Foundation

// MARK: - Widget Snapshot Models

/// Lightweight snapshot of a plant that is safe to serialize and share with widgets.
public struct WidgetPlantSnapshot: Identifiable, Codable, Hashable, Sendable {
    public struct EnvironmentalSummary: Codable, Hashable, Sendable {
        public enum Status: String, Codable, Hashable, Sendable {
            case optimal
            case caution
            case critical
            case offline
        }

        public let temperature: Double
        public let humidity: Double
        public let vpd: Double
        public let status: Status
        public let lastReadingDate: Date

        public init(
            temperature: Double,
            humidity: Double,
            vpd: Double,
            status: Status,
            lastReadingDate: Date = Date()
        ) {
            self.temperature = temperature
            self.humidity = humidity
            self.vpd = vpd
            self.status = status
            self.lastReadingDate = lastReadingDate
        }
    }

    public enum StatusBadge: String, Codable, Hashable, Sendable {
        case dueSoon
        case overdue
        case offline
        case pro
        case empty

        public var title: String {
            switch self {
            case .dueSoon: return "Due Soon"
            case .overdue: return "Overdue"
            case .offline: return "Sensor Offline"
            case .pro: return "Pro"
            case .empty: return "Empty"
            }
        }

        public var systemImageName: String {
            switch self {
            case .dueSoon: return "clock"
            case .overdue: return "exclamationmark.triangle.fill"
            case .offline: return "antenna.radiowaves.left.and.right.slash"
            case .pro: return "star.fill"
            case .empty: return "plus"
            }
        }
    }

    public let id: UUID
    public let name: String
    public let stage: PlantStage
    public let countdownText: String
    public let statusMessage: String
    public let nextWateringDate: Date?
    public let isOverdue: Bool
    public let badges: [StatusBadge]
    public let environment: EnvironmentalSummary?
    public let isProOnlyFeature: Bool
    public let updatedAt: Date

    public init(
        id: UUID,
        name: String,
        stage: PlantStage,
        countdownText: String,
        statusMessage: String,
        nextWateringDate: Date?,
        isOverdue: Bool,
        badges: [StatusBadge],
        environment: EnvironmentalSummary?,
        isProOnlyFeature: Bool,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.stage = stage
        self.countdownText = countdownText
        self.statusMessage = statusMessage
        self.nextWateringDate = nextWateringDate
        self.isOverdue = isOverdue
        self.badges = badges
        self.environment = environment
        self.isProOnlyFeature = isProOnlyFeature
        self.updatedAt = updatedAt
    }

    public static let placeholder: WidgetPlantSnapshot = .init(
        id: UUID(),
        name: "GroBro",
        stage: .vegetative,
        countdownText: "Water in 3h",
        statusMessage: "Water in 3 hours",
        nextWateringDate: Date().addingTimeInterval(10_800),
        isOverdue: false,
        badges: [.dueSoon],
        environment: .init(
            temperature: 78,
            humidity: 58,
            vpd: 1.1,
            status: .optimal
        ),
        isProOnlyFeature: false
    )
}

/// Snapshot of the full garden used to populate widgets.
public struct WidgetGardenSnapshot: Codable, Hashable, Sendable {
    public let generatedAt: Date
    public let plants: [WidgetPlantSnapshot]
    public let emptyStateMessage: String
    public let hasConnectedDevices: Bool

    public init(
        generatedAt: Date = Date(),
        plants: [WidgetPlantSnapshot],
        emptyStateMessage: String,
        hasConnectedDevices: Bool
    ) {
        self.generatedAt = generatedAt
        self.plants = plants
        self.emptyStateMessage = emptyStateMessage
        self.hasConnectedDevices = hasConnectedDevices
    }

    public static let placeholder: WidgetGardenSnapshot = .init(
        plants: [.placeholder],
        emptyStateMessage: "Add your first plant",
        hasConnectedDevices: true
    )
}

/// Persisted widget configuration per widget identifier.
public struct WidgetConfigurationRecord: Codable, Hashable, Sendable {
    public enum WidgetFamily: String, Codable, Sendable {
        case home
        case lockScreen
    }

    public let widgetID: String
    public var family: WidgetFamily
    public var plantIDs: [UUID]
    public var preferredPlantCount: Int

    public init(
        widgetID: String,
        family: WidgetFamily,
        plantIDs: [UUID],
        preferredPlantCount: Int
    ) {
        self.widgetID = widgetID
        self.family = family
        self.plantIDs = plantIDs
        self.preferredPlantCount = preferredPlantCount
    }
}
