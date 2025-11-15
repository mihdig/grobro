import Foundation

/// Supported nutrient brands
public enum NutrientBrand: String, Codable, CaseIterable, Sendable {
    case generalHydroponics = "general_hydroponics"
    case advancedNutrients = "advanced_nutrients"
    case foxFarm = "fox_farm"
    case canna = "canna"
    case biobizz = "biobizz"

    /// Display name for the brand
    public var displayName: String {
        switch self {
        case .generalHydroponics:
            return "General Hydroponics"
        case .advancedNutrients:
            return "Advanced Nutrients"
        case .foxFarm:
            return "Fox Farm"
        case .canna:
            return "Canna"
        case .biobizz:
            return "BioBizz"
        }
    }

    /// Whether this brand requires Pro subscription
    public var requiresPro: Bool {
        switch self {
        case .generalHydroponics, .advancedNutrients:
            return false
        case .foxFarm, .canna, .biobizz:
            return true
        }
    }

    /// Brand color identifier for UI
    public var colorIdentifier: String {
        switch self {
        case .generalHydroponics:
            return "gheGreen"
        case .advancedNutrients:
            return "anRed"
        case .foxFarm:
            return "ffOrange"
        case .canna:
            return "cannaGreen"
        case .biobizz:
            return "bbEarth"
        }
    }
}
