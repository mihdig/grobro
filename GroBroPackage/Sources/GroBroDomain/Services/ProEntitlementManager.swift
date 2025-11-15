import Foundation
import SwiftUI

/// Manages Pro subscription entitlements and provides app-wide access to subscription status
@available(iOS 17.0, macOS 14.0, *)
@MainActor
@Observable
public final class ProEntitlementManager {

    // MARK: - Constants

    /// Maximum plants allowed for Free tier
    public static let freeTierPlantLimit = 3

    // MARK: - Services

    private let subscriptionManager: SubscriptionManager
    private let userDefaults: UserDefaults

    // MARK: - Cached State

    /// Current Pro subscription status
    public internal(set) var isPro: Bool = false

    /// Subscription status details
    public var subscriptionStatus: SubscriptionStatus {
        subscriptionManager.subscriptionStatus
    }

    /// Last time Pro status was verified with App Store
    public private(set) var lastVerificationDate: Date?

    // MARK: - Keys

    private let isProCacheKey = "com.grobro.isPro.cached"
    private let lastVerificationKey = "com.grobro.lastVerification"

    // MARK: - Initialization

    public init(
        subscriptionManager: SubscriptionManager = SubscriptionManager(),
        userDefaults: UserDefaults = .standard
    ) {
        self.subscriptionManager = subscriptionManager
        self.userDefaults = userDefaults

        // Load cached Pro status
        self.isPro = userDefaults.bool(forKey: isProCacheKey)
        self.lastVerificationDate = userDefaults.object(forKey: lastVerificationKey) as? Date
    }

    // MARK: - Pro Status Management

    /// Refresh Pro status from StoreKit
    /// - Parameter force: If true, always check with App Store. If false, may use cached value if recent.
    public func refreshProStatus(force: Bool = false) async {
        // If not forcing and we have a recent verification (within last hour), use cache
        if !force,
           let lastVerification = lastVerificationDate,
           Date().timeIntervalSince(lastVerification) < 3600 {
            return
        }

        // Check subscription status from StoreKit
        await subscriptionManager.checkSubscriptionStatus()

        // Update cached Pro status
        let newProStatus = subscriptionManager.subscriptionStatus.isPro
        if newProStatus != isPro {
            isPro = newProStatus
            userDefaults.set(isPro, forKey: isProCacheKey)
        }

        // Update last verification timestamp
        lastVerificationDate = Date()
        userDefaults.set(lastVerificationDate, forKey: lastVerificationKey)
    }

    /// Start periodic background refresh of Pro status
    public func startBackgroundRefresh() {
        Task {
            // Initial refresh
            await refreshProStatus(force: true)

            // Schedule periodic refresh every hour
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(3600))
                await refreshProStatus(force: true)
            }
        }
    }

    // MARK: - Plant Limit Checking

    /// Check if user can create another plant
    /// - Parameter currentPlantCount: Current number of non-archived plants
    /// - Returns: True if user can create more plants
    public func canCreatePlant(currentPlantCount: Int) -> Bool {
        if isPro {
            return true
        } else {
            return currentPlantCount < Self.freeTierPlantLimit
        }
    }

    /// Get remaining plants available in Free tier
    /// - Parameter currentPlantCount: Current number of non-archived plants
    /// - Returns: Number of plants remaining, or nil if Pro
    public func remainingFreePlants(currentPlantCount: Int) -> Int? {
        if isPro {
            return nil  // Unlimited for Pro
        } else {
            return max(0, Self.freeTierPlantLimit - currentPlantCount)
        }
    }

    // MARK: - Feature Gating

    /// Check if a Pro feature is available
    /// - Parameter feature: The Pro feature to check
    /// - Returns: True if user has access to this feature
    public func hasAccess(to feature: ProFeature) -> Bool {
        switch feature {
        case .unlimitedPlants:
            return isPro
        case .advancedAnalytics:
            return isPro
        case .dataExport:
            return isPro
        case .prioritySupport:
            return isPro
        }
    }

    /// Get user-friendly status message for UI display
    public var statusMessage: String {
        if isPro {
            return "GroBro Pro • Unlimited Plants"
        } else {
            return "GroBro Free • Limited to 3 Plants"
        }
    }
}

// MARK: - Pro Features

public enum ProFeature {
    case unlimitedPlants
    case advancedAnalytics
    case dataExport
    case prioritySupport

    public var displayName: String {
        switch self {
        case .unlimitedPlants:
            return "Unlimited Plants"
        case .advancedAnalytics:
            return "Advanced Analytics"
        case .dataExport:
            return "Data Export"
        case .prioritySupport:
            return "Priority Support"
        }
    }

    public var description: String {
        switch self {
        case .unlimitedPlants:
            return "Create and manage unlimited plants in your garden"
        case .advancedAnalytics:
            return "Access detailed growth analytics and insights"
        case .dataExport:
            return "Export your plant data in multiple formats"
        case .prioritySupport:
            return "Get priority email support from the GroBro team"
        }
    }
}

// MARK: - Environment Key

@available(iOS 17.0, macOS 14.0, *)
public struct ProEntitlementManagerKey: EnvironmentKey {
    public static let defaultValue: ProEntitlementManager = {
        // Create default value on main actor
        MainActor.assumeIsolated {
            ProEntitlementManager()
        }
    }()
}

@available(iOS 17.0, macOS 14.0, *)
extension EnvironmentValues {
    public var proEntitlementManager: ProEntitlementManager {
        get { self[ProEntitlementManagerKey.self] }
        set { self[ProEntitlementManagerKey.self] = newValue }
    }
}
