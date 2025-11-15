# GroBro Development Continuation Plan

**Last Updated:** November 14, 2025
**Current Status:** Stories 4.1, 4.2, 6.1, 6.2 complete; Epic 1 & 2 foundation ready
**Next Phase:** Non-stop development through Epic 2 completion → Epic 3 kickoff

---

## Current State Summary

### ✅ Completed Stories
- **Epic 1 (MVP Foundation):**
  - 1.1 App Shell and Persistence
  - 1.2 Plant Creation and Detail
  - 1.3 Garden View and Navigation
  - 2.1 Diary Events and Timeline
  - 2.2 Watering Scheduler and Reminders (Ready for Review)
  - 3.1 L1 Diagnostics and Debug Console (Ready for Review)

- **Epic 2 (Monetization):**
  - 4.1 Subscription Management and Pro Gating ✅ **COMPLETE**
  - 4.2 Subscription UI and Upgrade Flow ✅ **COMPLETE**
  - 6.1 iCloud Sync Architecture ✅ **COMPLETE**
  - 6.2 Conflict Resolution and Offline Support ✅ **COMPLETE**

### 🚧 Remaining Epic 2 Stories
- 5.1 Advanced Analytics Dashboard
- 5.2 Data Export Functionality

---

## Non-Stop Development Plan

### Phase 1: Complete Epic 2 (Immediate - Week 1-2)

**Priority:** P0 - Critical Path for v1.1 launch

#### Story 5.1: Advanced Analytics Dashboard
**Estimated Effort:** 3-5 days
**Dependencies:** None (Pro gating from 4.1 ready)

**Key Deliverables:**
- Growth timeline visualization
- Watering frequency charts
- Event distribution graphs
- Stage duration analytics
- Pro gating integration

**Technical Approach:**
- Use Swift Charts (iOS 16+) for native charting
- Create AnalyticsDataService for data aggregation
- Implement efficient Core Data queries with caching
- Build reusable chart components

**Success Criteria:**
- All 5 chart types implemented and performant
- Pro users can view analytics; Free users see upgrade prompt
- Charts handle sparse data gracefully
- Export to image functionality works

---

#### Story 5.2: Data Export Functionality
**Estimated Effort:** 2-3 days
**Dependencies:** Analytics complete (helps validate export data)

**Key Deliverables:**
- CSV export (plants + events tables)
- JSON export (structured, nested format)
- Export scope filtering (single plant / all / date range)
- iOS Share Sheet integration
- README file generation

**Technical Approach:**
- Create DataExportService with async processing
- Implement CSV serializer with proper escaping
- Use Codable for JSON export
- Generate temporary files and ZIP bundle
- Privacy filter to strip sensitive data

**Success Criteria:**
- Pro users can export full data to CSV/JSON
- Free users see upgrade prompt
- Exported files open correctly in Excel/Numbers
- Progress indicator shows for large datasets

---

### Phase 2: Epic 3 Quick Wins (Week 3-4)

**Priority:** P1 - High-value, standalone features

#### Story 9.1: Camera-Based Light Meter 🆕
**Estimated Effort:** 5-7 days
**Dependencies:** None (standalone feature)

**Why Start Here:**
- **High user value:** Replaces need for $200+ PAR meter
- **Competitive differentiator:** Few grow apps have this
- **Standalone:** Doesn't depend on other Epic 3 stories
- **Testable:** Easy to validate with Photone comparison

**Key Deliverables:**
- AVFoundation camera sensor integration
- PPFD, Lux, DLI calculations
- Light type calibration (LED, HPS, sunlight)
- Real-time measurement UI with freeze/capture
- Diary integration (log measurements as events)
- Stage-based recommendations (optimal ranges)

**Technical Approach:**
- Use AVCaptureDevice for camera sensor data (ISO, exposure, aperture)
- Implement calibration coefficients per light spectrum
- Create LightMeterService for calculations
- Build camera preview UI with real-time overlays
- Visual indicators (green/yellow/red zones)

**Success Criteria:**
- Measurements within ±30% of Photone app
- Smooth 60fps camera feed
- Logs to diary correctly
- Stage-based recommendations accurate

---

### Phase 3: Epic 3 Continued (Week 5-8)

#### Story 9.2: Light Distance Measurement (AR)
**Estimated Effort:** 3-4 days
**Dependencies:** Story 9.1 (light meter)

**Key Deliverables:**
- ARKit-based distance measurement
- Point camera at light, then at canopy to measure distance
- Combine with Story 9.1 light intensity for full picture
- Recommendations: "Move light 6 inches closer" based on PPFD + distance

---

#### Story 9.3: Light Recommendations Engine
**Estimated Effort:** 2-3 days
**Dependencies:** Stories 9.1, 9.2

**Key Deliverables:**
- Intelligent recommendations combining intensity + distance
- Stage-specific guidance (seedling needs less, flower needs more)
- Light type considerations (LED vs HPS optimal distances)
- Safety warnings (light burn risk)

