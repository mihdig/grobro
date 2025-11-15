import Foundation

/// Represents a specific dosage of a nutrient product
public struct NutrientDosage: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public let productId: UUID
    public let productName: String
    public let amount: Double
    public let unit: DosageUnit

    public init(
        id: UUID = UUID(),
        productId: UUID,
        productName: String,
        amount: Double,
        unit: DosageUnit
    ) {
        self.id = id
        self.productId = productId
        self.productName = productName
        self.amount = amount
        self.unit = unit
    }

    /// Convert dosage to milliliters
    public var amountInMilliliters: Double {
        switch unit {
        case .milliliters:
            return amount
        case .teaspoons:
            return amount * 4.92892  // 1 tsp = ~4.92892 ml
        case .tablespoons:
            return amount * 14.7868  // 1 tbsp = ~14.7868 ml
        case .grams:
            return amount  // Assume 1:1 for liquid nutrients
        }
    }

    /// Formatted display string
    public var formattedAmount: String {
        String(format: "%.2f %@", amount, unit.abbreviation)
    }
}

/// Unit of measurement for nutrient dosage
public enum DosageUnit: String, Codable, CaseIterable, Sendable {
    case milliliters = "ml"
    case teaspoons = "tsp"
    case tablespoons = "tbsp"
    case grams = "g"

    public var displayName: String {
        switch self {
        case .milliliters:
            return "Milliliters"
        case .teaspoons:
            return "Teaspoons"
        case .tablespoons:
            return "Tablespoons"
        case .grams:
            return "Grams"
        }
    }

    public var abbreviation: String {
        self.rawValue
    }
}
