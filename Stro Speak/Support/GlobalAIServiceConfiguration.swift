import Foundation

struct GlobalAIServiceConfiguration {
    let apiKey: String
    let baseURL: String
    let fallbackAPIKey: String
    let fallbackBaseURL: String
    let transcriptionAPIKey: String
    let transcriptionBaseURL: String

    static var current: GlobalAIServiceConfiguration {
        GlobalAIServiceConfiguration(
            apiKey: configuredValue(
                environmentKey: "STRO_SPEAK_AI_API_KEY",
                infoDictionaryKey: "StroSpeakAIAPIKey"
            ),
            baseURL: configuredValue(
                environmentKey: "STRO_SPEAK_AI_BASE_URL",
                infoDictionaryKey: "StroSpeakAIBaseURL"
            ),
            fallbackAPIKey: configuredValue(
                environmentKey: "STRO_SPEAK_FALLBACK_AI_API_KEY",
                infoDictionaryKey: "StroSpeakFallbackAIAPIKey"
            ),
            fallbackBaseURL: configuredValue(
                environmentKey: "STRO_SPEAK_FALLBACK_AI_BASE_URL",
                infoDictionaryKey: "StroSpeakFallbackAIBaseURL"
            ),
            transcriptionAPIKey: configuredValue(
                environmentKey: "STRO_SPEAK_TRANSCRIPTION_API_KEY",
                infoDictionaryKey: "StroSpeakTranscriptionAPIKey"
            ),
            transcriptionBaseURL: configuredValue(
                environmentKey: "STRO_SPEAK_TRANSCRIPTION_BASE_URL",
                infoDictionaryKey: "StroSpeakTranscriptionBaseURL"
            )
        )
    }

    var resolvedTranscriptionAPIKey: String {
        transcriptionAPIKey.isEmpty ? apiKey : transcriptionAPIKey
    }

    var resolvedTranscriptionBaseURL: String {
        transcriptionBaseURL.isEmpty ? baseURL : transcriptionBaseURL
    }

    var hasAPIKey: Bool {
        !apiKey.isEmpty || !transcriptionAPIKey.isEmpty
    }

    private static func configuredValue(environmentKey: String, infoDictionaryKey: String) -> String {
        if let environmentValue = ProcessInfo.processInfo.environment[environmentKey],
           let value = usableConfiguredValue(environmentValue) {
            return value
        }

        if let bundleValue = Bundle.main.object(forInfoDictionaryKey: infoDictionaryKey) as? String {
            if let value = usableConfiguredValue(bundleValue) {
                return value
            }
        }

        return ""
    }

    private static func usableConfiguredValue(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        let placeholderValues: Set<String> = [
            "YOUR_GROQ_API_KEY_HERE",
            "your_api_key_here",
            "$(STRO_SPEAK_AI_API_KEY)",
            "$(STRO_SPEAK_FALLBACK_AI_API_KEY)",
            "$(STRO_SPEAK_TRANSCRIPTION_API_KEY)"
        ]

        guard !trimmed.hasPrefix("$("), !placeholderValues.contains(trimmed) else {
            return nil
        }

        return trimmed
    }
}
