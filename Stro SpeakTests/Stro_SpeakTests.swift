//
//  Stro_SpeakTests.swift
//  Stro SpeakTests
//
//  Created by Ali Abdulkadir Ali on 11/05/2026.
//

import XCTest
@testable import Stro_Speak

final class Stro_SpeakTests: XCTestCase {
    func testStructuredContextBlockIncludesAppMetadataAndSummary() {
        let context = slackTraFixContext()

        let block = PostProcessingService.formattedContextBlock(for: context)

        XCTAssertTrue(block.contains("App: Slack"))
        XCTAssertTrue(block.contains("Bundle ID: com.tinyspeck.slackmacgap"))
        XCTAssertTrue(block.contains("Window: Suramya Senarath"))
        XCTAssertTrue(block.contains("Selected text: None"))
        XCTAssertTrue(block.contains("Screenshot: available (image/jpeg)"))
        XCTAssertTrue(block.contains("Current conversation/person: Suramya Senarath"))
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

        XCTAssertTrue(prompt.contains("Suramya Senarath"))
        XCTAssertTrue(prompt.contains("Never replace a visible participant name with a different near-match"))
        XCTAssertTrue(prompt.contains("Do not output a wrong visible-name near match such as \"Shamia\""))
    }

    private func slackTraFixContext() -> AppContext {
        AppContext(
            appName: "Slack",
            bundleIdentifier: "com.tinyspeck.slackmacgap",
            windowTitle: "Suramya Senarath",
            selectedText: nil,
            currentActivity: """
App: Slack
Surface: Direct message
Writing destination: Message composer in a DM with Suramya Senarath
Likely intent: Reply to Suramya's latest TraFix permissions question
Tone expectation: concise and helpful
Formatting hint: one short chat message
Current conversation/person: Suramya Senarath
Latest visible message/request: Could you please check the permissions for my TraFix account? I cannot see anything on it.
Visible names or terms: Suramya Senarath, Ali, TraFix, Akram
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
