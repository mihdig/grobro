# GroBro Device Integration Strategy

**Last Updated:** November 14, 2025
**Status:** Planning Phase

---

## Overview

GroBro will integrate with popular grow controller hardware to automatically log environmental data (temperature, humidity, VPD) alongside manual plant diary entries. This document outlines the technical approach and business strategy.

---

## Supported Devices (Roadmap)

| Device | Story | API Status | Priority | Notes |
|--------|-------|------------|----------|-------|
| **AC Infinity UIS Controllers** | 7.2 | Unofficial (reverse-engineered) | P1 | Most popular brand, large user base |
| **Vivosun Controllers** | 7.1 | Unknown (research needed) | P2 | Second most popular, smaller ecosystem |
| **Manual Entry** | 8.1 | N/A | P0 | Always available fallback |

---

## AC Infinity Integration

### Current Situation (November 2025)

**✅ What We Know:**
- AC Infinity has a cloud API used by their mobile apps
- Community developers have reverse-engineered the API:
  - **Home Assistant integration** (GitHub: dalinicus/homeassistant-acinfinity)
  - **Python `acinf` package** (GitHub: jquast/acinf)
- API endpoints are publicly accessible (no authentication bypass needed)
- Minimum polling interval: 5 seconds (per HA integration)

**❌ What We Don't Have:**
- Official public API documentation
- Developer partnership or agreement
- Official API keys or SDK

### Two-Track Approach

#### Track 1: Technical Implementation (Parallel)
**Use reverse-engineered API** (same as Home Assistant integration)

**Why This Works:**
- Proven approach: Home Assistant integration has 1000+ users
- Legally defensible: No circumvention, public API endpoints
- Fast to market: Can ship in 1-2 weeks
- Read-only: No device control, just data reading (low risk)

**Technical Approach:**
```swift
// Authentication
POST https://api.acinfinity.com/api/user/login
Body: { "email": "user@example.com", "password": "..." }
Response: { "token": "..." }

// Get Devices
GET https://api.acinfinity.com/api/user/devices
Headers: { "Authorization": "Bearer <token>" }

// Get Sensor Data
GET https://api.acinfinity.com/api/device/{deviceId}/sensors
Response: { "temperature": 75.2, "humidity": 60, "vpd": 1.2 }
```

