import SwiftUI
import StoreKit
import GroBroDomain

/// Main upgrade screen showcasing Pro features with purchase flow
@available(iOS 18.0, macOS 15.0, *)
public struct UpgradeToProView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(ProEntitlementManager.self) private var proManager

    @State private var viewModel: UpgradeToProViewModel
    @State private var showSuccessAnimation = false

    public init() {
        self._viewModel = State(initialValue: UpgradeToProViewModel())
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                // Main content
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        headerSection

                        // Feature comparison
                        featureComparisonSection

                        // Pricing and CTA
                        pricingSection

                        // Footer info
                        footerSection
                    }
                    .padding()
                }
                .opacity(showSuccessAnimation ? 0 : 1)

                // Success celebration overlay
                if showSuccessAnimation {
                    successOverlay
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .alert("Purchase Error", isPresented: Binding(
                get: { viewModel.showError },
                set: { _ in }
            )) {
                Button("Try Again") {
                    Task {
                        await viewModel.retryPurchase()
                    }
                }
                Button("Cancel", role: .cancel) {
                    viewModel.clearError()
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
            .task {
                await viewModel.loadProducts()
            }
            .onChange(of: viewModel.purchaseSucceeded) { _, succeeded in
                if succeeded {
                    showSuccessAnimation = true
                    // Auto-dismiss after 2 seconds
                    Task {
                        try? await Task.sleep(for: .seconds(2))
                        await proManager.refreshProStatus(force: true)
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "crown.fill")
                .font(.system(size: 72))
                .foregroundStyle(
                    .linearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Upgrade to GroBro Pro")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("Unlock your garden's full potential")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }

    // MARK: - Feature Comparison Section

    private var featureComparisonSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("What's Included")
                .font(.title2)
                .fontWeight(.bold)

            ProFeatureCard(
                icon: "infinity.circle.fill",
                iconColor: .green,
                title: "Track Unlimited Plants",
                description: "No more limits - grow your garden as large as you want"
            )

            ProFeatureCard(
                icon: "chart.line.uptrend.xyaxis.circle.fill",
                iconColor: .blue,
                title: "Advanced Analytics",
                description: "Deep insights into growth patterns, health trends, and optimization tips"
            )

            ProFeatureCard(
                icon: "square.and.arrow.up.circle.fill",
                iconColor: .purple,
                title: "Export Your Data",
                description: "Download your complete plant history in CSV or JSON format"
            )

            ProFeatureCard(
                icon: "headphones.circle.fill",
                iconColor: .orange,
                title: "Priority Support",
                description: "Get expert help from the GroBro team within 24 hours"
            )
        }
    }

    // MARK: - Pricing Section

    private var pricingSection: some View {
        VStack(spacing: 16) {
            if let product = viewModel.proProduct {
                VStack(spacing: 8) {
                    // Price display
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(product.displayPrice)
                            .font(.system(size: 48, weight: .bold))
                        Text(pricingPeriod(for: product))
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }

                    // Free trial info if available
                    if let trialInfo = freeTrialInfo(for: product) {
                        Text(trialInfo)
                            .font(.subheadline)
                            .foregroundStyle(.green)
                            .fontWeight(.semibold)
                    }
                }
                .padding(.vertical, 12)

                // Purchase button
                Button {
                    Task {
                        await viewModel.purchaseProduct()
                    }
                } label: {
                    HStack(spacing: 8) {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(viewModel.isLoading ? "Processing..." : ctaButtonText(for: product))
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(viewModel.isLoading)

            } else if viewModel.isLoading {
                ProgressView("Loading subscription options...")
                    .frame(height: 56)
            } else {
                // Error state
                VStack(spacing: 12) {
                    Text("Unable to load subscription")
                        .foregroundStyle(.secondary)
                    Button("Retry") {
                        Task {
                            await viewModel.loadProducts()
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .frame(height: 56)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        VStack(spacing: 8) {
            Text("Subscription automatically renews unless cancelled")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Link("Terms of Service", destination: URL(string: "https://grobro.app/terms")!)
                Text("•")
                    .foregroundStyle(.secondary)
                Link("Privacy Policy", destination: URL(string: "https://grobro.app/privacy")!)
            }
            .font(.caption)
            .foregroundStyle(.blue)
        }
        .padding(.bottom, 20)
    }

    // MARK: - Success Overlay

    private var successOverlay: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 100))
                .foregroundStyle(.green)
                .scaleEffect(showSuccessAnimation ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showSuccessAnimation)

            Text("Welcome to Pro!")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("You now have unlimited access to all Pro features")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }

    // MARK: - Helper Methods

    private func pricingPeriod(for product: Product) -> String {
        guard let subscription = product.subscription else { return "" }

        switch subscription.subscriptionPeriod.unit {
        case .day:
            return "/day"
        case .week:
            return "/week"
        case .month:
            return "/month"
        case .year:
            return "/year"
        @unknown default:
            return ""
        }
    }

    private func freeTrialInfo(for product: Product) -> String? {
        guard let introOffer = product.subscription?.introductoryOffer,
              introOffer.paymentMode == .freeTrial else {
            return nil
        }

        let period = introOffer.period
        let value = period.value
        let unit: String

        switch period.unit {
        case .day:
            unit = value == 1 ? "day" : "days"
        case .week:
            unit = value == 1 ? "week" : "weeks"
        case .month:
            unit = value == 1 ? "month" : "months"
        case .year:
            unit = value == 1 ? "year" : "years"
        @unknown default:
            unit = "period"
        }

        return "Start \(value)-\(unit) free trial"
    }

    private func ctaButtonText(for product: Product) -> String {
        if product.subscription?.introductoryOffer?.paymentMode == .freeTrial {
            return "Start Free Trial"
        } else {
            return "Upgrade to Pro"
        }
    }
}

// MARK: - Pro Feature Card

@available(iOS 18.0, macOS 15.0, *)
struct ProFeatureCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(iconColor)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(Color(red: 0.95, green: 0.95, blue: 0.95))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}

// MARK: - View Model

@available(iOS 18.0, macOS 15.0, *)
@MainActor
@Observable
final class UpgradeToProViewModel {

    private let subscriptionManager = SubscriptionManager()

    var proProduct: Product?
    var isLoading = false
    var errorMessage: String?
    var purchaseSucceeded = false

    private var lastProduct: Product?

    var showError: Bool {
        errorMessage != nil
    }

    func loadProducts() async {
        isLoading = true
        await subscriptionManager.loadProducts()
        proProduct = subscriptionManager.products.first
        isLoading = false
    }

    func purchaseProduct() async {
        guard let product = proProduct else {
            errorMessage = "Unable to load subscription product. Please try again."
            return
        }

        lastProduct = product
        isLoading = true

        let success = await subscriptionManager.purchase(product)
        isLoading = false

        if success {
            purchaseSucceeded = true
        } else {
            handlePurchaseError()
        }
    }

    func retryPurchase() async {
        guard let product = lastProduct else {
            await loadProducts()
            return
        }

        isLoading = true
        let success = await subscriptionManager.purchase(product)
        isLoading = false

        if success {
            purchaseSucceeded = true
            errorMessage = nil
        } else {
            handlePurchaseError()
        }
    }

    func clearError() {
        errorMessage = nil
    }

    private func handlePurchaseError() {
        guard let error = subscriptionManager.lastError else {
            errorMessage = "An unknown error occurred. Please try again."
            return
        }

        switch error {
        case .purchaseCancelled:
            // User cancelled, don't show error
            errorMessage = nil
        case .purchasePending:
            errorMessage = "Your purchase is pending approval. Please check back later."
        case .purchaseFailed(let underlyingError):
            errorMessage = "Purchase failed: \(underlyingError.localizedDescription)\n\nPlease check your payment method and try again."
        case .verificationFailed:
            errorMessage = "Unable to verify purchase. Please try again or contact support."
        case .productLoadFailed:
            errorMessage = "Unable to load subscription information. Please check your network connection."
        default:
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Preview

@available(iOS 18.0, macOS 15.0, *)
#Preview {
    UpgradeToProView()
        .environment(ProEntitlementManager())
}
