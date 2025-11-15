# Epic 7: Onboarding & First-Time User Experience

## Status

Approved

## Summary

Create a welcoming, educational onboarding experience that helps new users understand GroBro's value and get started quickly:

- Welcome flow showcasing key features
- Guided first plant creation
- Interactive tutorial tooltips
- Sample data and templates for empty states
- Contextual help throughout the app

This epic ensures users experience early success, reducing churn and increasing activation rates.

## Business Value

- Reduces user churn in first 7 days (target: <30% churn)
- Increases feature discovery and adoption
- Lowers support burden through proactive education
- Improves App Store ratings (users understand app value)
- Accelerates time-to-value (first successful plant diary within 5 minutes)
- Creates upgrade opportunities by showcasing Pro features early

## In Scope

- Welcome screen with feature highlights (3-4 cards)
- Optional tutorial flow (skippable)
- Guided first plant creation with tips
- Sample plant data for new users (optional, demonstrative)
- Empty state illustrations and calls-to-action
- Contextual tooltips for first-time feature usage
- Feature discovery nudges (non-intrusive)
- Onboarding progress tracking and completion rewards
- Legal disclaimer and terms acceptance
- Optional data collection preferences

## Out of Scope (for this Epic)

- Video tutorials (future consideration)
- Gamification system (future epic)
- Social/community onboarding (future)
- Multi-language onboarding (localization epic)
- Advanced customization during onboarding

## Epic-Level Acceptance Criteria

1. New users see welcome screen on first launch with Skip and Continue options
2. Welcome flow shows 3-4 feature highlight cards with glassmorphic styling
3. Legal disclaimer and terms acceptance presented clearly
4. Guided plant creation flow with inline tips and validation
5. Sample plant option offered (user can create demo plant with pre-populated events)
6. Empty states throughout app include helpful illustrations and action prompts
7. First-time tooltips appear for key features (diagnostics, watering scheduler, etc.)
8. Tooltips are dismissible and never shown again once dismissed
9. Onboarding completion tracked (e.g., "3 of 5 steps complete")
10. Optional Pro feature teaser shown during onboarding (non-pushy)
11. All onboarding content respects Smart Greenhouse design system
12. Onboarding can be restarted from Settings

## Stories in This Epic

**Welcome & Tutorial:**
- `docs/stories/15.1.welcome-screen-and-feature-highlights.md` – Initial welcome flow
- `docs/stories/15.2.guided-first-plant-creation.md` – Step-by-step first plant
- `docs/stories/15.3.sample-data-and-demo-plant.md` – Optional demo plant with events

**Discoverability:**
- `docs/stories/15.4.empty-states-and-illustrations.md` – Helpful empty states
- `docs/stories/15.5.contextual-tooltips-and-feature-discovery.md` – First-time tooltips
- `docs/stories/15.6.onboarding-progress-and-completion.md` – Progress tracking

**Legal & Preferences:**
- `docs/stories/15.7.legal-disclaimer-and-terms-acceptance.md` – Terms flow

## Change Log

| Date       | Version | Description                            | Author |
|-----------|---------|----------------------------------------|--------|
| 2025-11-15 | 1.0     | Initial epic creation                  | Mary (BA) |
