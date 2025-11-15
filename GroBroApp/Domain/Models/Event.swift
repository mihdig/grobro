import Foundation

enum EventType: Int16 {
    case watering
    case feeding
    case flush
    case note
    case photo
    case stress
}

enum StressTag: Int16 {
    case heatStress
    case lightStress
    case overwatering
    case underwatering
    case pests
    case training
    case transplant
    case other
}

struct Event: Identifiable, Equatable {
    let id: UUID
    let plantId: UUID
    let type: EventType
    let timestamp: Date
    var volumeLiters: Double?
    var noteText: String?
    var photoAssetId: String?
    var stressTags: [StressTag]
}

