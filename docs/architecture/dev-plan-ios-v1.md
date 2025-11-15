# GroBro – Dev Plan for iOS v1 (Epic 1)

This document describes a practical implementation plan for Epic 1 from a developer’s perspective. It assumes the architecture documents in `docs/architecture/` and the stories in `docs/stories/` as the source of truth.

## 1. Order of Implementation

Recommended story order (each is already in `Approved` status and ready for development):

1. `1.1 App Shell and Persistence`
2. `1.2 Plant Creation and Basic Detail`
3. `1.3 Garden View and Navigation`
4. `2.1 Diary Events and Timeline`
5. `2.2 Watering Scheduler and Reminders`
6. `3.1 L1 Diagnostics and Debug Console`

This order builds from infrastructure → basic CRUD → UX shell → smart behavior.

## 2. Story 1.1 – App Shell and Persistence (Foundation)

Key files to create/modify:

- `GroBroApp/App/AppEntry.swift` – SwiftUI `@main` entry point.  
- `GroBroApp/Persistence/GroBroModel.xcdatamodeld` – Core Data model stub.  
- `GroBroApp/Persistence/PersistenceController.swift` – Core Data stack.  
- Root view placeholder (e.g., `GardenContainerView`) under `Features/Garden/`.

Dev steps:

1. Create Xcode project with SwiftUI + Core Data and move files into the structure described in `source-tree.md`.  
2. Implement `PersistenceController` with a shared instance and an in‑memory variant for tests.  
3. Inject `PersistenceController` into the SwiftUI environment in `AppEntry`.  
4. Create a minimal root view that compiles and can later host `GardenView`.

Tests:

- Unit test that `PersistenceController` can create a container and perform a basic save/fetch cycle using an in‑memory store.

## 3. Story 1.2 – Plant Creation and Basic Detail

Key files:

- `GroBroApp/Domain/Models/Plant.swift` (or similar).  
- Core Data `Plant` entity in `GroBroModel.xcdatamodeld`.  
- `GroBroApp/Domain/Services/PlantStore.swift`.  
- `GroBroApp/Features/PlantDetail/PlantDetailView.swift`.  
- `GroBroApp/Features/PlantDetail/PlantDetailViewModel.swift`.  
- Plant creation form view under `Features/Garden/` or `Features/PlantCreation/`.

Dev steps:

1. Define `Plant` entity in Core Data aligned with `data-model.md`.  
2. Create matching domain model and mapping helpers.  
3. Implement `PlantStore` with basic CRUD operations (create, fetch all non‑archived, delete/archive).  
4. Build plant creation form UI that uses `PlantStore` to persist new plants.  
5. Implement `PlantDetailView` + ViewModel to display plant basics (photo/placeholder, name, stage, age, pot size, substrate).

Tests:

- `PlantStore` tests using in‑memory Core Data.  
- Age calculation tests.

## 4. Story 1.3 – Garden View and Navigation

Key files:

- `GroBroApp/Features/Garden/GardenView.swift`.  
- `GroBroApp/Features/Garden/GardenViewModel.swift`.

Dev steps:

1. Bind `GardenViewModel` to `PlantStore` to load plants and expose them for the UI.  
2. Implement plant card UI showing latest photo/placeholder, name, stage, age.  
3. Implement empty state with a clear CTA to create the first plant.  
4. Wire navigation from Garden card tap to `PlantDetailView` (via NavigationStack/NavigationLink).

Tests:

- GardenViewModel sorting and empty state behavior with a mocked `PlantStore`.

## 5. Story 2.1 – Diary Events and Timeline

Key files:

- Core Data `Event` entity in `GroBroModel.xcdatamodeld`.  
- `GroBroApp/Domain/Models/Event.swift`.  
- `GroBroApp/Domain/Services/EventStore.swift`.  
- `GroBroApp/Features/Diary/DiaryView.swift`.  
- `GroBroApp/Features/Diary/DiaryViewModel.swift`.

Dev steps:

1. Define `Event` entity and enums (`EventType`, `StressTag`) per `data-model.md`.  
2. Implement `EventStore` with methods for creating events per plant and fetching by plant and type.  
3. Implement Diary tab in Plant Detail:
   - Reverse chronological list of events.  
   - Type‑specific visual markers (icons/labels).  
4. Add event creation flows from Plant Detail (watering, feeding, note, photo, stress).

Tests:

- `EventStore` creation and query tests.  
- DiaryViewModel ordering and filtering tests.

## 6. Story 2.2 – Watering Scheduler and Reminders

Key files:

- `GroBroApp/Domain/Services/WateringScheduler.swift`.  
- Extensions in `GardenViewModel` and `PlantDetailViewModel` to use the scheduler.  
- Notification helpers (e.g., `NotificationManager` in `Domain/Services/` or a small `System/` folder).

Dev steps:

1. Design and implement `WateringScheduler` API:
   - Input: plant parameters + recent watering events.  
   - Output: suggested interval + next watering date.  
2. Implement feedback handling (too early / just right / too late) to adjust intervals within safe bounds.  
3. Extend GardenViewModel to compute watering status text for each plant.  
4. Add UI in Plant Detail/Watering tab to show status and collect feedback.  
5. Implement local notification scheduling and handling:
   - Request permissions.  
   - Schedule/update notifications on interval changes.  
   - Navigate to the relevant plant when a notification is tapped.

Tests:

- WateringScheduler unit tests for interval calculations and feedback adaptation.  
- Manual tests for notifications in simulator/device.

## 7. Story 3.1 – L1 Diagnostics and Debug Console

Key files:

- Core Data `DiagnosticsResult` entity.  
- `GroBroApp/Domain/Models/DiagnosticsResult.swift`.  
- `GroBroApp/Domain/Services/DiagnosticsService.swift`.  
- `GroBroApp/Domain/Services/DebugAssistantService.swift`.  
- `GroBroApp/Features/Diagnostics/DiagnosticsView.swift` + ViewModel.  
- `GroBroApp/Features/DebugConsole/DebugConsoleView.swift` + ViewModel.

Dev steps:

1. Implement `DiagnosticsResult` model and Core Data entity based on `data-model.md`.  
2. Implement `DiagnosticsService`:
   - For first pass, a placeholder or very simple model is acceptable; API should match the design in `ai-architecture.md`.  
   - Map raw outputs to enum statuses and generate checklists.  
3. Build Diagnostics UI:
   - “Check plant” action in Plant Detail.  
   - Screen showing photo, summary, checklist.  
   - Persist DiagnosticsResult linked to plant and photo event.  
4. Implement Debug Console:
   - View and ViewModel for per‑plant chat.  
   - `DebugAssistantService` that can either call a real LLM endpoint or a stub for development.  
   - Rule‑based offline/limited‑mode behavior as described in `ai-architecture.md`.

Tests:

- DiagnosticsService tests for mapping outputs → enums → checklist items.  
- DebugConsoleViewModel tests for context construction and handling of online/offline modes.

## 8. General Dev Guidelines

- Always place new code according to `source-tree.md` and respect layering:
  - Views in `Features/…`  
  - ViewModels in `Features/…`  
  - Domain logic in `Domain/`  
  - Persistence in `Persistence/`  
  - Networking/AI in `Networking/` and `Domain/Services/`
- For every story:
  - Update the story’s Dev Agent Record sections (tasks, file list, completion notes) as per BMAD dev rules.  
  - Add or update tests for new behavior.  
- Keep external dependencies minimal; prefer Apple frameworks and standard library.

