import Foundation

/// Represents a complete feeding schedule for a nutrient product line
public struct FeedingSchedule: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public let brand: NutrientBrand
    public let productLine: ProductLine
    public let name: String
    public let description: String
    public let weeks: [WeeklyDosage]
    public let products: [String] // Product names used in this schedule
    public let safetyNotes: [String]

    public init(
        id: UUID = UUID(),
        brand: NutrientBrand,
        productLine: ProductLine,
        name: String,
        description: String,
        weeks: [WeeklyDosage],
        products: [String],
        safetyNotes: [String]
    ) {
        self.id = id
        self.brand = brand
        self.productLine = productLine
        self.name = name
        self.description = description
        self.weeks = weeks
        self.products = products
        self.safetyNotes = safetyNotes
    }
}

/// Represents dosage information for a single week
public struct WeeklyDosage: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public let weekNumber: Int
    public let stage: GrowthStage
    public let stageName: String
    public let productDosages: [ScheduleProductDosage]
    public let notes: String?

    public init(
        id: UUID = UUID(),
        weekNumber: Int,
        stage: GrowthStage,
        stageName: String,
        productDosages: [ScheduleProductDosage],
        notes: String? = nil
    ) {
        self.id = id
        self.weekNumber = weekNumber
        self.stage = stage
        self.stageName = stageName
        self.productDosages = productDosages
        self.notes = notes
    }
}

/// Dosage for a specific product in a feeding schedule week
public struct ScheduleProductDosage: Codable, Sendable, Hashable {
    public let productName: String
    public let mlPerGallon: Double
    public let mlPerLiter: Double

    public init(productName: String, mlPerGallon: Double, mlPerLiter: Double) {
        self.productName = productName
        self.mlPerGallon = mlPerGallon
        self.mlPerLiter = mlPerLiter
    }

    /// Convenience initializer that calculates mlPerLiter from mlPerGallon
    public init(productName: String, mlPerGallon: Double) {
        self.productName = productName
        self.mlPerGallon = mlPerGallon
        self.mlPerLiter = mlPerGallon / 3.78541 // 1 gallon = 3.78541 liters
    }
}

/// Product line within a brand
public enum ProductLine: String, Codable, CaseIterable, Sendable {
    case floraSeries = "flora_series"
    case floraNova = "flora_nova"
    case bioThrive = "bio_thrive"
    case phPerfectGMB = "ph_perfect_gmb" // Grow, Micro, Bloom
    case phPerfectSensi = "ph_perfect_sensi"
    case foxFarmTrio = "fox_farm_trio"
    case cannaTerra = "canna_terra"
    case cannaCoco = "canna_coco"
    case biobizzOrganic = "biobizz_organic"

    public var displayName: String {
        switch self {
        case .floraSeries:
            return "Flora Series"
        case .floraNova:
            return "Flora Nova"
        case .bioThrive:
            return "BioThrive"
        case .phPerfectGMB:
            return "pH Perfect (Grow, Micro, Bloom)"
        case .phPerfectSensi:
            return "pH Perfect Sensi"
        case .foxFarmTrio:
            return "Fox Farm Trio"
        case .cannaTerra:
            return "Canna Terra"
        case .cannaCoco:
            return "Canna Coco"
        case .biobizzOrganic:
            return "BioBizz Organic"
        }
    }

    public var brand: NutrientBrand {
        switch self {
        case .floraSeries, .floraNova, .bioThrive:
            return .generalHydroponics
        case .phPerfectGMB, .phPerfectSensi:
            return .advancedNutrients
        case .foxFarmTrio:
            return .foxFarm
        case .cannaTerra, .cannaCoco:
            return .canna
        case .biobizzOrganic:
            return .biobizz
        }
    }

    /// Whether this product line requires Pro subscription
    public var requiresPro: Bool {
        brand.requiresPro
    }
}

/// Growth stage for feeding schedules
public enum GrowthStage: String, Codable, CaseIterable, Sendable {
    case seedling = "seedling"
    case earlyVegetative = "early_vegetative"
    case lateVegetative = "late_vegetative"
    case transition = "transition"
    case earlyFlowering = "early_flowering"
    case midFlowering = "mid_flowering"
    case lateFlowering = "late_flowering"
    case flush = "flush"

    public var displayName: String {
        switch self {
        case .seedling:
            return "Seedling/Clone"
        case .earlyVegetative:
            return "Early Vegetative"
        case .lateVegetative:
            return "Late Vegetative"
        case .transition:
            return "Transition"
        case .earlyFlowering:
            return "Early Flowering"
        case .midFlowering:
            return "Mid Flowering"
        case .lateFlowering:
            return "Late Flowering"
        case .flush:
            return "Flush"
        }
    }

    public var icon: String {
        switch self {
        case .seedling:
            return "leaf.fill"
        case .earlyVegetative, .lateVegetative:
            return "tree.fill"
        case .transition:
            return "arrow.triangle.2.circlepath"
        case .earlyFlowering, .midFlowering, .lateFlowering:
            return "flower.fill"
        case .flush:
            return "drop.fill"
        }
    }
}
