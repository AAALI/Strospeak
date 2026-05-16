# Stro Speak

A macOS menu-bar dictation app. Hold a key to talk, release to paste the cleaned transcription into whatever app you're in.

## Pipeline

1. Global hotkey (hold-to-talk or tap-to-toggle) starts an audio recording.
2. Audio is sent to an OpenAI-compatible transcription endpoint.
3. Transcript is cleaned up by a primary OpenAI-compatible LLM with screen-context awareness (active window, selected text, screenshot via ScreenCaptureKit) and optional Groq fallback.
4. Result is pasted into the focused text field.

## Project layout

```
Stro Speak.xcodeproj/           Xcode project
Stro Speak/                     Source root (file-system synchronized group)
├── App/                        Entry point, AppDelegate, AppState
├── Audio/                      Recording, level metering, device monitoring
├── Transcription/              Transcription + LLM cleanup + context capture
├── Hotkeys/                    Global hotkey + shortcut matcher state machine
├── UI/                         MenuBarView, SettingsView, SetupView, RecordingOverlay
├── Storage/                    Keychain-backed settings
├── Support/                    Pipeline history, notifications, helpers
├── Updates/                    Update manager (currently a no-op placeholder)
├── Assets.xcassets             App icon / accent color (placeholder — needs assets)
└── StroSpeak.entitlements      Hardened-runtime entitlements (audio input)
Stro SpeakTests/                Unit test target
Stro SpeakUITests/              UI test target
```

## Build & run

Requires Xcode targeting the macOS SDK matching `MACOSX_DEPLOYMENT_TARGET` in `Stro Speak.xcodeproj`.

```
open "Stro Speak.xcodeproj"
```

The app runs un-sandboxed (required for global hotkey, accessibility, and paste-to-frontmost-app) with hardened runtime on. First launch will prompt for Microphone, Accessibility, and Screen Recording permissions.

## Configuration

- **API key**: set via the in-app Settings → uses Keychain for storage.
- **Provider**: defaults to OpenAI for cleanup/context, with optional Groq fallback; any OpenAI-compatible URL works.
- **Shortcuts**: customizable in Settings; defaults are `Fn` (hold) and `⌘Fn` (toggle).

## Concurrency settings

The Xcode target intentionally has Swift 6 strict-concurrency / member-import-visibility flags **off** so the ported code compiles cleanly. Re-enabling them is a follow-up modernization pass.

## License

Originally based on [FreeFlow](https://github.com/zachlatta/freeflow) (MIT). Heavily refactored and rebranded.
