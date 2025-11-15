import Foundation

/// Represents a complete nutrient mix with multiple products
public struct NutrientMix: Identifiable, Codable, Sendable {
    public let id: UUID
    public let dosages: [NutrientDosage]
    public let brand: NutrientBrand
    public let productLine: String?
    public let reservoirVolume: ReservoirVolume
    public let plantStage: PlantStage
    public let createdDate: Date

    /// Calculated total PPM (if available from products)
    public var estimatedPPM: Double?

    /// Calculated total EC (if available)
    public var estimatedEC: Double?

    public init(
        id: UUID = UUID(),
        dosages: [NutrientDosage],
        brand: NutrientBrand,
        productLine: String? = nil,
        reservoirVolume: ReservoirVolume,
        plantStage: PlantStage,
        createdDate: Date = Date(),
        estimatedPPM: Double? = nil,
        estimatedEC: Double? = nil
    ) {
        self.id = id
        self.dosages = dosages
        self.brand = brand
        self.productLine = productLine
        self.reservoirVolume = reservoirVolume
        self.plantStage = plantStage
        self.createdDate = createdDate
        self.estimatedPPM = estimatedPPM
        self.estimatedEC = estimatedEC
    }

    /// Total number of products in the mix
    public var productCount: Int {
        dosages.count
    }
}

/// Reservoir volume with unit
public struct ReservoirVolume: Codable, Sendable, Hashable {
    public let amount: Double
    public let unit: VolumeUnit

    public init(amount: Double, unit: VolumeUnit) {
        self.amount = amount
        self.unit = unit
    }

    /// Convert to liters
    public var liters: Double {
        switch unit {
        case .liters:
            return amount
        case .gallons:
            return amount * 3.78541  // 1 gallon = ~3.78541 liters
        case .milliliters:
            return amount / 1000.0
        }
    }

    /// Convert to gallons
    public var gallons: Double {
        switch unit {
        case .liters:
            return amount / 3.78541
        case .gallons:
            return amount
        case .milliliters:
            return amount / 3785.41
        }
    }

    /// Formatted display string
    public var formatted: String {
        String(format: "%.1f %@", amount, unit.abbreviation)
    }
}

/// Volume unit for reservoir size
public enum VolumeUnit: String, Codable, CaseIterable, Sendable {
    case liters = "L"
    case gallons = "gal"
    case milliliters = "ml"

    public var displayName: String {
        switch self {
        case .liters:
            return "Liters"
        case .gallons:
            return "Gallons"
        case .milliliters:
            return "Milliliters"
        }
    }

    public var abbreviation: String {
        self.rawValue
    }
}
