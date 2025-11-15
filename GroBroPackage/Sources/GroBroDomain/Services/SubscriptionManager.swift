import Foundation
import StoreKit

/// Manages StoreKit 2 subscription purchases and transaction verification
@available(iOS 17.0, macOS 14.0, *)
@MainActor
@Observable
public final class SubscriptionManager {

    // MARK: - Product IDs

    /// Pro subscription product ID (configure in App Store Connect)
    public static let proSubscriptionID = "com.grobro.pro.monthly"

    // MARK: - Published State

    /// Available subscription products loaded from the App Store
    public private(set) var products: [Product] = []

    /// Current active subscription status
    public private(set) var subscriptionStatus: SubscriptionStatus = .notSubscribed

    /// Loading state for UI feedback
    public private(set) var isLoading = false

    /// Last error encountered
    public private(set) var lastError: SubscriptionError?

    // MARK: - Transaction Monitoring

    @ObservationIgnored
    private var transactionUpdateTask: Task<Void, Never>?

    // MARK: - Initialization

    public init() {
        // Start monitoring for transaction updates
        startTransactionListener()
    }

    deinit {
        transactionUpdateTask?.cancel()
    }

    // MARK: - Product Loading

    /// Load available subscription products from the App Store
    public func loadProducts() async {
        isLoading = true
        lastError = nil

        do {
            let productIDs = [Self.proSubscriptionID]
            let loadedProducts = try await Product.products(for: Set(productIDs))
            products = loadedProducts.sorted { $0.price < $1.price }

            // Check current subscription status after loading products
            await checkSubscriptionStatus()
        } catch {
            lastError = .productLoadFailed(error)
            products = []
        }

        isLoading = false
    }

    // MARK: - Purchase Flow

    /// Purchase a subscription product
    /// - Parameter product: The subscription product to purchase
    /// - Returns: True if purchase succeeded, false otherwise
    @discardableResult
    public func purchase(_ product: Product) async -> Bool {
        isLoading = true
        lastError = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                // Verify the transaction
                let transaction = try checkVerified(verification)

                // Update subscription status
                await checkSubscriptionStatus()

                // Finish the transaction
                await transaction.finish()

                isLoading = false
                return true

            case .userCancelled:
                lastError = .purchaseCancelled
                isLoading = false
                return false

            case .pending:
                lastError = .purchasePending
                isLoading = false
                return false

            @unknown default:
                lastError = .unknownPurchaseResult
                isLoading = false
                return false
            }
        } catch {
            lastError = .purchaseFailed(error)
            isLoading = false
            return false
        }
    }

    // MARK: - Restore Purchases

    /// Restore previously purchased subscriptions
    /// - Returns: True if restore succeeded and active subscription found
    @discardableResult
    public func restorePurchases() async -> Bool {
        isLoading = true
        lastError = nil

        do {
            // Request App Store to sync latest transactions
            try await AppStore.sync()

            // Check subscription status after sync
            await checkSubscriptionStatus()

            isLoading = false
            return subscriptionStatus.isPro
        } catch {
            lastError = .restoreFailed(error)
            isLoading = false
            return false
        }
    }

    // MARK: - Subscription Status Checking

    /// Check current subscription status by examining active entitlements
    public func checkSubscriptionStatus() async {
        // Check all current entitlements for active subscription
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                // Check if this is our Pro subscription
                if transaction.productID == Self.proSubscriptionID {
                    // Subscription is active
                    if let expirationDate = transaction.expirationDate {
                        if expirationDate > Date() {
                            subscriptionStatus = .active(expirationDate: expirationDate)
                        } else {
                            subscriptionStatus = .expired(expirationDate: expirationDate)
                        }
                    } else {
                        // No expiration date means lifetime or active without end
                        subscriptionStatus = .active(expirationDate: nil)
                    }
                    return
                }
            } catch {
                lastError = .verificationFailed(error)
            }
        }

        // No active subscription found
        subscriptionStatus = .notSubscribed
    }

    // MARK: - Transaction Verification

    /// Verify a transaction result is valid and not tampered with
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified(_, let error):
            throw SubscriptionError.verificationFailed(error)
        }
    }

    // MARK: - Transaction Listener

    /// Start listening for transaction updates in the background
    private func startTransactionListener() {
        transactionUpdateTask = Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self = self else { return }

                do {
                    let transaction = try await self.checkVerified(result)

                    // Update subscription status on main actor
                    await self.checkSubscriptionStatus()

                    // Finish the transaction
                    await transaction.finish()
                } catch {
                    // Log verification failure but continue listening
                    await MainActor.run {
                        self.lastError = .verificationFailed(error)
                    }
                }
            }
        }
    }
}

// MARK: - Subscription Status

public enum SubscriptionStatus: Equatable {
    case notSubscribed
    case active(expirationDate: Date?)
    case expired(expirationDate: Date)
    case gracePeriod(expirationDate: Date)
    case billingRetry(expirationDate: Date)

    /// True if user has active Pro subscription
    public var isPro: Bool {
        switch self {
        case .active, .gracePeriod, .billingRetry:
            return true
        case .notSubscribed, .expired:
            return false
        }
    }

    /// User-friendly status description
    public var description: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none

        switch self {
        case .notSubscribed:
            return "Free Plan"
        case .active(let expirationDate):
            if let date = expirationDate {
                return "Pro (renews \(dateFormatter.string(from: date)))"
            } else {
                return "Pro Plan"
            }
        case .expired(let expirationDate):
            return "Pro Expired (\(dateFormatter.string(from: expirationDate)))"
        case .gracePeriod(let expirationDate):
            return "Pro (grace period until \(dateFormatter.string(from: expirationDate)))"
        case .billingRetry(let expirationDate):
            return "Pro (billing issue - renews \(dateFormatter.string(from: expirationDate)))"
        }
    }
}

// MARK: - Errors

public enum SubscriptionError: Error, LocalizedError {
    case productLoadFailed(Error)
    case purchaseFailed(Error)
    case purchaseCancelled
    case purchasePending
    case unknownPurchaseResult
    case verificationFailed(Error)
    case restoreFailed(Error)

    public var errorDescription: String? {
        switch self {
        case .productLoadFailed(let error):
            return "Failed to load subscription products: \(error.localizedDescription)"
        case .purchaseFailed(let error):
            return "Purchase failed: \(error.localizedDescription)"
        case .purchaseCancelled:
            return "Purchase was cancelled"
        case .purchasePending:
            return "Purchase is pending approval"
        case .unknownPurchaseResult:
            return "Unknown purchase result"
        case .verificationFailed(let error):
            return "Transaction verification failed: \(error.localizedDescription)"
        case .restoreFailed(let error):
            return "Failed to restore purchases: \(error.localizedDescription)"
        }
    }
}
