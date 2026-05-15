import AppKit
import Foundation
import PostHog

enum Analytics {
    private static let defaultPostHogProjectToken = "phc_ootgopx5ASmdiy4k2wk9tdQso9G2eR3VBenGRzqn5HmA"
    private static let defaultPostHogHost = "https://eu.i.posthog.com"
    private static let installationIdKey = "analytics_installation_id"
    private static var didConfigurePostHog = false

    static func configurePostHog() {
        guard !didConfigurePostHog else { return }
        didConfigurePostHog = true

        let config = PostHogConfig(
            projectToken: configuredValue(environmentKey: "POSTHOG_PROJECT_TOKEN", fallback: defaultPostHogProjectToken),
            host: configuredValue(environmentKey: "POSTHOG_HOST", fallback: defaultPostHogHost)
        )
        config.captureApplicationLifecycleEvents = true
        config.personProfiles = .always
        #if DEBUG
            config.debug = true
        #endif

        PostHogSDK.shared.setup(config)
        PostHogSDK.shared.identify(installationId, userProperties: commonProperties)
    }

    static func capture(_ event: String, properties: [String: Any]? = nil) {
        PostHogSDK.shared.capture(event, properties: mergedCommonProperties(properties))
    }

    static func captureAppOpened(source: String) {
        capture("app_opened", properties: [
            "source": source,
            "has_active_window": NSApp.windows.contains { $0.isVisible },
        ])
    }

    static func captureLLMTrace(traceId: String, name: String, feature: String) {
        capture("$ai_trace", properties: [
            "$ai_trace_id": traceId,
            "$ai_span_name": name,
            "feature": feature,
        ])
    }

    static func captureLLMGeneration(
        traceId: String,
        parentId: String,
        spanId: String,
        name: String,
        feature: String,
        model: String,
        provider: String,
        endpoint: String,
        startedAt: Date,
        statusCode: Int?,
        responseData: Data?,
        error: Error?,
        inputCharacters: Int? = nil,
        outputCharacters: Int? = nil
    ) {
        var properties: [String: Any] = [
            "$ai_trace_id": traceId,
            "$ai_parent_id": parentId,
            "$ai_span_id": spanId,
            "$ai_span_name": name,
            "$ai_model": model,
            "$ai_provider": provider,
            "$ai_latency": Date().timeIntervalSince(startedAt),
            "$ai_is_error": error != nil || (statusCode.map { !(200..<300).contains($0) } ?? false),
            "feature": feature,
            "endpoint": endpoint,
            "privacy_mode": "redacted_content",
        ]

        if let statusCode {
            properties["$ai_http_status"] = statusCode
        }
        if let error {
            properties["$ai_error"] = error.localizedDescription
        }
        if let inputCharacters {
            properties["input_characters"] = inputCharacters
        }
        if let outputCharacters {
            properties["output_characters"] = outputCharacters
        }

        let usage = tokenUsage(from: responseData)
        if let inputTokens = usage.inputTokens {
            properties["$ai_input_tokens"] = inputTokens
        }
        if let outputTokens = usage.outputTokens {
            properties["$ai_output_tokens"] = outputTokens
        }

        PostHogSDK.shared.capture("$ai_generation", properties: mergedCommonProperties(properties))
    }

    static func newTraceId() -> String {
        UUID().uuidString
    }

    static var installationId: String {
        if let existing = UserDefaults.standard.string(forKey: installationIdKey), !existing.isEmpty {
            return existing
        }
        let created = UUID().uuidString
        UserDefaults.standard.set(created, forKey: installationIdKey)
        return created
    }

    private static var commonProperties: [String: Any] {
        let bundle = Bundle.main
        return [
            "app_name": AppName.displayName,
            "app_version": bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown",
            "app_build": bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown",
            "bundle_identifier": bundle.bundleIdentifier ?? "unknown",
            "platform": "macOS",
            "installation_id": installationId,
        ]
    }

    private static func configuredValue(environmentKey: String, fallback: String) -> String {
        let value = ProcessInfo.processInfo.environment[environmentKey]?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return value?.isEmpty == false ? value! : fallback
    }

    private static func mergedCommonProperties(_ properties: [String: Any]?) -> [String: Any] {
        var merged = commonProperties
        properties?.forEach { key, value in
            merged[key] = value
        }
        return merged
    }

    private static func tokenUsage(from data: Data?) -> (inputTokens: Int?, outputTokens: Int?) {
        guard
            let data,
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let usage = json["usage"] as? [String: Any]
        else {
            return (nil, nil)
        }

        return (
            intValue(usage["prompt_tokens"] ?? usage["input_tokens"]),
            intValue(usage["completion_tokens"] ?? usage["output_tokens"])
        )
    }

    private static func intValue(_ value: Any?) -> Int? {
        if let value = value as? Int {
            return value
        }
        if let value = value as? NSNumber {
            return value.intValue
        }
        return nil
    }
}
