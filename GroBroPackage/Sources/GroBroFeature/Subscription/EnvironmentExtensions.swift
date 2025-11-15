import SwiftUI
import GroBroDomain

// MARK: - Prompt Dismissal Tracker Environment

@available(iOS 17.0, macOS 14.0, *)
public struct PromptDismissalTrackerKey: EnvironmentKey {
    public static let defaultValue: PromptDismissalTracker = {
        MainActor.assumeIsolated {
            PromptDismissalTracker()
        }
    }()
}

@available(iOS 17.0, macOS 14.0, *)
extension EnvironmentValues {
    public var promptDismissalTracker: PromptDismissalTracker {
        get { self[PromptDismissalTrackerKey.self] }
        set { self[PromptDismissalTrackerKey.self] = newValue }
    }
}
