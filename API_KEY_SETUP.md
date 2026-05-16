# API Key Setup for Strospeak

## Local Development

For local development, set environment variables when building:

```bash
xcodebuild build \
  -project "Stro Speak.xcodeproj" \
  -scheme "Stro Speak" \
  STRO_SPEAK_AI_API_KEY="your_api_key_here" \
  STRO_SPEAK_AI_BASE_URL="https://api.openai.com/v1" \
  STRO_SPEAK_FALLBACK_AI_API_KEY="your_groq_key_here" \
  STRO_SPEAK_FALLBACK_AI_BASE_URL="https://api.groq.com/openai/v1"
```

Or create a `.env` file (copy from `.env.example`) and use a tool like `dotenv` to load it.

## App Store Distribution Setup

For App Store distribution, set the API configuration as Xcode Cloud shared environment variables. Xcode Cloud exposes these values during the build, `ci_scripts/ci_pre_xcodebuild.sh` writes them into `Config/GeneratedCloudSecrets.xcconfig`, and the app target expands them into the generated `Info.plist` so the distributed app can use the same global key for every user.

### Xcode Cloud Shared Environment Variables

1. Go to App Store Connect > Xcode Cloud > Settings > Shared Environment Variables.
2. Add these shared variables:
   ```
   STRO_SPEAK_AI_API_KEY = your_production_api_key
   STRO_SPEAK_AI_BASE_URL = https://api.openai.com/v1
   STRO_SPEAK_FALLBACK_AI_API_KEY = your_groq_fallback_key
   STRO_SPEAK_FALLBACK_AI_BASE_URL = https://api.groq.com/openai/v1
   STRO_SPEAK_TRANSCRIPTION_API_KEY = (optional, leave empty if not needed)
   STRO_SPEAK_TRANSCRIPTION_BASE_URL = (optional, leave empty if not needed)
   ```
3. Make sure the workflow uses the shared variables, as shown by the `Used In` workflow column in App Store Connect.

Do not add the API key as a hardcoded target build setting in the Xcode project. The target reads `Config/SharedEnvironment.xcconfig`, which optionally includes the generated Xcode Cloud secrets file. `Config/GeneratedCloudSecrets.xcconfig` is ignored by git and should never be committed.

### TestFlight vs Production

- **TestFlight**: Use your test API keys if you have a separate Xcode Cloud workflow.
- **Production**: Use your production API keys with appropriate rate limits.
- Use different Xcode Cloud workflows or shared variable sets if you need separate environments.

### Security Notes

- API keys are embedded in the app binary when distributed via App Store
- This is acceptable for voice apps as discussed in the implementation plan
- Monitor usage via your API provider's dashboard
- Implement usage tracking (Phase 3-4) for per-user monitoring
- Plan for key rotation if needed

## Current Configuration

The app target uses `Config/SharedEnvironment.xcconfig` as its base configuration and expands the following keys in `Stro Speak/Info.plist`:

```
StroSpeakAIAPIKey = "$(STRO_SPEAK_AI_API_KEY)"
StroSpeakAIBaseURL = "$(STRO_SPEAK_AI_BASE_URL)"
StroSpeakFallbackAIAPIKey = "$(STRO_SPEAK_FALLBACK_AI_API_KEY)"
StroSpeakFallbackAIBaseURL = "$(STRO_SPEAK_FALLBACK_AI_BASE_URL)"
StroSpeakTranscriptionAPIKey = "$(STRO_SPEAK_TRANSCRIPTION_API_KEY)"
StroSpeakTranscriptionBaseURL = "$(STRO_SPEAK_TRANSCRIPTION_BASE_URL)"
```

These are read by `GlobalAIServiceConfiguration.swift` which:
1. First checks process environment variables for local runs and tests
2. Falls back to generated `Info.plist` values embedded by Xcode Cloud builds
3. Ignores empty, unresolved, or placeholder values
4. Returns empty string if no real value is set

## Verification

To verify the setup works:

1. Build locally with environment variables set
2. Check that the app can successfully make API calls
3. Test with TestFlight to ensure Xcode Cloud shared variables were embedded
4. Monitor API dashboard for successful requests