**Sync Strategy:**
- Poll every 5-15 minutes (less aggressive than HA's 5 seconds)
- Background sync using BGTaskScheduler
- Log data as events with `source: .acinfinity` indicator

**Risk Mitigation:**
- Abstraction layer: Easy to swap to official API
- Fallback: Manual logging always available
- Clear disclaimers: "Unofficial integration"
- Monitoring: Alert if API structure changes

#### Track 2: Business Partnership (Parallel)
**Pursue official API access** with AC Infinity

**Contact:**
- Email: dev@acinfinity.com
- Purpose: Request official API docs, propose partnership

**Partnership Proposal:**
1. **Value Proposition:**
   - GroBro users = AC Infinity controller buyers
   - Co-marketing opportunity (App Store featuring, blog posts)
   - Official integration increases device sales

2. **Request:**
   - Official API documentation
   - Developer API keys
   - Beta tester access for AC Infinity team

3. **Offer:**
   - Promote AC Infinity controllers in app (affiliate links?)
   - Feature AC Infinity in launch announcement
   - Provide user feedback to AC Infinity (feature requests)

**Timeline:**
- Week 1: Send partnership email
- Week 2-4: Continue unofficial implementation
- Week 4-8: If partnership secured → migrate to official API
- If no response → ship with reverse-engineered API

---

## Legal & Compliance

### Using Reverse-Engineered APIs

**Legal Precedents:**
- **LinkedIn v. HiQ Labs** (2019): Public data scraping is legal
- **Oracle v. Google** (2021): APIs not copyrightable
- Key factors:
  - ✅ No circumvention of technical protections
  - ✅ Public API endpoints (no authentication bypass)
  - ✅ Read-only access (no control/modification)
  - ✅ Transparent about unofficial status

**Our Approach:**
- Display clear disclaimers: "Unofficial integration. AC Infinity is not affiliated with GroBro."
- Read-only data access (no device control)
- Offer official AC Infinity app link for full control
- Document all endpoints and behaviors
- Ready to switch to official API if provided

### Privacy & Security

**User Credentials:**
- Store in iOS Keychain with `.whenUnlocked` accessibility
- Never log credentials or tokens
- Use HTTPS for all API calls
- Clear on logout

**User Data:**
- Environmental data synced to user's device/iCloud only
- No GroBro servers involved (local-first architecture)
- User can disable integration anytime

---

## Technical Architecture

### Abstraction Layer

Design allows swapping unofficial → official API with minimal code changes:

```swift
protocol DeviceIntegrationClient {
    func authenticate(email: String, password: String) async throws -> String
    func fetchDevices() async throws -> [Device]
    func fetchSensorData(deviceId: String) async throws -> SensorData
}

// Unofficial implementation
class ACInfinityUnofficialClient: DeviceIntegrationClient { ... }

// Future official implementation (drop-in replacement)
class ACInfinityOfficialClient: DeviceIntegrationClient { ... }
```

### Data Flow

```
AC Infinity Controller (physical device)
  ↓ (WiFi)
AC Infinity Cloud API
  ↓ (HTTPS polling every 5-15 min)
GroBro ACInfinityAPIClient
  ↓
ACInfinitySyncService
  ↓
EventStore (Core Data)
  ↓
Plant Diary Timeline UI
```

### Error Handling

| Error | Response | User Experience |
|-------|----------|-----------------|
| Invalid credentials | Show re-login prompt | "Re-enter AC Infinity password" |
| Rate limit | Exponential backoff | "Sync paused temporarily" |
| Network error | Queue for next sync | "Syncing when online" |
| API structure change | Disable integration | "AC Infinity integration unavailable. Update app." |

---

## User Experience

### Pairing Flow

1. **Settings → Integrations → AC Infinity**
2. Enter email/password
3. App fetches devices
4. User sees: "Controller 69 Pro - Tent A"
5. User selects device → associates with plant(s)
6. Auto-sync starts immediately

### Diary Timeline

Environmental events appear in plant timeline:

```
[AC Infinity icon] 3:45 PM
Temperature: 75°F, Humidity: 60%, VPD: 1.2 kPa
```

### Settings UI

```
[✓] AC Infinity Integration
    Last Sync: 5 minutes ago
    [ Sync Now ]

    Devices:
    - Controller 69 Pro - Tent A
      Associated: Plant A, Plant B
      Sync: Every 10 minutes
```

---

## Comparison: Manual vs Integrated Logging

| Feature | Manual Logging | AC Infinity Integration |
|---------|----------------|-------------------------|
| **Effort** | Manual entry every day | Automatic, zero effort |
| **Accuracy** | Human error possible | Precise sensor data |
| **Frequency** | 1-2x per day typical | Every 5-15 minutes |
| **Cost** | Free | Requires AC Infinity controller ($100-300) |
| **Reliability** | User must remember | Always syncing |

**Value Proposition:**
- Growers already own AC Infinity controllers → integration is **free upgrade**
- Saves 5-10 minutes per day on manual logging
- Better data quality → better AI recommendations

---

## Vivosun Integration (Story 7.1)

**Status:** Research phase

**Approach:**
- Similar two-track strategy (unofficial + partnership)
- Research Vivosun app's API endpoints
- Check if Vivosun has developer program
- Contact: Find Vivosun developer email

**Priority:** P2 (after AC Infinity proves successful)

---

## Rollout Plan

### Phase 1: AC Infinity (Unofficial)
**Timeline:** Week 7-9 (Sprint 4)
- Implement Story 7.2 using reverse-engineered API
- Ship to TestFlight beta testers
- Gather feedback on reliability and UX

### Phase 2: Official Partnership (If Secured)
**Timeline:** Week 10-12
- Migrate to official AC Infinity API
- Update App Store description: "Official AC Infinity Integration"
- Co-marketing push with AC Infinity

### Phase 3: Vivosun Integration
**Timeline:** Week 13-15
- Repeat process for Vivosun controllers
- Ship second device integration

### Phase 4: Additional Devices (Future)
**Timeline:** Q2 2026+
- Based on user requests:
  - Inkbird controllers
  - Pulse sensors
  - Spider Farmer controllers

---

## Success Metrics

### Adoption Metrics
- **Target:** 20% of users connect AC Infinity within 30 days
- **Target:** 10% of users connect Vivosun within 30 days
- **Target:** 30% of users use manual environmental logging

### Engagement Metrics
- **Target:** 100+ environmental data points logged per plant per month
- **Target:** 90%+ sync success rate (no errors)

### Business Metrics
- **Target:** 15% increase in Pro conversion (environmental data → analytics value)
- **Target:** 50% reduction in "manual logging is tedious" complaints

---

## Risks & Mitigation

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| AC Infinity changes API | High | Medium | Monitoring, abstraction layer, fallback to manual |
| Legal challenge from AC Infinity | High | Low | Read-only, public API, willing to partner |
| User credentials leak | High | Low | Keychain storage, HTTPS only, security audit |
| Sync reliability issues | Medium | Medium | Retry logic, exponential backoff, status indicators |
| Partnership rejection | Low | Medium | Ship with unofficial, clearly disclaimed |

---

## Next Actions

### Immediate (This Week)
1. ✅ **PO:** Complete Story 7.2 documentation (DONE)
2. 📧 **Business:** Draft partnership email to dev@acinfinity.com
3. 📧 **Business:** Send partnership email by Friday

### Week 7-8 (Sprint 4)
1. 🔬 **Dev:** Research AC Infinity API using HA integration code
2. 🔬 **Dev:** Test API endpoints with AC Infinity account
3. 📋 **PO:** Prepare Story 7.1 (Vivosun) with similar structure

### Week 9 (Sprint 5)
1. ⚡ **Dev:** Start Story 7.2 implementation
2. 👥 **QA:** Recruit beta testers with AC Infinity controllers
3. 📊 **Analytics:** Set up monitoring for sync success rates

---

## Document Maintenance

Update this document:
- **Weekly:** If partnership status changes
- **Ad-hoc:** When new device integration opportunities arise
- **Post-launch:** With actual adoption and reliability metrics

**Owner:** Sarah (Product Owner)
**Contributors:** Dev Team, Business Development

---

*This strategy balances technical pragmatism with business partnership opportunities. We move fast with reverse-engineered APIs while pursuing official relationships in parallel.*
