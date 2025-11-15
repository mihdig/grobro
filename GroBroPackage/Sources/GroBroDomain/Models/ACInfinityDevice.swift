import Foundation

/// AC Infinity Controller device model
public struct ACInfinityDevice: Identifiable, Sendable, Codable {
    public let id: String
    public let name: String
    public let model: DeviceModel
    public let firmwareVersion: String
    public var isConnected: Bool
    public var lastSyncDate: Date?
    public var signalStrength: SignalStrength
    public var assignedPlantId: UUID?

    // Controller settings
    public var fanSpeed: Int // 0-10
    public var targetTemperature: TemperatureRange
    public var targetHumidity: HumidityRange

    public enum DeviceModel: String, Codable, Sendable {
        case controller69Pro = "Controller 69 Pro"
        case controller67 = "Controller 67"
        case controller69 = "Controller 69"

        public var displayName: String { rawValue }
    }

    public enum SignalStrength: String, Codable, Sendable {
        case excellent = "Excellent"
        case good = "Good"
        case fair = "Fair"
        case poor = "Poor"

        public var iconName: String {
            switch self {
            case .excellent: return "antenna.radiowaves.left.and.right"
            case .good: return "antenna.radiowaves.left.and.right"
            case .fair: return "antenna.radiowaves.left.and.right"
            case .poor: return "antenna.radiowaves.left.and.right.slash"
            }
        }

        public var bars: Int {
            switch self {
            case .excellent: return 4
            case .good: return 3
            case .fair: return 2
            case .poor: return 1
            }
        }
    }

    public struct TemperatureRange: Codable, Sendable {
        public var min: Double // Fahrenheit
        public var max: Double

        public static let `default` = TemperatureRange(min: 75, max: 80)

        public init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }
    }

    public struct HumidityRange: Codable, Sendable {
        public var min: Double // Percentage
        public var max: Double

        public static let `default` = HumidityRange(min: 55, max: 65)

        public init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }
    }

    public init(
        id: String,
        name: String,
        model: DeviceModel,
        firmwareVersion: String,
        isConnected: Bool = false,
        lastSyncDate: Date? = nil,
        signalStrength: SignalStrength = .good,
        assignedPlantId: UUID? = nil,
        fanSpeed: Int = 5,
        targetTemperature: TemperatureRange = .default,
        targetHumidity: HumidityRange = .default
    ) {
        self.id = id
        self.name = name
        self.model = model
        self.firmwareVersion = firmwareVersion
        self.isConnected = isConnected
        self.lastSyncDate = lastSyncDate
        self.signalStrength = signalStrength
        self.assignedPlantId = assignedPlantId
        self.fanSpeed = fanSpeed
        self.targetTemperature = targetTemperature
        self.targetHumidity = targetHumidity
    }

    /// Time since last successful sync
    public var timeSinceLastSync: TimeInterval? {
        guard let lastSyncDate = lastSyncDate else { return nil }
        return Date().timeIntervalSince(lastSyncDate)
    }

    /// User-friendly last sync description
    public var lastSyncDescription: String {
        guard let interval = timeSinceLastSync else {
            return "Never synced"
        }

        if interval < 10 {
            return "Just now"
        } else if interval < 60 {
            return "\(Int(interval)) seconds ago"
        } else if interval < 3600 {
            return "\(Int(interval / 60)) minutes ago"
        } else {
            return "\(Int(interval / 3600)) hours ago"
        }
    }

    /// Mock device for previews and testing
    public static let mock = ACInfinityDevice(
        id: "AC69PRO-123456",
        name: "AC Infinity Controller 69 Pro",
        model: .controller69Pro,
        firmwareVersion: "2.1.4",
        isConnected: true,
        lastSyncDate: Date(),
        signalStrength: .excellent,
        fanSpeed: 6
    )

    public static let mockOffline = ACInfinityDevice(
        id: "AC69PRO-789012",
        name: "AC Infinity Controller 69 Pro",
        model: .controller69Pro,
        firmwareVersion: "2.1.4",
        isConnected: false,
        signalStrength: .poor
    )
}

/// Device discovery result during scanning
public struct DiscoveredDevice: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let model: ACInfinityDevice.DeviceModel
    public let signalStrength: ACInfinityDevice.SignalStrength

    public init(id: String, name: String, model: ACInfinityDevice.DeviceModel, signalStrength: ACInfinityDevice.SignalStrength) {
        self.id = id
        self.name = name
        self.model = model
        self.signalStrength = signalStrength
    }

    public func toDevice(firmwareVersion: String = "Unknown") -> ACInfinityDevice {
        ACInfinityDevice(
            id: id,
            name: name,
            model: model,
            firmwareVersion: firmwareVersion,
            signalStrength: signalStrength
        )
    }
}
