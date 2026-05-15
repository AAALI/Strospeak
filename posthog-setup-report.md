<wizard-report>
# PostHog post-wizard report

The wizard has completed a deep integration of PostHog analytics into **Stro Speak**, a macOS dictation app. Here is a summary of all changes made:

- **PostHog iOS SDK** (v3.58.3) added to the Xcode project via Swift Package Manager (`project.pbxproj` updated with `XCRemoteSwiftPackageReference`, `XCSwiftPackageProductDependency`, and `PBXBuildFile` entries).
- **PostHog initialized** in `StroSpeakApp.swift` via a `PostHogEnv` enum that reads `POSTHOG_PROJECT_TOKEN` and `POSTHOG_HOST` from Xcode scheme environment variables at runtime.
- **Xcode shared scheme** created at `Stro Speak.xcodeproj/xcshareddata/xcschemes/Stro Speak.xcscheme` with the required environment variable keys pre-configured. Set `POSTHOG_PROJECT_TOKEN` in **Product > Scheme > Edit Scheme > Run > Environment Variables**.
- **`ENABLE_OUTGOING_NETWORK_CONNECTIONS = YES`** added to both Debug and Release build configurations to allow PostHog to reach its servers from within the App Sandbox.
- **8 events** instrumented across 4 files (see table below).

| Event | Description | File |
|---|---|---|
| `recording_started` | User starts a dictation recording session (hold or toggle trigger mode) | `Stro Speak/App/AppState.swift` |
| `recording_cancelled` | User cancels an active recording before transcription | `Stro Speak/App/AppState.swift` |
| `transcription_completed` | Transcription pipeline completes successfully and text is pasted at cursor | `Stro Speak/App/AppState.swift` |
| `transcription_failed` | Transcription or post-processing step fails with an error | `Stro Speak/App/AppState.swift` |
| `command_transform_used` | User invokes edit/command mode to transform selected text with a voice command | `Stro Speak/App/AppState.swift` |
| `setup_completed` | User finishes the first-run setup wizard | `Stro Speak/App/AppDelegate.swift` |
| `api_key_saved` | User saves a new API key in settings | `Stro Speak/App/AppState.swift` |
| `vocabulary_saved` | User saves custom vocabulary terms during setup | `Stro Speak/UI/SetupView.swift` |

## Next steps

We've built some insights and a dashboard for you to keep an eye on user behavior, based on the events we just instrumented:

- [Analytics basics dashboard](/dashboard/684355)
- [Recordings over time](/insights/mIRa8xGw)
- [Transcription success vs failure](/insights/jowYMTOG)
- [Setup completion funnel](/insights/t2G1UDjf)
- [Command mode vs dictation usage](/insights/ChlWDBdk)
- [Recording cancellation rate](/insights/Vd6uDigz)

### Agent skill

We've left an agent skill folder in your project. You can use this context for further agent development when using Claude Code. This will help ensure the model provides the most up-to-date approaches for integrating PostHog.

</wizard-report>
