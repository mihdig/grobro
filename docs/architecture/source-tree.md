# GroBro – Source Tree Layout (iOS)

This document describes the recommended structure of the iOS project so that all contributors and AI agents place new code in the right locations.

## High-Level Structure

At the repository root, the iOS app should live in a top‑level folder, for example:

- `GroBroApp/`
  - `App/`
  - `Features/`
  - `Domain/`
  - `Persistence/`
  - `Networking/`
  - `Resources/`
  - `MLModels/`
- `GroBroTests/`

The exact folder name for the app target can be adjusted if needed, but the internal module layout should follow the structure below.

## App Layer

- `App/AppEntry.swift`
  - SwiftUI `@main` application entry point
  - Configures shared environment objects and dependency injection

- `App/AppRouter.swift`
  - High‑level navigation and routing (if a coordinator pattern is used)

## Features

Each major user‑facing area lives under `Features/` as a separate module:

- `Features/Garden/`
  - `GardenView.swift`
  - `GardenViewModel.swift`
  - `GardenModels.swift`

- `Features/PlantDetail/`
  - `PlantDetailView.swift`
  - `PlantDetailViewModel.swift`
  - `Tabs/` (Overview, Diary, Watering, Debug)

- `Features/Diary/`
- `Features/Watering/`
- `Features/Diagnostics/`
- `Features/DebugConsole/`
- `Features/Settings/`

View code belongs in `Features`, while cross‑cutting business logic is placed under `Domain` and `Services`.

## Domain and Services

- `Domain/Models/`
  - Core types such as `Plant`, `Event`, `DiagnosticsResult`, subscription state, and configuration types

- `Domain/Services/`
  - `PlantStore.swift` – CRUD operations over plant data
  - `EventStore.swift` – CRUD operations over events/diary entries
  - `WateringScheduler.swift` – business logic for watering intervals and feedback adaptation
  - `DiagnosticsService.swift` – wrapper over Core ML models for L1 diagnostics
  - `DebugAssistantService.swift` – wrapper over external LLM APIs (when enabled)
  - `SubscriptionService.swift` – StoreKit 2 subscription management

Domain and services should be UI‑agnostic and testable via unit tests.

## Persistence

- `Persistence/CoreData/`
  - `GroBroModel.xcdatamodeld` – Core Data model
  - `PersistenceController.swift` – Core Data stack setup and access helpers

Alternative persistence (e.g., SQLite) can be introduced if required but should remain behind a clear abstraction.

## Networking

- `Networking/HTTPClient.swift`
  - Thin wrapper around URLSession with async/await

- `Networking/APIEndpoints.swift`
  - Centralized definition of external endpoints (LLM provider, backend services in later phases)

## Resources and ML Models

- `Resources/Assets.xcassets` – colors, icons, images
- `Resources/Localization/` – localized strings when introduced
- `MLModels/` – bundled Core ML models such as `PlantDiagnostics.mlmodel`

## Tests

- `GroBroTests/`
  - Unit tests for Domain and Services
  - ViewModel tests for non‑trivial feature logic
  - Snapshot tests for key screens where appropriate

