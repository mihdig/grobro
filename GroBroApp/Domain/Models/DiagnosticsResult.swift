import Foundation

enum HydrationStatus: Int16 {
    case unknown
    case normal
    case possibleOverwatering
    case possibleUnderwatering
}

enum LightStressStatus: Int16 {
    case unknown
    case none
    case possible
}

enum LeafConditionStatus: Int16 {
    case unknown
    case normal
    case chlorosis
    case spots
    case necrosis
}

enum PestsStatus: Int16 {
    case unknown
    case notObvious
    case possible
}

struct DiagnosticsResult: Identifiable, Equatable {
    let id: UUID
    let plantId: UUID
    let createdAt: Date
    let modelVersion: String

    let hydrationStatus: HydrationStatus
    let lightStressStatus: LightStressStatus
    let leafConditionStatus: LeafConditionStatus
    let pestsStatus: PestsStatus

    let overallConfidence: Double?
    let checklistItems: [String]
}

