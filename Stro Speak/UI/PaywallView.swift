import SwiftUI
import StoreKit

struct PaywallView: View {
    @ObservedObject var subscription: SubscriptionService
    var onDismiss: (() -> Void)? = nil

    @State private var purchaseError: String?
    @State private var inFlightProductID: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Upgrade to Stro Speak Pro")
                    .font(.title3.weight(.semibold))
                Text("Unlimited dictation, screen-context cleanup, and priority transcription models.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 10) {
                tierRow(.proYearly, highlight: true)
                tierRow(.proMonthly, highlight: false)
            }

            VStack(alignment: .leading, spacing: 4) {
                bullet("Unlimited monthly transcription (fair-use 30 audio-hours)")
                bullet("Screen-aware cleanup with the strongest models")
                bullet("Cancel anytime in App Store account settings")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if let purchaseError {
                Text(purchaseError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack {
                Button("Restore Purchases") {
                    Task { await subscription.restorePurchases() }
                }
                .buttonStyle(.link)
                Spacer()
                if let onDismiss {
                    Button("Not now", action: onDismiss)
                        .buttonStyle(.borderless)
                }
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            if subscription.products.isEmpty {
                Task { await subscription.refresh() }
            }
        }
    }

    @ViewBuilder
    private func tierRow(_ tier: SubscriptionTier, highlight: Bool) -> some View {
        let product = subscription.product(for: tier)
        let title = tier.displayName
        let price = product?.displayPrice ?? tier.priceLabel
        let isLoading = inFlightProductID == productID(for: tier)

        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title).font(.headline)
                    if highlight {
                        Text("BEST VALUE")
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.18), in: Capsule())
                            .foregroundStyle(Color.accentColor)
                    }
                }
                Text(product?.description ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(price)
                    .font(.headline)
                Button {
                    purchase(tier)
                } label: {
                    if isLoading {
                        ProgressView().controlSize(.small)
                    } else {
                        Text(subscription.activeTier == tier ? "Current" : "Subscribe")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading || subscription.activeTier == tier || product == nil)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(highlight ? Color.accentColor.opacity(0.08) : Color.secondary.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(highlight ? Color.accentColor.opacity(0.5) : Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text("•")
            Text(text)
        }
    }

    private func productID(for tier: SubscriptionTier) -> String? {
        switch tier {
        case .proMonthly: return SubscriptionProductID.proMonthly
        case .proYearly: return SubscriptionProductID.proYearly
        case .free: return nil
        }
    }

    private func purchase(_ tier: SubscriptionTier) {
        guard let id = productID(for: tier) else { return }
        inFlightProductID = id
        purchaseError = nil
        Task {
            let result = await subscription.purchase(productID: id)
            inFlightProductID = nil
            switch result {
            case .success:
                onDismiss?()
            case .userCanceled:
                break
            case .pending:
                purchaseError = "Purchase pending — finish in App Store and reopen."
            case .failed(let err):
                purchaseError = err.localizedDescription
            }
        }
    }
}
