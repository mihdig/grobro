# GroBro Product Roadmap

## Overview

This document outlines the complete product vision for GroBro across 5 major epics, from MVP to advanced features.

## Epic Status Summary

| Epic | Status | Stories | Priority | Target Release |
|------|--------|---------|----------|----------------|
| Epic 1: iOS v1 Garden & Diagnostics | ✅ Complete (6/6) | All stories approved | P0 - MVP | v1.0 |
| Epic 2: Pro Features & Analytics | ✅ Complete (6/6) | All stories approved | P0 - Monetization | v1.1 |
| Epic 3: Device Integrations | 📋 Planned (0/8) | Needs story creation | P1 - Differentiation | v1.2-v1.3 |
| Epic 4: Knowledge Base & Education | 📋 Planned (0/6) | Needs story creation | P1 - Engagement | v1.3-v1.4 |
| Epic 5: App Intents & Siri | 📋 Planned (0/7) | Needs story creation | P2 - Polish | v1.4-v1.5 |

**Total:** 5 epics, 33 stories (12 ready, 21 planned)

---

## Epic 1: iOS v1 Garden & Diagnostics ✅

**Goal:** Deliver first usable version with local-first plant diary, watering scheduler, and AI diagnostics.

**Business Value:** Demonstrates core value proposition, establishes architecture foundation, enables TestFlight testing.

### Stories (All Approved ✅)

1. **1.1 App Shell and Persistence**
   - Foundation: SwiftUI app, Core Data/SwiftData, persistence layer
   - Critical path for all other stories

2. **1.2 Plant Creation and Detail**
   - CRUD operations for plants
   - Plant detail screen with basic info display

3. **1.3 Garden View and Navigation**
   - Main garden list view
   - Plant cards with status indicators
   - Navigation to detail screens

4. **2.1 Diary Events and Timeline**
   - Event logging (watering, feeding, notes, photos, stress)
   - Timeline visualization
   - Event filtering and search

5. **2.2 Watering Scheduler and Reminders**
   - Adaptive watering interval calculation
   - Local push notifications
   - User feedback for interval adjustment

6. **3.1 L1 Diagnostics and Debug Console**
   - Photo-based plant health diagnostics (Core ML)
   - AI debug console for troubleshooting
   - Offline fallback mode

**Completion Criteria:** User can track 1+ plants end-to-end with diagnostics, entirely offline.

---

## Epic 2: Pro Features & Analytics ✅

**Goal:** Create compelling monetization model with Pro tier differentiation.

**Business Value:** Establishes recurring revenue, targets committed growers, foundation for B2B features.

### Stories (All Approved ✅)

1. **4.1 Subscription Management and Pro Gating**
   - StoreKit 2 integration
   - Pro entitlement system
   - Free tier plant limit (3 plants)
   - Restore purchases and graceful degradation

2. **4.2 Subscription UI and Upgrade Flow**
   - "Upgrade to Pro" screen
   - Contextual Pro feature prompts
   - Subscription management in Settings

3. **5.1 Advanced Analytics Dashboard**
   - Growth timeline visualization
   - Watering frequency charts
   - Event distribution graphs
   - Stage duration analytics

4. **5.2 Data Export Functionality**
   - CSV and JSON export formats
   - Scope filtering (single plant / all / date range)
   - Privacy-conscious export with README

5. **6.1 iCloud Sync Architecture**
   - CloudKit integration
   - Bidirectional sync across devices
   - Background sync and offline queue
   - Sync status indicators

6. **6.2 Conflict Resolution and Offline Support**
   - Intelligent conflict resolution
   - "Last write wins" with timestamp
   - Offline edit preservation
   - Quota/rate limit handling

**Completion Criteria:** Pro users get unlimited plants, analytics, export, and iCloud sync.

---

## Epic 3: Device Integrations 📋

**Goal:** Integrate with grow controller hardware for automated environmental logging.

**Business Value:** Differentiates from basic diary apps, appeals to serious growers, data foundation for AI recommendations.

### Planned Stories (8 total)

**Controller Integrations:**
- 7.1 Vivosun Integration and Data Sync
- 7.2 AC Infinity Integration and Data Sync
- 7.3 Device Pairing and Room Management

**Environmental Features:**
- 8.1 Environmental Data Timeline
- 8.2 Environmental Analytics Dashboard
- 8.3 Threshold Alerts and Notifications

**Light Assistant:**
- 9.1 Camera Light Distance Measurement (ARKit)
- 9.2 Light Recommendations Engine

**Completion Criteria:** Users can pair grow controllers, automatically log environmental data, and use AR-based light assistant.

---

## Epic 4: Knowledge Base & Education 📋

**Goal:** Provide safe, educational content positioning GroBro as trusted authority.

**Business Value:** Increases engagement, reduces support burden, legal protection through disclaimers.

### Planned Stories (6 total)

**Content Infrastructure:**
- 10.1 Guides Section and Content Delivery
- 10.2 Search and Bookmarks

**Educational Content:**
- 10.3 Core Educational Content (writing guides)
- 10.4 Context-Aware Tips System

**Compliance:**
- 10.5 Safety and Legal Content
- 10.6 Content Moderation Guidelines

