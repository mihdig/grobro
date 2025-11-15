import Foundation

/// Represents a specific nutrient product from a brand
public struct NutrientProduct: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public let name: String
    public let brand: NutrientBrand
    public let productLine: String?

    /// NPK ratio (Nitrogen-Phosphorus-Potassium)
    public let npkRatio: NPKRatio?

    /// Typical dosage range in ml per gallon
    public let dosageRangePerGallon: DosageRange?

    /// Product type/category
    public let category: ProductCategory

    public init(
        id: UUID = UUID(),
        name: String,
        brand: NutrientBrand,
        productLine: String? = nil,
        npkRatio: NPKRatio? = nil,
        dosageRangePerGallon: DosageRange? = nil,
        category: ProductCategory = .baseNutrient
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.productLine = productLine
        self.npkRatio = npkRatio
        self.dosageRangePerGallon = dosageRangePerGallon
        self.category = category
    }
}

/// Dosage range for nutrient products
public struct DosageRange: Codable, Sendable, Hashable {
    public let min: Double
    public let max: Double

    public init(min: Double, max: Double) {
        self.min = min
        self.max = max
    }
}

/// NPK (Nitrogen-Phosphorus-Potassium) ratio
public struct NPKRatio: Codable, Sendable, Hashable {
    public let nitrogen: Double  // N
    public let phosphorus: Double  // P
    public let potassium: Double  // K

    public init(nitrogen: Double, phosphorus: Double, potassium: Double) {
        self.nitrogen = nitrogen
        self.phosphorus = phosphorus
        self.potassium = potassium
    }

    /// Formatted string representation (e.g., "5-10-5")
    public var formatted: String {
        "\(Int(nitrogen))-\(Int(phosphorus))-\(Int(potassium))"
    }
}

/// Product category/type
public enum ProductCategory: String, Codable, CaseIterable, Sendable {
    case baseNutrient = "base_nutrient"
    case supplement = "supplement"
    case calMag = "cal_mag"
    case bloom = "bloom"
    case grow = "grow"
    case micro = "micro"
    case phAdjuster = "ph_adjuster"
    case additive = "additive"

    public var displayName: String {
        switch self {
        case .baseNutrient:
            return "Base Nutrient"
        case .supplement:
            return "Supplement"
        case .calMag:
            return "Cal-Mag"
        case .bloom:
            return "Bloom"
        case .grow:
            return "Grow"
        case .micro:
            return "Micro"
        case .phAdjuster:
            return "pH Adjuster"
        case .additive:
            return "Additive"
        }
    }
}
