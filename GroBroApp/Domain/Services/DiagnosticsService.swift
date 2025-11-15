import CoreData
import Foundation
import UIKit

/// Service responsible for running L1 diagnostics on a plant photo.
///
/// In early versions this can use a placeholder model or heuristic,
/// as long as it produces a DiagnosticsResult compatible with the
/// data model and AI architecture.
final class DiagnosticsService {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func runDiagnostics(for plantId: UUID, image: UIImage) throws -> DiagnosticsResult {
        // TODO: replace placeholder logic with Core ML model inference.
        let now = Date()

        let result = DiagnosticsResult(
            id: UUID(),
            plantId: plantId,
            createdAt: now,
            modelVersion: "placeholder-v1",
            hydrationStatus: .unknown,
            lightStressStatus: .unknown,
            leafConditionStatus: .unknown,
            pestsStatus: .unknown,
            overallConfidence: nil,
            checklistItems: [
                "Check soil moisture with your finger or a simple meter.",
                "Verify that the distance between light and canopy is reasonable.",
                "Look at the underside of leaves for any visible pests.",
                "Observe the plant for a few days before making drastic changes."
            ]
        )

        // Persist a minimal representation in Core Data if desired by
        // later stories. For now this is a pure domain result.
        _ = result

        return result
    }
}

