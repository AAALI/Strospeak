# API Key Setup for Strospeak

## Local Development

For local development, set environment variables when building:

```bash
xcodebuild build \
  -project "Stro Speak.xcodeproj" \
  -scheme "Stro Speak" \
  STRO_SPEAK_AI_API_KEY="your_api_key_here" \
  STRO_SPEAK_AI_BASE_URL="https://api.groq.com/openai/v1"
```

Or create a `.env` file (copy from `.env.example`) and use a tool like `dotenv` to load it.

## App Store Connect Setup

For App Store distribution, API keys are set via App Store Connect environment variables:

### Steps:

1. **Open App Store Connect**
   - Go to your app in App Store Connect
   - Navigate to "App Information" → "General Information"

2. **Add Custom Environment Variables**
   - In the build settings, add the following environment variables:
     ```
     STRO_SPEAK_AI_API_KEY = your_production_api_key
     STRO_SPEAK_AI_BASE_URL = https://api.groq.com/openai/v1
     STRO_SPEAK_TRANSCRIPTION_API_KEY = (optional)
     STRO_SPEAK_TRANSCRIPTION_BASE_URL = (optional)
     ```

3. **Configure Build Settings**
   - The Xcode project is already configured to read these variables
   - Build settings use `$(STRO_SPEAK_AI_API_KEY)` syntax
   - Values are injected into Info.plist at build time

### TestFlight vs Production

- **TestFlight**: Use your test API keys
- **Production**: Use your production API keys with appropriate rate limits

### Security Notes

- API keys are embedded in the app binary when distributed via App Store
- This is acceptable for voice apps as discussed in the implementation plan
- Monitor usage via your API provider's dashboard
- Implement usage tracking (Phase 3-4) for per-user monitoring
- Plan for key rotation if needed

## Current Configuration

The project uses the following build settings in `project.pbxproj`:

```
INFOPLIST_KEY_StroSpeakAIAPIKey = "$(STRO_SPEAK_AI_API_KEY)";
INFOPLIST_KEY_StroSpeakAIBaseURL = "$(STRO_SPEAK_AI_BASE_URL)";
INFOPLIST_KEY_StroSpeakTranscriptionAPIKey = "$(STRO_SPEAK_TRANSCRIPTION_API_KEY)";
INFOPLIST_KEY_StroSpeakTranscriptionBaseURL = "$(STRO_SPEAK_TRANSCRIPTION_BASE_URL)";
```

These are read by `GlobalAIServiceConfiguration.swift` which:
1. First checks environment variables
2. Falls back to Info.plist values
3. Returns empty string if neither is set

## Verification

To verify the setup works:

1. Build locally with environment variables set
2. Check that the app can successfully make API calls
3. Test with TestFlight to ensure App Store Connect variables work
4. Monitor API dashboard for successful requests
