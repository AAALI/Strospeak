import Foundation

struct GlobalAIServiceConfiguration {
    let apiKey: String
    let baseURL: String
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
           !environmentValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return environmentValue.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let bundleValue = Bundle.main.object(forInfoDictionaryKey: infoDictionaryKey) as? String {
            let trimmed = bundleValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty && !trimmed.hasPrefix("$(") {
                return trimmed
            }
        }

        return ""
    }
}
