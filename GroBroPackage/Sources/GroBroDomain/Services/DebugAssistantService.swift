import Foundation

/// Mode for debug assistant operation
public enum DebugAssistantMode {
    case online // Using MCP/LLM
    case offline // Rule-based fallback
}

/// Service responsible for providing debug assistance via LLM or fallback rules
@available(iOS 17.0, macOS 14.0, *)
@MainActor
public final class DebugAssistantService: ObservableObject {

    @Published public var mode: DebugAssistantMode = .offline
    @Published public var isProcessing: Bool = false

    private let eventStore: EventStore?

    public init(eventStore: EventStore? = nil) {
        self.eventStore = eventStore
    }

    /// Sends a user query and gets an assistant response
    /// - Parameters:
    ///   - query: The user's question or concern
    ///   - plant: The plant context
    ///   - recentDiagnostics: Optional recent diagnostic result for context
    /// - Returns: Assistant's response message
    public func sendQuery(
        _ query: String,
        for plant: Plant,
        recentDiagnostics: DiagnosticsResult? = nil
    ) async throws -> String {
        isProcessing = true
        defer { isProcessing = false }

        // Check if we can use online mode (MCP available)
        if await checkMCPAvailability() {
            mode = .online
            return try await queryMCP(query: query, plant: plant, diagnostics: recentDiagnostics)
        } else {
            mode = .offline
            return generateRuleBasedResponse(query: query, plant: plant, diagnostics: recentDiagnostics)
        }
    }

    // MARK: - MCP Integration (Placeholder)

    /// Checks if MCP service is available
    private func checkMCPAvailability() async -> Bool {
        // TODO: Implement actual MCP availability check
        // For now, always return false to use offline mode
        return false
    }

    /// Queries the MCP service for a response
    private func queryMCP(
        query: String,
        plant: Plant,
        diagnostics: DiagnosticsResult?
    ) async throws -> String {
        // TODO: Implement actual MCP integration
        // This would:
        // 1. Build context from plant data, events, and diagnostics
        // 2. Construct a safe prompt following AI safety guidelines
        // 3. Call MCP endpoint
        // 4. Parse and return response

        // Placeholder implementation
        try await Task.sleep(for: .seconds(1))

        return """
        [MCP Response - Not Implemented Yet]

        Based on the information about \(plant.name), here are some suggestions...
        """
    }

    // MARK: - Rule-Based Fallback

    /// Generates a rule-based response when offline or MCP unavailable
    private func generateRuleBasedResponse(
        query: String,
        plant: Plant,
        diagnostics: DiagnosticsResult?
    ) -> String {
        let lowercaseQuery = query.lowercased()

        // Build context
        var response = "[Limited Mode - Offline]\n\n"

        // Check keywords and provide relevant advice
        if lowercaseQuery.contains("yellow") || lowercaseQuery.contains("chlorosis") {
            response += buildChlorosisResponse(plant: plant)
        } else if lowercaseQuery.contains("water") || lowercaseQuery.contains("hydrat") {
            response += buildWateringResponse(plant: plant)
        } else if lowercaseQuery.contains("light") || lowercaseQuery.contains("burn") {
            response += buildLightResponse(plant: plant)
        } else if lowercaseQuery.contains("pest") || lowercaseQuery.contains("bug") {
            response += buildPestResponse(plant: plant)
        } else if lowercaseQuery.contains("nutrient") || lowercaseQuery.contains("feed") {
            response += buildNutrientResponse(plant: plant)
        } else {
            response += buildGeneralResponse(plant: plant)
        }

        // Add diagnostics context if available
        if let diag = diagnostics {
            response += "\n\nRecent Health Check:\n"
            response += "• \(diag.healthSummary)\n"
        }

        response += "\n\nNote: For detailed analysis, enable online mode or consult the diagnostics feature."

        return response
    }

    // MARK: - Rule-Based Response Builders