---

#### Story 8.1: Environmental Data Timeline
**Estimated Effort:** 3-4 days
**Dependencies:** None (prepares for 7.x integrations)

**Key Deliverables:**
- Extend Event model for environmental data (temp, humidity, VPD)
- Timeline view for environmental events
- Manual entry UI (for users without controllers)
- Foundation for auto-logging from devices (Stories 7.1-7.3)

---

### Phase 4: Device Integrations (Week 9-12)

**Note:** Requires API access/partnerships, may shift timeline

#### Story 7.1: Vivosun Integration
**Estimated Effort:** 5-7 days
**Blockers:** Vivosun API access required

#### Story 7.2: AC Infinity Integration
**Estimated Effort:** 5-7 days
**Blockers:** AC Infinity API access required

#### Story 7.3: Device Pairing and Room Management
**Estimated Effort:** 3-4 days
**Dependencies:** Stories 7.1, 7.2

---

### Phase 5: Environmental Analytics (Week 13-15)

#### Story 8.2: Environmental Analytics Dashboard
**Estimated Effort:** 4-5 days
**Dependencies:** Story 8.1, device integrations (7.1-7.3)

#### Story 8.3: Threshold Alerts and Notifications
**Estimated Effort:** 3-4 days
**Dependencies:** Story 8.2

---

## Development Velocity & Milestones

### Sprint Schedule (2-week sprints)

**Sprint 1 (Now - Week 2):**
- ✅ Complete Story 5.1 (Analytics)
- ✅ Complete Story 5.2 (Export)
- 🎯 **Milestone:** Epic 2 Complete, v1.1 launch ready

**Sprint 2 (Week 3-4):**
- ✅ Complete Story 9.1 (Light Meter)
- ✅ Start Story 9.2 (AR Distance)
- 🎯 **Milestone:** Light Meter shipped, major differentiator live

**Sprint 3 (Week 5-6):**
- ✅ Complete Story 9.2 (AR Distance)
- ✅ Complete Story 9.3 (Light Recommendations)
- ✅ Start Story 8.1 (Environmental Timeline)
- 🎯 **Milestone:** Complete Light Assistant suite

**Sprint 4 (Week 7-8):**
- ✅ Complete Story 8.1 (Environmental Timeline)
- ✅ Pursue device integration partnerships (7.1, 7.2)
- 🎯 **Milestone:** Environmental foundation ready

**Sprint 5-6 (Week 9-12):**
- ⚠️ Device integrations (API-dependent)
- 🎯 **Milestone:** First device integration live

---

## Priority Rationale

### Why Story 9.1 (Light Meter) After Epic 2?

1. **Standalone Value:** Doesn't require device integrations or partnerships
2. **High User Demand:** Growers need light measurements, PAR meters are expensive
3. **Competitive Edge:** Few grow diary apps have camera-based light meters
4. **Technical Feasibility:** Well-understood approach (Photone exists as reference)
5. **Quick Win:** Can ship in 1 week, immediate user impact
6. **Foundation:** Prepares for Stories 9.2-9.3 (AR distance, recommendations)

### Why Delay Device Integrations (7.1-7.3)?

- **External Dependency:** Requires API access/partnerships (may take weeks/months)
- **Can Run in Parallel:** Business dev pursues APIs while dev builds light meter
- **Graceful Degradation:** Manual environmental logging (8.1) works without APIs
- **Risk Mitigation:** Don't block high-value features on external parties

---

## Release Strategy

### v1.1 - Epic 2 Complete (Week 2)
**Features:**
- ✅ Pro subscriptions with StoreKit 2
- ✅ Advanced analytics dashboard
- ✅ Data export (CSV/JSON)
- ✅ iCloud sync across devices
- 🎯 **Goal:** Monetization live, recurring revenue starts

**Launch Checklist:**
- [ ] All Epic 2 stories complete and tested
- [ ] StoreKit sandbox testing complete
- [ ] TestFlight beta with 20+ users
- [ ] App Store submission ready
- [ ] Marketing materials prepared
- [ ] Pro feature demo video

---

### v1.2 - Light Meter & Assistant (Week 4)
**Features:**
- ✅ Camera-based light meter (PPFD, Lux, DLI)
- ✅ Light type calibration
- ✅ Stage-based recommendations
- 🎯 **Goal:** Major competitive differentiator, no hardware required

**Launch Checklist:**
- [ ] Story 9.1 complete and validated vs Photone
- [ ] Accuracy disclaimer and calibration flow tested
- [ ] App Store feature submission (potential featuring for unique feature)
- [ ] Educational content: "How to use the light meter"
- [ ] Social proof: comparison videos vs Photone

---

### v1.3 - Full Light Assistant (Week 6)
**Features:**
- ✅ AR-based light distance measurement
- ✅ Combined intensity + distance recommendations
- ✅ Light burn risk warnings
- 🎯 **Goal:** Complete light management suite

