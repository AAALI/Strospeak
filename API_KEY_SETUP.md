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

## App Store Distribution Setup

For App Store distribution, you need to hardcode the API keys in the Xcode project build settings since App Store Connect doesn't provide environment variable injection.

### Steps:

1. **Open Xcode Project**
   - Open `Stro Speak.xcodeproj` in Xcode
   - Select the project in the navigator
   - Select the "Stro Speak" target

2. **Add Build Settings**
   - Go to the "Build Settings" tab
   - Click the "+" button to add user-defined settings
   - Add the following build settings:
     ```
     STRO_SPEAK_AI_API_KEY = your_production_api_key
     STRO_SPEAK_AI_BASE_URL = https://api.groq.com/openai/v1
     STRO_SPEAK_TRANSCRIPTION_API_KEY = (optional, leave empty if not needed)
     STRO_SPEAK_TRANSCRIPTION_BASE_URL = (optional, leave empty if not needed)
     ```

**Note:** The project currently has placeholder values (`YOUR_GROQ_API_KEY_HERE`) that need to be replaced with your actual API keys.

3. **Configure Different Environments (Optional)**
   - Create separate schemes/configurations for TestFlight and Production
   - Set different API keys for each configuration
   - Use the appropriate scheme when building for each environment

### Alternative: Xcode Cloud

If using Xcode Cloud for CI/CD:
1. Go to Xcode Cloud workflow settings
2. Add environment variables in the workflow configuration
3. These will be available during the Xcode Cloud build process

### TestFlight vs Production

- **TestFlight**: Use your test API keys (lower rate limits)
- **Production**: Use your production API keys with appropriate rate limits
- Use different Xcode schemes or build configurations to separate these

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
