# Epic 2: Pro Features & Analytics

## Status

Approved

## Summary

Deliver the Pro tier subscription features that unlock advanced functionality for serious growers:

- Unlimited plants (Free tier limited to 3)
- Advanced analytics with graphs and trend visualization
- Data export (CSV/JSON) for external analysis
- iCloud synchronization across devices
- Enhanced photo diagnostics with unlimited frequency

This epic transforms GroBro from a basic diary tool into a powerful analytics platform for growers who want deep insights into their cultivation practices.

## Business Value

- Creates a compelling monetization model with clear differentiation between Free and Pro tiers
- Targets committed growers willing to pay for advanced features
- Establishes recurring revenue through StoreKit 2 subscriptions
- Provides foundation for future B2B features (grow shop integrations, professional analytics)

## In Scope

- StoreKit 2 integration with subscription management
- Pro entitlement gating throughout the app
- Unlimited plant creation for Pro users
- Advanced analytics views (growth trends, watering patterns, event frequency)
- Data export functionality (CSV/JSON formats)
- iCloud CloudKit integration for multi-device sync
- Enhanced diagnostics frequency for Pro users
- Subscription management UI and restore purchases

## Out of Scope (for this Epic)

- B2B features and API access for grow shops
- Advanced sensor data analytics (part of Epic 3)
- RAG-based advanced AI assistant (future epic)
- Web dashboard or cross-platform clients
- Payment processing outside of Apple's ecosystem

## Epic-Level Acceptance Criteria

1. Users can discover Pro features through clear in-app prompts and a dedicated "Upgrade to Pro" screen
2. Users can purchase a Pro subscription through StoreKit 2 with proper receipt validation
3. Free users are limited to 3 plants; attempting to create a 4th plant prompts upgrade flow
4. Pro users can create unlimited plants without restrictions
5. Pro users can access an Analytics tab showing:
   - Growth timeline with photos overlay
   - Watering frequency charts
   - Event distribution graphs
   - Stage duration analytics
6. Pro users can export all plant data to CSV or JSON format
7. Pro users with iCloud enabled can sync plants and events across multiple devices automatically
8. Pro users can run unlimited photo diagnostics; Free users limited to 1 per plant per week
9. Users can manage their subscription (view status, cancel, restore purchases) from Settings
10. All Pro features gracefully degrade when subscription lapses (no data loss, read-only access to advanced features)

## Stories in This Epic

- Subscriptions:
  - `docs/stories/4.1.subscription-management-and-pro-gating.md` – StoreKit 2 integration and Pro tier gating
  - `docs/stories/4.2.subscription-ui-and-upgrade-flow.md` – Pro feature discovery and purchase UI
- Analytics:
  - `docs/stories/5.1.advanced-analytics-dashboard.md` – Analytics views and visualizations
  - `docs/stories/5.2.data-export-functionality.md` – CSV/JSON export for all plant data
- Sync:
  - `docs/stories/6.1.icloud-sync-architecture.md` – CloudKit integration and sync engine
  - `docs/stories/6.2.conflict-resolution-and-offline-support.md` – Handling sync conflicts and offline edits

Future epics can extend Pro features with sensor integrations, advanced AI, and B2B capabilities.