**Completion Criteria:** Users can access curated guides, search content, get context-aware tips, and see clear legal/safety disclaimers.

---

## Epic 5: App Intents & Siri Integration 📋

**Goal:** Leverage iOS ecosystem for hands-free, low-friction interactions.

**Business Value:** Improves convenience during hands-on tasks, showcases technical excellence, competitive differentiation.

### Planned Stories (7 total)

**App Intents:**
- 11.1 App Intents Framework Integration
- 11.2 Siri Voice Commands
- 11.3 Shortcuts Suggested Actions
- 11.4 Spotlight Search Integration

**Widgets:**
- 12.1 Home Screen Widgets
- 12.2 Lock Screen Widgets
- 12.3 Widget Configuration and Deep Linking

**Completion Criteria:** Users can log actions via Siri, use Shortcuts, search in Spotlight, and view plant status via widgets.

---

## Implementation Phases

### Phase 1: MVP + Monetization (v1.0 - v1.1)
**Priority:** P0 - Critical Path
**Timeline:** Immediate

1. Complete Epic 1 (all 6 stories) - Foundation
2. Complete Epic 2 (all 6 stories) - Monetization
3. Launch TestFlight beta
4. Submit to App Store

**Success Metrics:**
- 100% of Epic 1 & 2 stories complete
- TestFlight with 20+ testers
- App Store submission ready

### Phase 2: Advanced Features (v1.2 - v1.3)
**Priority:** P1 - Differentiation
**Timeline:** Post-launch + 3 months

1. Create and implement Epic 3 stories (Device Integrations)
2. Begin Epic 4 stories (Knowledge Base)

**Success Metrics:**
- Vivosun and AC Infinity integrations live
- Environmental analytics available
- At least 10 educational guides published

### Phase 3: Polish & Ecosystem (v1.4 - v1.5)
**Priority:** P2 - Polish
**Timeline:** Post-launch + 6 months

1. Complete Epic 4 stories (Knowledge Base)
2. Complete Epic 5 stories (Siri & Widgets)

**Success Metrics:**
- Siri voice commands functional
- Home and lock screen widgets available
- Full knowledge base with search

---

## Current Status & Next Steps

### ✅ Completed
- All Epic 1 stories created and approved (6/6)
- All Epic 2 stories created and approved (6/6)
- All epics defined with clear business value and scope

### 🚧 In Progress
- Story 3.1 (Diagnostics and Debug Console) - nearing completion

### 📋 Immediate Next Steps
1. **Complete Story 3.1** - finish diagnostics implementation
2. **Begin Epic 2 implementation** - prioritize subscription system (4.1, 4.2)
3. **Create remaining stories** for Epics 3-5 (21 stories)
4. **TestFlight preparation** - beta testing infrastructure

### 🎯 Definition of "Ready for Dev"
All Epic 1 and Epic 2 stories are marked **Approved** and ready for development:
- Acceptance criteria defined
- Tasks and subtasks identified
- Dev notes include architecture context
- Testing approach documented

---

## Dependencies & Risks

### Technical Dependencies
- ✅ iOS 18.0+ deployment target (confirmed)
- ✅ Swift 6.1+ and SwiftUI (confirmed)
- ✅ SwiftData for persistence (confirmed in CLAUDE.md)
- ⚠️ Core ML model for diagnostics (placeholder acceptable for v1)
- ⚠️ LLM API for debug console (stub acceptable for v1)

### External Dependencies
- StoreKit 2 for subscriptions (native, no risk)
- CloudKit for sync (native, minor risk around quota limits)
- Vivosun API (requires partnership/API access)
- AC Infinity API (requires partnership/API access)

### Key Risks
1. **Legal/Compliance** - Cannabis legality varies by jurisdiction
   - Mitigation: Strong disclaimers, no cultivation instructions, user responsibility
2. **AI Safety** - Diagnostic accuracy and liability
   - Mitigation: Soft language, hypothesis-based (not diagnostic), clear disclaimers
3. **Device Integration** - API availability and stability
   - Mitigation: Read-only integrations, graceful degradation, manual logging fallback
4. **Monetization** - Pro tier perceived value
   - Mitigation: Clear differentiation, free tier valuable on its own, generous trial

---

## Success Metrics (KPIs)

### Epic 1 (MVP) Metrics
- User retention: 40%+ D7 retention
- Engagement: 3+ diary entries per week per active user
- Feature adoption: 60%+ users try diagnostics within first week

### Epic 2 (Monetization) Metrics
- Conversion: 5%+ Free → Pro conversion within 30 days
- Revenue: $X MRR target (define based on business goals)
- Export usage: 20%+ of Pro users export data monthly

### Epic 3-5 (Growth) Metrics
- Device integration: 10%+ of users connect controllers
- Educational engagement: 30%+ users read at least 1 guide
- Voice/widget usage: 15%+ users interact via Siri or widgets

---

## Document History

| Date       | Version | Changes | Author |
|------------|---------|---------|--------|
| 2025-11-14 | 1.0     | Initial roadmap with 5 epics, 33 stories | Sarah (PO) |

---

*This roadmap is a living document and will be updated as priorities shift and new insights emerge.*
