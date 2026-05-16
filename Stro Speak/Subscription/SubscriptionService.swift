import Foundation
import StoreKit
import Combine

enum SubscriptionPurchaseResult {
    case success
    case userCanceled
    case pending
    case failed(Error)
}

@MainActor
final class SubscriptionService: ObservableObject {
    static let shared = SubscriptionService()

    @Published private(set) var products: [Product] = []
    @Published private(set) var activeTier: SubscriptionTier = .free
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var lastError: String?

    private var transactionListener: Task<Void, Never>?

    init() {
        transactionListener = Task.detached(priority: .background) { [weak self] in
            for await update in Transaction.updates {
                await self?.handle(transactionResult: update)
            }
        }
        Task { await self.refresh() }
    }

    deinit {
        transactionListener?.cancel()
    }

    /// Load product metadata + current entitlements.
    func refresh() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }

        do {
            let loaded = try await Product.products(for: SubscriptionProductID.all)
            // Stable ordering: monthly first, then yearly.
            products = SubscriptionProductID.all.compactMap { id in
                loaded.first { $0.id == id }
            }
        } catch {
            lastError = "Could not load subscription options: \(error.localizedDescription)"
        }

        await refreshEntitlements()
    }

    func refreshEntitlements() async {
        var newTier: SubscriptionTier = .free
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.revocationDate == nil,
               !(transaction.isUpgraded),
               let tier = SubscriptionProductID.tier(for: transaction.productID) {
                // Yearly outranks monthly if both somehow present.
                if tier == .proYearly || newTier == .free {
                    newTier = tier
                }
            }
        }
        if newTier != activeTier {
            activeTier = newTier
            Analytics.capture("subscription_tier_changed", properties: ["tier": newTier.rawValue])
        }
    }

    func purchase(productID: String) async -> SubscriptionPurchaseResult {
        guard let product = products.first(where: { $0.id == productID }) else {
            await refresh()
            guard let product = products.first(where: { $0.id == productID }) else {
                return .failed(NSError(
                    domain: "Subscription",
                    code: 404,
                    userInfo: [NSLocalizedDescriptionKey: "Product not available."]
                ))
            }
            return await purchase(product: product)
        }
        return await purchase(product: product)
    }

    private func purchase(product: Product) async -> SubscriptionPurchaseResult {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                await handle(transactionResult: verification)
                return .success
            case .userCancelled:
                return .userCanceled
            case .pending:
                return .pending
            @unknown default:
                return .failed(NSError(domain: "Subscription", code: -1))
            }
        } catch {
            lastError = error.localizedDescription
            return .failed(error)
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            lastError = "Restore failed: \(error.localizedDescription)"
        }
    }

    func manageSubscriptionsURL() -> URL? {
        URL(string: "https://apps.apple.com/account/subscriptions")
    }

    func product(for tier: SubscriptionTier) -> Product? {
        switch tier {
        case .proMonthly: return products.first { $0.id == SubscriptionProductID.proMonthly }
        case .proYearly: return products.first { $0.id == SubscriptionProductID.proYearly }
        case .free: return nil
        }
    }

    private func handle(transactionResult: VerificationResult<Transaction>) async {
        switch transactionResult {
        case .verified(let transaction):
            await transaction.finish()
            await refreshEntitlements()
        case .unverified(_, let error):
            lastError = "Transaction could not be verified: \(error.localizedDescription)"
        }
    }
}
