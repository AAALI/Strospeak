# API Key Implementation Plan for Strospeak Voice App

## Research Summary

### Industry Approaches Analyzed

**Clicky.so Approach:**
- Uses Cloudflare Worker as a proxy
- API keys stored as secrets in Cloudflare Worker
- App → Worker → APIs (keys never ship in binary)
- Adds latency but provides security

**Wispr Flow Approach:**
- Two authentication methods:
  1. API-key based auth: Keep API key on backend (easier, higher latency)
  2. Client-side auth (recommended): Generate access tokens for clients (lower latency)

**OpenAI Realtime Voice API:**
- Uses safety identifiers (hashed user IDs) for tracking
- Ephemeral client secrets for session-based auth
- Differentiates between voice-agent, translation, and transcription sessions

**Industry Best Practices:**
- Never hardcode API keys
- Use environment variables or secret management
- Implement proper authentication and rate limiting
- Monitor usage per user

## Chosen Solution: Hybrid Approach

**App Store Environment Variables + Login + PostHog + Client-side Usage Tracking**

### Security Assessment
- **Risk Level:** Medium
- API key still extractable from app bundle, but mitigated by:
  - User authentication layer
  - Usage tracking and monitoring
  - Ability to revoke/rotate keys

### Implementation Complexity
- **App Store env vars:** Simple (10 minutes)
- **Login system:** Medium (4-8 hours)
- **PostHog integration:** Simple (1-2 hours)
- **Client-side usage tracking:** Simple (1-2 hours)
- **Total:** 6-12 hours

### Latency Impact
- **Excellent:** Direct API calls (no proxy overhead)
- **Critical for voice apps:** Near-instant transcription/action execution

### Monetization Capabilities
- **Strong:** Login system enables user identification
- **PostHog:** Detailed usage analytics per user
- **Client-side tracking:** Precise voice message counting
- **Tiered pricing:** Can implement usage-based limits

### Cost Management
- **Groq API:** Monitor via dashboard
- **PostHog:** Free tier sufficient for most apps
- **No server costs:** Unlike proxy approach

## Why This Approach is Best for Strospeak

1. **Latency-critical:** Voice apps require minimal delay
2. **Monetization-ready:** Login + usage tracking enables subscription tiers
3. **Security-balanced:** Acceptable risk for voice apps (protecting quota, not sensitive data)
4. **Cost-effective:** No ongoing server infrastructure costs
5. **Industry-aligned:** Similar to Wispr Flow's client-side auth approach

## Implementation Phases

### Phase 1: App Store Environment Variables (Immediate)
**Status:** In Progress
**Time:** 10 minutes
**Tasks:**
- Set API keys in App Store Connect
- Update Xcode project to use build-time variables
- Test with TestFlight

### Phase 2: Login System (Week 1)
**Status:** Pending
**Time:** 4-8 hours
**Tasks:**
- Implement email/password or OAuth authentication
- Store user session securely in Keychain
- Add user settings screen for login/logout

### Phase 3: PostHog Integration (Week 1)
**Status:** Pending
**Time:** 1-2 hours
**Tasks:**
- Add PostHog SDK to Swift project
- Track user sign-ups, voice messages, API calls
- Set up dashboards for usage analytics

### Phase 4: Client-side Usage Tracking (Week 1)
**Status:** Pending
**Time:** 1-2 hours
**Tasks:**
- Implement local counter for voice messages
- Sync with PostHog for per-user tracking
- Add usage display in settings

### Phase 5: Monetization Features (Week 2)
**Status:** Pending
**Time:** 4-8 hours
**Tasks:**
- Implement usage limits per subscription tier
- Add upgrade prompts when limits reached
- Set up billing integration (RevenueCat or similar)

## Security Enhancements

- Add client-side rate limiting
- Implement device fingerprinting for abuse detection
- Monitor Groq dashboard for unusual usage patterns
- Plan for key rotation strategy

## Notes

- This plan balances security, latency, and monetization capabilities
- Implementation complexity is manageable for a voice transcription/action app
- Phases can be implemented incrementally as the app grows
