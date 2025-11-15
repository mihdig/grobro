import Foundation

/// Service responsible for generating debug console responses.
///
/// This is a stub aligned with the AI architecture. It can later be
/// wired to a real LLM endpoint and RAG pipeline.
final class DebugAssistantService {
    struct Context {
        let plant: Plant
        let recentEvents: [Event]
        let latestDiagnostics: DiagnosticsResult?
    }

    enum Mode {
        case limitedOffline
        case aiBacked
    }

    func respond(to userMessage: String, context: Context, mode: Mode) async -> String {
        switch mode {
        case .limitedOffline:
            return makeRuleBasedResponse(userMessage: userMessage, context: context)
        case .aiBacked:
            // TODO: call external LLM with safe, anonymized context.
            return makeRuleBasedResponse(userMessage: userMessage, context: context)
        }
    }

    private func makeRuleBasedResponse(userMessage: String, context: Context) -> String {
        var lines: [String] = []
        lines.append("Let's look at your plant step by step.")
        lines.append("")

        lines.append("1. Check the basics:")
        lines.append("- Confirm soil moisture (not soaking, not bone dry).")
        lines.append("- Confirm light distance is not extreme for the current stage.")

        if let latest = context.latestDiagnostics {
            lines.append("")
            lines.append("2. Recent diagnostics snapshot:")
            lines.append("- Hydration: \(describe(latest.hydrationStatus))")
            lines.append("- Light stress: \(describe(latest.lightStressStatus))")
            lines.append("- Leaf condition: \(describe(latest.leafConditionStatus))")
            lines.append("- Pests: \(describe(latest.pestsStatus))")
        }

        lines.append("")
        lines.append("3. Observe over the next few days and avoid drastic changes unless you see rapid worsening.")
        return lines.joined(separator: "\n")
    }

    private func describe(_ status: HydrationStatus) -> String {
        switch status {
        case .unknown: return "unclear"
        case .normal: return "looks normal"
        case .possibleOverwatering: return "possible overwatering"
        case .possibleUnderwatering: return "possible underwatering"
        }
    }

    private func describe(_ status: LightStressStatus) -> String {
        switch status {
        case .unknown: return "unclear"
        case .none: return "no obvious light stress"
        case .possible: return "possible light stress"
        }
    }

    private func describe(_ status: LeafConditionStatus) -> String {
        switch status {
        case .unknown: return "unclear"
        case .normal: return "looks normal"
        case .chlorosis: return "general yellowing (chlorosis)"
        case .spots: return "visible spots"
        case .necrosis: return "dead/necrotic tissue"
        }
    }

    private func describe(_ status: PestsStatus) -> String {
        switch status {
        case .unknown: return "unclear"
        case .notObvious: return "no obvious pests"
        case .possible: return "possible pests – inspect undersides of leaves closely"
        }
    }
}

