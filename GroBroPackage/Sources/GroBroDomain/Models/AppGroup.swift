import Foundation

/// Shared application group identifiers used for communication between the main app,
/// widgets, and future extensions.
public enum AppGroup {
    /// Primary app group identifier. Keep this value in sync with entitlements.
    public static let identifier = "group.com.pokrasote.grobro"

    /// Convenience accessor for the shared UserDefaults container. Falls back to the
    /// standard defaults when the app group has not been configured yet so preview
    /// builds and tests continue to function.
    public static var userDefaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }
}
