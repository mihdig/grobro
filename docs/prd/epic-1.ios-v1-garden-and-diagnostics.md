# Epic 1: iOS v1 Garden & Diagnostics

## Status

Approved

## Summary

Deliver the first usable version of GroBro as a local‑first iOS app that allows growers to:

- Create and manage plants in a Garden view.  
- View basic plant details and growth stage.  
- Log key events in a per‑plant diary.  
- Get adaptive watering suggestions and reminders.  
- Run L1 photo diagnostics and use a debug console for soft, checklist‑style guidance.

This epic covers the vertical slice from a fresh install to a user being able to track at least one plant end‑to‑end with basic diagnostics, entirely on device.

## Business Value

- Provides a tangible, testable product that demonstrates GroBro’s core value proposition.  
- Establishes the architectural foundation for future Pro features (PPM/EC, nutrients, RAG, integrations).  
- Enables early internal testing and potential TestFlight distribution to gather feedback before public App Store release.

## In Scope

- iOS app shell and persistence (Core Data).  
- Garden view with plant list and navigation.  
- Plant creation and basic detail screen.  
- Per‑plant diary/timeline with key event types.  
- Watering scheduler and local notifications.  
- L1 photo diagnostics (Core ML or placeholder) and debug console with safe AI integration and offline fallback.  
- Free vs Pro gating scaffolding (basic, if time permits; detailed monetization can be a follow‑up epic).

## Out of Scope (for this Epic)

- Full Pro feature set (advanced nutrients/PPM analytics, full RAG assistant).  
- Device integrations (Vivosun, AC Infinity) and camera‑based light assistant.  
- Cross‑platform clients (Android, web).  
- Backend sync and multi‑device support.

## Epic-Level Acceptance Criteria

1. A new user can install GroBro on iOS, create at least one plant, and see it in a Garden view.  
2. The user can open a plant and see a detail screen showing stage, age, and basic parameters.  
3. The user can log diary events (watering, feeding, notes, photos, stress) per plant and see them in a timeline.  
4. The app computes a suggested watering interval per plant, adapts it based on feedback, and shows a clear “water in X days / overdue by X days” status, along with local reminders.  
5. The user can run an L1 diagnostic on a photo from Plant Detail and see a soft, checklist‑style result for hydration, light stress, leaf condition, and pests suspicion.  
6. The user can open a per‑plant debug console, describe concerns, and receive safe, hypothesis‑based guidance; if external AI is unavailable, the console falls back to a rule‑based “limited mode”.  
7. All core flows work offline using local storage; the app does not depend on a backend for basic functionality.  
8. The implementation conforms to the architecture and coding standards in `docs/architecture/`.

## Stories in This Epic

- Foundation:
  - `docs/stories/1.1.app-shell-and-persistence.md` – App shell and persistence.
- Garden and Plant Detail:
  - `docs/stories/1.2.plant-creation-and-detail.md` – Plant creation and basic detail.
  - `docs/stories/1.3.garden-view-and-navigation.md` – Garden view and navigation.
- Diary and Watering:
  - `docs/stories/2.1.diary-events-and-timeline.md` – Diary events and timeline.
  - `docs/stories/2.2.watering-scheduler-and-reminders.md` – Watering scheduler and reminders.
- Diagnostics and Debug:
  - `docs/stories/3.1.diagnostics-and-debug-console.md` – L1 diagnostics and debug console.

Future epics can extend this with Pro features, integrations, and additional analytics.

