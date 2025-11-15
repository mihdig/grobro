# GroBro – Frontend Architecture (iOS)

This document describes the frontend architecture for the GroBro iOS app, focusing on navigation, state management, and feature boundaries.

## 1. Architectural Style

- SwiftUI‑based UI.
- MVVM per feature module.
- Local‑first data access through domain services.
- Dependency injection via environment objects and lightweight containers.

Goals:

- Keep views declarative and simple.
- Keep business logic in view models and domain services.
- Make it easy to test ViewModels without UI.

## 2. Navigation Structure

### 2.1. App Root

- `AppEntry` creates the root view and injects shared dependencies:
  - Persistence controller
  - Domain services (PlantStore, EventStore, WateringScheduler, DiagnosticsService, SubscriptionService)
  - Global app state objects (e.g., `AppState`, `SubscriptionState`)

- Root navigation:
  - Tab or stack‑based navigation with Garden as the primary entry point.

Example structure:

- Root: `GardenView` (list of plants)
  - Navigation to `PlantDetailView` per plant
  - Access to Settings via a button/menu

### 2.2. Plant Detail Navigation

`PlantDetailView` exposes nested tabs:

- `OverviewTabView`
- `DiaryTabView`
- `WateringTabView`
- `DebugTabView`

Navigation rules:

- From Overview: quick access to logging actions (watering, notes, photos).
- From Diary: tap events to see details or edit.
- From Watering: adjust feedback or view history.
- From Debug: run diagnostics or open the debug console.

Actions such as adding events or running diagnostics should be presented as sheets or full‑screen covers where appropriate.

## 3. State Management

### 3.1. App‑Level State

- `AppState` (optional):
  - Holds global flags (e.g., first run, feature flags).
  - May hold shared navigation or error banners.

- `SubscriptionState`:
  - Exposes whether the user is on Free or Pro.
  - Used by feature modules to gate advanced functionality.

### 3.2. Feature‑Level State (ViewModels)

- `GardenViewModel`:
  - Exposes list of plants for display.
  - Handles refresh and simple filtering/sorting (e.g., by next watering).

- `PlantDetailViewModel`:
  - Holds a single plant and derived state (age, stage labels).
  - Acts as a facade for tab‑specific ViewModels when convenient.

- `DiaryViewModel`:
  - Loads and groups events by date.
  - Handles creation and editing of diary entries.

- `WateringViewModel`:
  - Uses `WateringScheduler` to compute the next watering date.
  - Applies user feedback (“too early / just right / too late”).

- `DiagnosticsViewModel`:
  - Manages the state of running diagnostics on a photo.
  - Displays results and checklist items.

- `DebugConsoleViewModel`:
  - Coordinates user messages, context construction, and LLM responses.
  - Persistently stores debug thread messages if needed.

Each ViewModel is responsible for orchestrating services but not for business rules themselves.

## 4. Data Access Pattern

- Views bind to ViewModels (`@StateObject` or `@ObservedObject`).
- ViewModels depend on domain services injected in their initializers.
- Domain services encapsulate:
  - Persistence details (Core Data / other)
  - Networking/AI calls
  - Business rules (e.g., watering adaptation logic)

No SwiftUI view should directly perform:

- Core Data fetches/saves.
- Network calls.
- AI/ML inference calls.

## 5. Error Handling and UX

- Errors from services should be:
  - Captured as states in ViewModels.
  - Presented as user‑friendly messages or banners in Views.

- Use simple, consistent patterns:
  - `@Published var errorMessage: String?` in ViewModels.
  - Views show non‑blocking alerts when `errorMessage` is not nil.

- For diagnostics and LLM calls:
  - Show clear loading indicators.
  - Offer retry options for transient failures.

## 6. Offline Behavior

- Reading:
  - All core screens (Garden, Plant Detail, Diary, Watering) work fully offline using local data.

- Writing:
  - Logging events is always allowed offline and written to local storage.

- AI:
  - L1 diagnostics are expected to work offline (Core ML).
  - If L2 (LLM) is unavailable, the debug console should:
    - Show “Limited mode” messaging.
    - Fall back to rule‑based guidance where possible.

## 7. Free vs Pro UX

- Free/Pro gating is checked via `SubscriptionState`.
- Features should show clearly when they are Pro:
  - Use labels like “Pro” next to advanced fields or analytics.
  - Tapping Pro features in Free mode should:
    - Explain the value.
    - Offer an upgrade path.

- Do not:
  - Block basic flows behind Pro (e.g., creating plants, basic logging, basic diagnostics).

## 8. Testing Strategy (Frontend)

- Unit tests:
  - For ViewModels with non‑trivial logic (e.g., WateringViewModel, DiagnosticsViewModel).
- Snapshot tests:
  - For key views once the UI is stable (Garden, PlantDetail, Diagnostics result screen).
- Use dependency injection:
  - Pass mock services to ViewModels in tests.

