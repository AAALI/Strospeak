import SwiftUI

struct AccountSectionView: View {
    @ObservedObject var auth: AuthenticationService
    @ObservedObject var subscription: SubscriptionService
    @ObservedObject var usage: UsageTracker

    @State private var showSignOutConfirm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let account = auth.currentAccount {
                signedInBlock(account)
                Divider()
                subscriptionBlock
                Divider()
                usageBlock
            } else {
                SignInView(auth: auth)
                Divider()
                subscriptionBlock
            }
        }
        .onAppear {
            Task {
                await subscription.refresh()
                usage.rolloverIfNeeded()
            }
        }
    }

    // MARK: - Sections

    private func signedInBlock(_ account: UserAccount) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: account.provider == .apple ? "apple.logo" : "envelope.fill")
                .font(.title2)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(account.displayLabel)
                    .font(.headline)
                Text(providerLabel(account.provider))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Sign Out") {
                showSignOutConfirm = true
            }
            .confirmationDialog(
                "Sign out of Stro Speak?",
                isPresented: $showSignOutConfirm,
                titleVisibility: .visible
            ) {
                Button("Sign Out", role: .destructive) { auth.signOut() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private var subscriptionBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Plan")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(subscription.activeTier.displayName)
                        .font(.headline)
                }
                Spacer()
                if subscription.activeTier.isPaid {
                    if let url = subscription.manageSubscriptionsURL() {
                        Button("Manage in App Store") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }
            }

            if !subscription.activeTier.isPaid {
                PaywallView(subscription: subscription)
            }

            if let lastError = subscription.lastError {
                Text(lastError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private var usageBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Usage")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(usage.statusText(tier: subscription.activeTier))
                .font(.callout)

            if let remaining = usage.remainingSeconds(tier: subscription.activeTier) {
                let limit = subscription.activeTier.monthlyAudioSecondsLimit ?? 1
                ProgressView(
                    value: Double(limit - remaining),
                    total: Double(limit)
                )
                .progressViewStyle(.linear)
            }

            Text("Period: \(usage.currentPeriod) (UTC). Resets on the 1st.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func providerLabel(_ provider: AuthProvider) -> String {
        switch provider {
        case .apple: return "Signed in with Apple"
        case .email: return "Signed in with email"
        }
    }
}
