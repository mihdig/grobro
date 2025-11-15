# Epic 5: App Intents & Siri Integration

## Status

Approved

## Summary

Integrate GroBro with Siri and Shortcuts to enable hands-free diary management and quick actions:

- Siri voice commands for common actions (log watering, add notes, check watering status)
- App Intents framework integration for Shortcuts support
- Spotlight search integration for plants and diary entries
- Suggested Shortcuts based on usage patterns
- Lock screen and home screen widgets for quick status glances

This epic makes GroBro a first-class iOS citizen by leveraging Apple's ecosystem features for seamless, hands-free interaction.

## Business Value

- Dramatically improves user convenience during hands-on growing tasks (dirty hands, gloves, etc.)
- Increases app engagement through low-friction interactions (widgets, Siri)
- Showcases technical excellence by leveraging latest Apple frameworks
- Creates competitive differentiation vs. competitors without voice integration
- Improves accessibility for users who prefer voice interaction
- Generates App Store featuring opportunities through showcase of iOS integration

## In Scope

- App Intents implementation for core actions:
  - "Log watering for [plant name]"
  - "Add note to [plant name]"
  - "When did I last water [plant name]?"
  - "Show [plant name] status"
  - "Create new plant"
- Siri integration with natural language support
- Shortcuts app integration with suggested shortcuts
- Spotlight search integration:
  - Find plants by name
  - Search diary entries
  - Quick action suggestions
- Home screen widgets:
  - Garden overview widget (multiple sizes)
  - Single plant widget with watering status
- Lock screen widgets (iOS 16+):
  - Next watering countdown
  - Recent activity badge
- Widget configuration and customization
- Intent donation for proactive Siri suggestions

## Out of Scope (for this Epic)

- Apple Watch app (separate future epic)
- Live Activities for ongoing grows
- Complex multi-step Shortcuts workflows (user can build these themselves)
- Third-party automation platform integration (Zapier, IFTTT)
- Voice-controlled diagnostics or debug console (safety concerns with AI via voice)
- Sharing Shortcuts publicly in gallery (legal liability)

## Epic-Level Acceptance Criteria

1. Users can invoke Siri with "Hey Siri, log watering in GroBro" and select from their plants
2. Users can ask Siri "When did I last water [plant name]?" and receive accurate response
3. Users can add notes to plants via Siri voice dictation
4. Shortcuts app shows suggested GroBro shortcuts based on user behavior patterns
5. Users can search for plants and diary entries in Spotlight from home screen
6. Users can add GroBro widgets to home screen showing:
   - Small: Single plant watering countdown
   - Medium: 2-3 plants with status
   - Large: Full garden overview with quick actions
7. Users can add lock screen widgets showing next watering countdown
8. Widgets deep-link to relevant plant detail or action when tapped
9. App donates intents to Siri for proactive suggestions (e.g., "Time to water Plant A" suggestion)
10. All voice interactions respect user privacy (no audio sent to GroBro servers, only Apple's on-device processing)

## Stories in This Epic

- App Intents:
  - `docs/stories/11.1.app-intents-framework-integration.md` – Core App Intents implementation
  - `docs/stories/11.2.siri-voice-commands.md` – Siri integration and natural language handling
  - `docs/stories/11.3.shortcuts-suggested-actions.md` – Shortcuts app integration and suggestions
- Search:
  - `docs/stories/11.4.spotlight-search-integration.md` – Core Spotlight and NSUserActivity
- Widgets:
  - `docs/stories/12.1.home-screen-widgets.md` – WidgetKit implementation for home screen
  - `docs/stories/12.2.lock-screen-widgets.md` – iOS 16+ lock screen widgets
  - `docs/stories/12.3.widget-configuration-and-deep-linking.md` – Widget customization and navigation

Future epics can add Apple Watch support, Live Activities, and more advanced automation features.
