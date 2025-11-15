import Foundation
import GroBroDomain

@MainActor
public final class DebugConsoleViewModel: ObservableObject {
    @Published public var messages: [DebugMessage] = []
    @Published public var currentInput: String = ""
    @Published public var isProcessing: Bool = false
    @Published public var mode: DebugAssistantMode = .offline

    public let plant: Plant
    private let debugAssistant: DebugAssistantService

    public var canSend: Bool {
        !currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isProcessing
    }

    public init(plant: Plant, debugAssistant: DebugAssistantService = DebugAssistantService()) {
        self.plant = plant
        self.debugAssistant = debugAssistant

        // Add welcome message
        messages.append(DebugMessage(
            plantId: plant.id,
            isUserMessage: false,
            content: """
            Hi! I'm here to help you understand what's happening with \(plant.name).

            You can ask me about watering, nutrients, light, pests, or any concerns you have. I'll do my best to provide helpful suggestions.

            Note: I'm not a replacement for professional advice, and I won't give consumption-related guidance. My goal is to help you understand your plant's health.
            """
        ))
    }

    /// Sends the current input as a user message and gets a response
    public func sendMessage() async {
        guard canSend else { return }

        let userQuery = currentInput.trimmingCharacters(in: .whitespacesAndNewlines)

        // Add user message
        let userMessage = DebugMessage(
            plantId: plant.id,
            isUserMessage: true,
            content: userQuery
        )
        messages.append(userMessage)

        // Clear input
        currentInput = ""
        isProcessing = true

        do {
            // Get response from debug assistant
            let response = try await debugAssistant.sendQuery(userQuery, for: plant)

            // Update mode
            mode = debugAssistant.mode

            // Add assistant response
            let assistantMessage = DebugMessage(
                plantId: plant.id,
                isUserMessage: false,
                content: response
            )
            messages.append(assistantMessage)

        } catch {
            // Add error message
            let errorMessage = DebugMessage(
                plantId: plant.id,
                isUserMessage: false,
                content: "I'm sorry, I encountered an error: \(error.localizedDescription)"
            )
            messages.append(errorMessage)
        }

        isProcessing = false
    }

    /// Clears all messages except the welcome message
    public func clearHistory() {
        messages = [messages.first!]
    }
}