    private func buildChlorosisResponse(plant: Plant) -> String {
        """
        Yellowing leaves (chlorosis) can have several causes:

        Common Causes:
        • Nitrogen deficiency (especially in \(plant.stage.displayName) stage)
        • pH imbalance affecting nutrient uptake
        • Overwatering leading to root issues
        • Light stress or light burn

        Things to Check:
        • Is yellowing on older or newer leaves?
        • Check soil pH (should be 6.0-7.0 for most substrates)
        • Review your feeding schedule
        • Check soil moisture - not too wet or dry
        • Measure light distance from canopy
        """
    }

    private func buildWateringResponse(plant: Plant) -> String {
        let substrate = plant.substrateType?.displayName ?? "your substrate"

        return """
        Watering Guidelines for \(plant.stage.displayName) stage in \(substrate):

        General Tips:
        • Water when top 1-2 inches of soil are dry
        • Ensure even moisture distribution
        • Always check drainage - no standing water
        • Adjust frequency based on plant response

        Signs of Overwatering:
        • Drooping leaves despite wet soil
        • Yellowing lower leaves
        • Slow growth

        Signs of Underwatering:
        • Crispy, dry leaf edges
        • Wilting that improves after watering
        • Soil pulling away from pot sides

        Consider using the Watering tab to track your schedule.
        """
    }

    private func buildLightResponse(plant: Plant) -> String {
        """
        Light Considerations for \(plant.stage.displayName):

        General Guidelines:
        • Seedling: 18-24 inches from light, lower intensity
        • Vegetative: 18-24 inches, moderate-high intensity
        • Flowering: 12-18 inches, high intensity (watch for stress)

        Signs of Too Much Light:
        • Leaf curling or "taco-ing"
        • Bleaching (pale or white spots)
        • Burnt tips

        Signs of Too Little Light:
        • Stretching (long internodes)
        • Pale green color
        • Slow growth

        Measure light intensity at canopy height if possible.
        """
    }

    private func buildPestResponse(plant: Plant) -> String {
        """
        Pest Inspection Checklist:

        Where to Look:
        • Undersides of leaves (most common hiding spot)
        • New growth and flower sites
        • Soil surface
        • Leaf stems and petioles

        Common Pests:
        • Spider mites: tiny dots, webbing
        • Aphids: small insects on new growth
        • Fungus gnats: flies around soil
        • Thrips: tiny insects, silvery damage

        Immediate Actions:
        • Isolate affected plants if possible
        • Increase air circulation
        • Monitor daily for spread
        • Document with photos

        For specific treatment, identify the pest type first.
        """
    }

    private func buildNutrientResponse(plant: Plant) -> String {
        """
        Nutrient Guidelines for \(plant.stage.displayName):

        General Tips:
        • Start with lower doses than recommended
        • Increase gradually based on plant response
        • Monitor for signs of deficiency or burn
        • Keep track in your diary

        Signs of Nutrient Burn:
        • Brown, crispy leaf tips
        • "Clawing" of leaves
        • Dark green, almost glossy leaves

        Signs of Deficiency:
        • Yellowing (nitrogen)
        • Purple stems (phosphorus)
        • Brown spots (calcium, potassium)

        Remember: less is often more with nutrients.
        """
    }

    private func buildGeneralResponse(plant: Plant) -> String {
        """
        Plant Overview for \(plant.name):

        Current Status:
        • Stage: \(plant.stage.displayName)
        • Age: Day \(plant.ageInDays)
        """ + (plant.potSizeLiters != nil ? "\n• Pot Size: \(String(format: "%.1f", plant.potSizeLiters!))L" : "") +
        (plant.substrateType != nil ? "\n• Substrate: \(plant.substrateType!.displayName)" : "") +
        """


        General Care Reminders:
        • Use the Diagnostics tab to check plant health
        • Log events in the Diary for tracking
        • Monitor watering schedule
        • Take photos to track progress

        What specific concern do you have about your plant?
        """
    }
}
