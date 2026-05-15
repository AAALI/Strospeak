//
//  Stro_SpeakTests.swift
//  Stro SpeakTests
//
//  Created by Ali Abdulkadir Ali on 11/05/2026.
//

import XCTest
@testable import Stro_Speak

final class Stro_SpeakTests: XCTestCase {
    override func tearDown() {
        unsetenv("STRO_SPEAK_AI_API_KEY")
        unsetenv("STRO_SPEAK_AI_BASE_URL")
        unsetenv("STRO_SPEAK_TRANSCRIPTION_API_KEY")
        unsetenv("STRO_SPEAK_TRANSCRIPTION_BASE_URL")
        super.tearDown()
    }

    func testGlobalAIServiceConfigurationReadsEnvironmentValues() {
        setenv("STRO_SPEAK_AI_API_KEY", " service-key ", 1)
        setenv("STRO_SPEAK_AI_BASE_URL", " https://api.example.com/openai/v1 ", 1)

        let configuration = GlobalAIServiceConfiguration.current

        XCTAssertEqual(configuration.apiKey, "service-key")
        XCTAssertEqual(configuration.baseURL, "https://api.example.com/openai/v1")
    }

    func testGlobalAIServiceConfigurationTreatsPlaceholderAPIKeyAsMissing() {
        setenv("STRO_SPEAK_AI_API_KEY", "YOUR_GROQ_API_KEY_HERE", 1)

        let configuration = GlobalAIServiceConfiguration.current

        XCTAssertEqual(configuration.apiKey, "")
        XCTAssertFalse(configuration.hasAPIKey)
    }

    func testGlobalAIServiceConfigurationSupportsTranscriptionSpecificOverrides() {
        setenv("STRO_SPEAK_AI_API_KEY", "service-key", 1)
        setenv("STRO_SPEAK_AI_BASE_URL", "https://api.example.com/openai/v1", 1)
        setenv("STRO_SPEAK_TRANSCRIPTION_API_KEY", "speech-key", 1)
        setenv("STRO_SPEAK_TRANSCRIPTION_BASE_URL", "https://speech.example.com/openai/v1", 1)

        let configuration = GlobalAIServiceConfiguration.current

        XCTAssertEqual(configuration.resolvedTranscriptionAPIKey, "speech-key")
        XCTAssertEqual(configuration.resolvedTranscriptionBaseURL, "https://speech.example.com/openai/v1")
    }

    func testStructuredContextBlockIncludesAppMetadataAndSummary() {
        let context = slackTraFixContext()

        let block = PostProcessingService.formattedContextBlock(for: context)

        XCTAssertTrue(block.contains("App: Slack"))
        XCTAssertTrue(block.contains("Bundle ID: com.tinyspeck.slackmacgap"))
        XCTAssertTrue(block.contains("Window: Maya Patel"))
        XCTAssertTrue(block.contains("Selected text: None"))
        XCTAssertTrue(block.contains("Screenshot: available (image/jpeg)"))
        XCTAssertTrue(block.contains("Current conversation/person: Maya Patel"))
        XCTAssertTrue(block.contains("Latest visible message/request: Could you please check the permissions for my TraFix account?"))
    }

    func testSystemPromptAllowsDirectChatReplyDrafting() {
        let prompt = PostProcessingService.defaultSystemPrompt

        XCTAssertTrue(prompt.contains("When the destination is a chat or messaging app"))
        XCTAssertTrue(prompt.contains("compose the direct message to paste"))
        XCTAssertTrue(prompt.contains("Do not output meta-instructions"))
    }

    func testSystemPromptKeepsLiteralDictationOutsideClearChatReplyIntent() {
        let prompt = PostProcessingService.defaultSystemPrompt

        XCTAssertTrue(prompt.contains("Outside clear chat-reply intent"))
        XCTAssertTrue(prompt.contains("continue treating the transcript as dictated text to clean and format"))
    }

    func testSystemPromptUsesVisibleNamesAsSpellingAnchors() {
        let prompt = PostProcessingService.defaultSystemPrompt

        XCTAssertTrue(prompt.contains("Maya Patel"))
        XCTAssertTrue(prompt.contains("Never replace a visible participant name with a different near-match"))
        XCTAssertTrue(prompt.contains("Do not output a wrong visible-name near match such as \"Mia\""))
    }

    private func slackTraFixContext() -> AppContext {
        AppContext(
            appName: "Slack",
            bundleIdentifier: "com.tinyspeck.slackmacgap",
            windowTitle: "Maya Patel",
            selectedText: nil,
            currentActivity: """
App: Slack
Surface: Direct message
Writing destination: Message composer in a DM with Maya Patel
Likely intent: Reply to Maya's latest TraFix permissions question
Tone expectation: concise and helpful
Formatting hint: one short chat message
Current conversation/person: Maya Patel
Latest visible message/request: Could you please check the permissions for my TraFix account? I cannot see anything on it.
Visible names or terms: Maya Patel, Jordan Lee, TraFix, Slack
Uncertainty: Low
""",
            contextSystemPrompt: nil,
            contextPrompt: nil,
            screenshotDataURL: nil,
            screenshotMimeType: "image/jpeg",
            screenshotError: nil
        )
    }

}
