import Foundation

// MARK: - Pricing model
//
// Cost basis (audio transcription dominates; LLM cleanup ≤ ~$0.30/heavy-user/mo):
//   * Groq whisper-large-v3-turbo : $0.04 / audio-hour  = $0.000667 / min
//   * OpenAI Whisper              : $0.36 / audio-hour  = $0.006    / min
//   * Blended worst-case          : ~$0.005 / min
//
// Tiers:
//   Free  — 60 audio-min / month.
//           Worst-case COGS ~$0.30 / free user. Loss-leader for activation.
//
//   Pro Monthly — $4.99 / month. Soft fair-use cap: 30 audio-hours / month.
//           Median Pro user (~5 hrs/mo) costs ~$1.50 → ~70% margin.
//           Heavy Pro user (~14 hrs/mo) costs ~$4.20 → 50% margin floor.
//           Above 14 hrs the user is paying their own COGS; soft cap kicks
//           in only at 30 hrs to keep the experience "unlimited" for 99%.
//
//   Pro Yearly — $49.99 / year (~$4.17 / month, ~16% discount).
//           Same usage envelope as monthly; trades unit margin for retention
//           and reduced churn / payment-processor fees.
//
// "AI cost + 50% margin" is enforced at the median + heavy-tail by Pro pricing,
// and at the catalog level by capping free-tier minutes.

enum SubscriptionTier: String, CaseIterable, Identifiable, Codable {
    case free
    case proMonthly
    case proYearly

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .proMonthly: return "Pro (Monthly)"
        case .proYearly: return "Pro (Yearly)"
        }
    }

    var priceLabel: String {
        switch self {
        case .free: return "Free"
        case .proMonthly: return "$4.99 / month"
        case .proYearly: return "$49.99 / year"
        }
    }

    /// Audio seconds allowed per calendar month. `nil` = effectively unlimited
    /// (subject to a high soft cap enforced by `softCapAudioSeconds`).
    var monthlyAudioSecondsLimit: Int? {
        switch self {
        case .free: return 60 * 60                  // 60 minutes
        case .proMonthly, .proYearly: return nil
        }
    }

    /// Fair-use ceiling for "unlimited" tiers, in seconds.
    var softCapAudioSeconds: Int {
        30 * 60 * 60                                // 30 audio-hours
    }

    var isPaid: Bool {
        switch self {
        case .free: return false
        case .proMonthly, .proYearly: return true
        }
    }

    static let pro: [SubscriptionTier] = [.proMonthly, .proYearly]
}

enum SubscriptionProductID {
    static let proMonthly = "siro.company.strospeak.pro.monthly"
    static let proYearly = "siro.company.strospeak.pro.yearly"

    static let all: [String] = [proMonthly, proYearly]

    static func tier(for productID: String) -> SubscriptionTier? {
        switch productID {
        case proMonthly: return .proMonthly
        case proYearly: return .proYearly
        default: return nil
        }
    }
}
