import SwiftUI
import StoreKit
import GroBroDomain

/// Modal prompt shown when Free user reaches plant limit
@available(iOS 17.0, macOS 14.0, *)
public struct UpgradePromptView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(ProEntitlementManager.self) private var proManager

    @State private var viewModel = UpgradePromptViewModel()

    public init() {}

    public var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header Icon
                Image(systemName: "leaf.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.green)
                    .padding(.top, 40)

                // Title and Message
                VStack(spacing: 12) {
                    Text("Upgrade to GroBro Pro")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("You've reached the Free plan limit of 3 plants.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Feature List
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(
                        icon: "infinity",
                        title: "Unlimited Plants",
                        description: "Create and manage as many plants as you want"
                    )

                    FeatureRow(
                        icon: "chart.xyaxis.line",
                        title: "Advanced Analytics",
                        description: "Track growth patterns and optimize your garden"
                    )

                    FeatureRow(
                        icon: "square.and.arrow.up",
                        title: "Data Export",
                        description: "Export your plant data anytime"
                    )

                    FeatureRow(
                        icon: "headphones",
                        title: "Priority Support",
                        description: "Get help from the GroBro team faster"
                    )
                }
                .padding(.horizontal)

                Spacer()

                // Price and CTA
                VStack(spacing: 16) {
                    if let product = viewModel.proProduct {
                        Text("\(product.displayPrice)/month")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }

                    Button {
                        Task {
                            await viewModel.upgradeToPro()
                        }
                    } label: {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Upgrade to Pro")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isLoading || viewModel.proProduct == nil)

                    Button("Maybe Later") {
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.showError },
                set: { _ in }
            )) {
                Button("OK") {}
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .task {
                await viewModel.loadProducts()
            }
            .onChange(of: viewModel.purchaseSucceeded) { _, succeeded in
                if succeeded {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Feature Row

@available(iOS 17.0, macOS 14.0, *)
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.green)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - View Model

@available(iOS 17.0, macOS 14.0, *)
@MainActor
@Observable
final class UpgradePromptViewModel {

    private let subscriptionManager = SubscriptionManager()
    private let proManager = ProEntitlementManager()

    var proProduct: Product?
    var isLoading = false
    var errorMessage: String?
    var purchaseSucceeded = false

    var showError: Bool {
        errorMessage != nil
    }

    func loadProducts() async {
        await subscriptionManager.loadProducts()
        proProduct = subscriptionManager.products.first
    }

    func upgradeToPro() async {
        guard let product = proProduct else {
            errorMessage = "Unable to load subscription product. Please try again."
            return
        }

        isLoading = true
        let success = await subscriptionManager.purchase(product)
        isLoading = false

        if success {
            // Refresh Pro status
            await proManager.refreshProStatus(force: true)
            purchaseSucceeded = true
        } else if let error = subscriptionManager.lastError {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Preview

#Preview {
    UpgradePromptView()
        .environment(ProEntitlementManager())
}
