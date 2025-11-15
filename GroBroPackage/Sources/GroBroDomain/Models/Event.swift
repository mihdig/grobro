import Foundation

/// Domain model representing an event in a plant's timeline/diary
public struct Event: Identifiable, Sendable {
    public let id: UUID
    public let plantId: UUID
    public var type: EventType
    public var timestamp: Date
    public var volumeLiters: Double?
    public var nutrientProfileId: UUID?
    public var noteText: String?
    public var photoAssetId: String?
    public var stressTags: [StressTag]

    // Optional structured metadata for advanced event types
    public var source: EventSource
    public var environmentalData: EnvironmentalData?
    public var lightMeasurement: LightMeasurementData?
    public var nutrientData: NutrientEventData?

    // Optional correlation data when environmental events coincide with plant events
    public var correlation: EventCorrelation?

    public init(
        id: UUID = UUID(),
        plantId: UUID,
        type: EventType,
        timestamp: Date = Date(),
        volumeLiters: Double? = nil,
        nutrientProfileId: UUID? = nil,
        noteText: String? = nil,
        photoAssetId: String? = nil,
        stressTags: [StressTag] = [],
        source: EventSource = .manual,
        environmentalData: EnvironmentalData? = nil,
        lightMeasurement: LightMeasurementData? = nil,
        nutrientData: NutrientEventData? = nil,
        correlation: EventCorrelation? = nil
    ) {
        self.id = id
        self.plantId = plantId
        self.type = type
        self.timestamp = timestamp
        self.volumeLiters = volumeLiters
        self.nutrientProfileId = nutrientProfileId
        self.noteText = noteText
        self.photoAssetId = photoAssetId
        self.stressTags = stressTags
        self.source = source
        self.environmentalData = environmentalData
        self.lightMeasurement = lightMeasurement
        self.nutrientData = nutrientData
        self.correlation = correlation
    }
}

/// Correlation data when environmental events coincide with plant events
public struct EventCorrelation: Codable, Sendable {
    public var message: String
    public var relatedEventId: UUID?

    public init(message: String, relatedEventId: UUID? = nil) {
        self.message = message
        self.relatedEventId = relatedEventId
    }
}

/// Source of an event (manual entry vs external integration)
public enum EventSource: String, Codable, Sendable {
    case manual
    case acInfinity
    case vivosun
    case lightMeter
    case other
}

/// Environmental data associated with an event (e.g., AC Infinity readings)
public struct EnvironmentalData: Codable, Sendable {
    public var temperatureFahrenheit: Double?
    public var humidityPercent: Double?
    public var vpdKilopascal: Double?
    public var deviceName: String?
    public var visualStyle: EnvironmentalEventStyle

    public init(
        temperatureFahrenheit: Double? = nil,
        humidityPercent: Double? = nil,
        vpdKilopascal: Double? = nil,
        deviceName: String? = nil,
        visualStyle: EnvironmentalEventStyle = .automatic
    ) {
        self.temperatureFahrenheit = temperatureFahrenheit
        self.humidityPercent = humidityPercent
        self.vpdKilopascal = vpdKilopascal
        self.deviceName = deviceName
        self.visualStyle = visualStyle
    }

    /// Calculate VPD from temperature and humidity
    public static func calculateVPD(temperatureFahrenheit: Double, humidityPercent: Double) -> Double {
        // Convert Fahrenheit to Celsius
        let tempC = (temperatureFahrenheit - 32) * 5 / 9

        // Calculate saturation vapor pressure (kPa)
        let svp = 0.6108 * exp((17.27 * tempC) / (tempC + 237.3))

        // Calculate actual vapor pressure
        let avp = svp * (humidityPercent / 100)

        // VPD = SVP - AVP
        return svp - avp
    }
}

/// Light measurement data logged from the light meter
public struct LightMeasurementData: Codable, Sendable {
    public var ppfd: Double?
    public var lux: Double?
    public var dli: Double?
    public var lightTypeIdentifier: String?
    public var distanceMeters: Double?

    public init(
        ppfd: Double? = nil,
        lux: Double? = nil,
        dli: Double? = nil,
        lightTypeIdentifier: String? = nil,
        distanceMeters: Double? = nil
    ) {
        self.ppfd = ppfd
        self.lux = lux
        self.dli = dli
        self.lightTypeIdentifier = lightTypeIdentifier
        self.distanceMeters = distanceMeters
    }
}

/// Nutrient data associated with a feeding event
public struct NutrientEventData: Codable, Sendable {
    /// Brand used for feeding
    public var brand: String?

    /// Product line (e.g., "Flora Series", "pH Perfect")
    public var productLine: String?

    /// List of products and dosages
    public var dosages: [ProductDosage]?

    /// PPM/EC readings
    public var feedPPM: Double?
    public var feedEC: Double?
    public var runoffPPM: Double?
    public var runoffEC: Double?

    /// pH readings
    public var feedPH: Double?
    public var runoffPH: Double?

    /// Reservoir volume
    public var reservoirVolumeLiters: Double?

    /// Optional recipe reference for reuse
    public var recipeId: UUID?
    public var recipeName: String?

    /// Cost tracking (Pro feature)
    public var totalCost: Double?

    public init(
        brand: String? = nil,
        productLine: String? = nil,
        dosages: [ProductDosage]? = nil,
        feedPPM: Double? = nil,
        feedEC: Double? = nil,
        runoffPPM: Double? = nil,
        runoffEC: Double? = nil,
        feedPH: Double? = nil,
        runoffPH: Double? = nil,
        reservoirVolumeLiters: Double? = nil,
        recipeId: UUID? = nil,
        recipeName: String? = nil,
        totalCost: Double? = nil
    ) {
        self.brand = brand
        self.productLine = productLine
        self.dosages = dosages
        self.feedPPM = feedPPM
        self.feedEC = feedEC
        self.runoffPPM = runoffPPM
        self.runoffEC = runoffEC
        self.feedPH = feedPH
        self.runoffPH = runoffPH
        self.reservoirVolumeLiters = reservoirVolumeLiters
        self.recipeId = recipeId
        self.recipeName = recipeName
        self.totalCost = totalCost
    }
}

/// Product and dosage for nutrient event data
public struct ProductDosage: Codable, Sendable {
    public var productName: String
    public var amount: Double
    public var unit: String

    public init(productName: String, amount: Double, unit: String) {
        self.productName = productName
        self.amount = amount
        self.unit = unit
    }
}
