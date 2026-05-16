import Foundation
import Combine

@MainActor
final class UsageTracker: ObservableObject {
    static let shared = UsageTracker()

    private static let periodKey = "usage_period_v1"          // e.g. "2026-05"
    private static let secondsKey = "usage_seconds_v1"        // seconds in current period

    @Published private(set) var currentPeriod: String
    @Published private(set) var secondsUsedThisPeriod: Int

    init() {
        let nowPeriod = Self.periodString(for: Date())
        let storedPeriod = AppSettingsStorage.load(account: Self.periodKey)
        let storedSeconds = Int(AppSettingsStorage.load(account: Self.secondsKey) ?? "") ?? 0

        if storedPeriod == nowPeriod {
            self.currentPeriod = nowPeriod
            self.secondsUsedThisPeriod = storedSeconds
        } else {
            self.currentPeriod = nowPeriod
            self.secondsUsedThisPeriod = 0
            AppSettingsStorage.save(nowPeriod, account: Self.periodKey)
            AppSettingsStorage.save("0", account: Self.secondsKey)
        }
    }

    func rolloverIfNeeded() {
        let nowPeriod = Self.periodString(for: Date())
        guard nowPeriod != currentPeriod else { return }
        currentPeriod = nowPeriod
        secondsUsedThisPeriod = 0
        AppSettingsStorage.save(nowPeriod, account: Self.periodKey)
        AppSettingsStorage.save("0", account: Self.secondsKey)
    }

    func record(seconds: Int) {
        guard seconds > 0 else { return }
        rolloverIfNeeded()
        secondsUsedThisPeriod += seconds
        AppSettingsStorage.save(String(secondsUsedThisPeriod), account: Self.secondsKey)
        Analytics.capture("usage_recorded", properties: [
            "seconds": seconds,
            "period_total_seconds": secondsUsedThisPeriod,
        ])
    }

    func canStartNewSession(tier: SubscriptionTier) -> Bool {
        rolloverIfNeeded()
        if let limit = tier.monthlyAudioSecondsLimit {
            return secondsUsedThisPeriod < limit
        }
        return secondsUsedThisPeriod < tier.softCapAudioSeconds
    }

    func remainingSeconds(tier: SubscriptionTier) -> Int? {
        if let limit = tier.monthlyAudioSecondsLimit {
            return max(0, limit - secondsUsedThisPeriod)
        }
        return nil
    }

    func statusText(tier: SubscriptionTier) -> String {
        let usedMin = secondsUsedThisPeriod / 60
        if let limit = tier.monthlyAudioSecondsLimit {
            let limitMin = limit / 60
            return "\(usedMin) of \(limitMin) min used this month"
        }
        return "\(usedMin) min used this month (fair-use cap \(tier.softCapAudioSeconds / 3600) hr)"
    }

    private static func periodString(for date: Date) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC") ?? .current
        let c = cal.dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", c.year ?? 0, c.month ?? 0)
    }
}