---

### v1.4 - Environmental Monitoring (Week 8+)
**Features:**
- ✅ Manual environmental data logging
- ✅ Environmental timeline and charts
- ⏳ Device integrations (if APIs ready)
- 🎯 **Goal:** Full grow room monitoring

---

## Risk Management

### Technical Risks

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Camera light sensing accuracy | High | Medium | Calibration profiles, accuracy disclaimer, validation vs Photone |
| Device API availability | High | High | Build manual logging first, device integration is enhancement |
| iOS camera permission denial | Medium | Low | Clear permission prompt, graceful fallback |
| Swift Charts iOS 16+ requirement | Low | Low | Confirmed in CLAUDE.md, iOS 18+ target |

### Business Risks

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Vivosun/AC Infinity partnership delay | Medium | High | Build manual logging, pursue partnerships in parallel |
| Light meter accuracy complaints | Medium | Medium | Clear disclaimers, calibration flow, comparison content |
| Pro conversion below 5% | High | Medium | A/B test pricing, trial length, feature messaging |

---

## Success Metrics

### Epic 2 (v1.1) Metrics
- **Conversion:** 5%+ Free → Pro within 30 days
- **Revenue:** $X MRR target (define based on business goals)
- **Export Usage:** 20%+ Pro users export data monthly
- **Analytics Engagement:** 40%+ Pro users view analytics weekly

### Story 9.1 (Light Meter) Metrics
- **Feature Adoption:** 50%+ users try light meter within first week
- **Measurement Frequency:** 3+ measurements per user per plant cycle
- **Accuracy Satisfaction:** <10% negative reviews mentioning accuracy issues
- **Competitive Benchmark:** Readings within ±30% of Photone app

---

## Team Capacity Planning

### Assumptions
- **1 Dev Agent** (full-time equivalent)
- **1 PO** (Sarah - part-time, story prep and review)
- **2-week sprints**
- **~5 story points per sprint** (varies by complexity)

### Story Point Estimates
- Story 5.1 (Analytics): 5 points
- Story 5.2 (Export): 3 points
- Story 9.1 (Light Meter): 8 points
- Story 9.2 (AR Distance): 5 points
- Story 9.3 (Recommendations): 3 points
- Story 8.1 (Env Timeline): 5 points
- Story 7.1 (Vivosun): 8 points (API-dependent)
- Story 7.2 (AC Infinity): 8 points (API-dependent)

### Sprint Allocation
- **Sprint 1:** 8 points (5.1 + 5.2)
- **Sprint 2:** 8 points (9.1)
- **Sprint 3:** 8 points (9.2 + 9.3)
- **Sprint 4:** 5 points (8.1) + API partnership pursuit

---

## Next Actions

### Immediate (This Week)
1. ✅ **Dev:** Start Story 5.1 (Advanced Analytics Dashboard)
2. ✅ **PO:** Review Story 5.1 acceptance criteria and dev notes
3. ✅ **PO:** Prep Story 5.2 for immediate pickup after 5.1
4. ✅ **Marketing:** Plan v1.1 launch messaging (Pro features)

### Week 2
1. ✅ **Dev:** Complete Story 5.1, start Story 5.2
2. ✅ **PO:** Review Story 9.1 (Light Meter) and finalize tech approach
3. ✅ **Business:** Begin outreach to Vivosun/AC Infinity for API access
4. ✅ **QA:** TestFlight recruitment and v1.1 testing plan

### Week 3
1. ✅ **Dev:** Start Story 9.1 (Light Meter)
2. ✅ **PO:** Create Stories 9.2, 9.3, 8.1 (detailed task breakdown)
3. ✅ **Marketing:** Prepare light meter launch content (comparison videos)
4. ✅ **App Store:** Submit v1.1 for review

---

## Epic 4 & 5 Planning (Future)

**Note:** Epics 4 (Knowledge Base) and 5 (Siri/Widgets) are **planned but not yet prioritized** for immediate development.

**When to Start:**
- **Epic 4:** After first device integration ships (Week 12+)
- **Epic 5:** After knowledge base foundation (Week 16+)

**Why Wait:**
- Focus on core value first (plant tracking, monetization, light tools, environmental monitoring)
- Knowledge base and Siri are **polish** features, not **core differentiators**
- Data shows users prioritize accuracy of tracking over ecosystem integration

---

## Document Maintenance

This plan should be updated:
- **Weekly:** After each sprint review to adjust estimates
- **Monthly:** To reflect market feedback and priority changes
- **Ad-hoc:** When external blockers (API access) resolve or new risks emerge

**Owner:** Sarah (Product Owner)
**Reviewers:** Dev Team, Stakeholders

---

*This is a living document. As stories complete, move sections from "Remaining" to "Completed" and update timelines based on actual velocity.*
