# GroBro – Data Model

This document defines the core data model for GroBro. It is designed to support a local‑first iOS app in v1, with the option to introduce cloud sync and analytics later without breaking compatibility.

## 1. Design Principles

- Local‑first: all primary data is stored on device in v1.
- Plant‑centric: the plant is the main aggregate root; most data hangs off plants.
- Append‑only for history: events are appended, not overwritten, to preserve the grow timeline.
- Backwards‑compatible: schema should be extendable without destructive migrations.

## 2. Core Entities (v1)

### 2.1. Plant

Represents a single plant in the user’s garden.

- `id: UUID`
- `name: String`
- `strainName: String?`
- `createdAt: Date`
- `startDate: Date` (when the grow cycle started)
- `stage: PlantStage` (enum)
- `potSizeLiters: Double?`
- `substrateType: SubstrateType?`
- `lightHoursPerDay: Double?`
- `notes: String?` (general per‑plant notes)
- `isArchived: Bool` (for completed/abandoned grows)
- `photoAssetId: String?` (reference to latest/cover photo)

`PlantStage` enum (v1):

- `seedling`
- `vegetative`
- `flowering`

Can be extended later (e.g., `drying`, `curing`) without breaking existing data.

`SubstrateType` enum (v1 examples):

- `soil`
- `coco`
- `hydro`
- `soilless`
- `other`

### 2.2. Event

Represents a single action or observation in the plant’s timeline (diary).

- `id: UUID`
- `plantId: UUID` (FK → Plant)
- `type: EventType`
- `timestamp: Date`
- `volumeLiters: Double?` (for watering/feeding)
- `nutrientProfileId: UUID?` (for feeding events, future use)
- `noteText: String?`
- `photoAssetId: String?` (for photo events or events with a photo)
- `stressTags: [StressTag]` (optional tags marking stress/important events)

`EventType` enum (v1):

- `watering`
- `feeding`
- `flush`
- `note`
- `photo`
- `stress`

`StressTag` enum (examples):

- `heatStress`
- `lightStress`
- `overwatering`
- `underwatering`
- `pests`
- `training`
- `transplant`
- `other`

The UI can display user‑friendly labels and allow multiple tags per event.

### 2.3. DiagnosticsResult

Represents the result of a photo‑based diagnostic run (L1, optionally combined with L2 explanation).

- `id: UUID`
- `plantId: UUID`
- `eventId: UUID?` (usually the associated photo event)
- `createdAt: Date`
- `modelVersion: String`
- `hydrationStatus: HydrationStatus` (enum)
- `lightStressStatus: LightStressStatus` (enum)
- `leafConditionStatus: LeafConditionStatus` (enum)
- `pestsStatus: PestsStatus` (enum)
- `overallConfidence: Double?` (0.0–1.0, optional)
- `checklistItems: [String]` (rendered to the user as bullet points)

`HydrationStatus` enum:

- `unknown`
- `normal`
- `possibleOverwatering`
- `possibleUnderwatering`

`LightStressStatus` enum:

- `unknown`
- `none`
- `possible`

`LeafConditionStatus` enum:

- `unknown`
- `normal`
- `chlorosis`
- `spots`
- `necrosis`

`PestsStatus` enum:

- `unknown`
- `notObvious`
- `possible`

### 2.4. SubscriptionState

Represents the local view of the user’s subscription and entitlements.

- `id: Int` (single row, e.g., 1)
- `tier: SubscriptionTier` (enum)
- `lastUpdatedAt: Date`
- `originalPurchaseDate: Date?`
- `expirationDate: Date?`
- `isInTrial: Bool`
- `isInGracePeriod: Bool`

`SubscriptionTier` enum:

- `free`
- `pro`

All subscription details are derived from StoreKit 2 and persisted for offline gating of features.

### 2.5. UserSettings

Represents app‑wide settings and preferences.

- `id: Int` (single row)
- `preferredUnits: UnitsPreference` (e.g., metric vs imperial)
- `notificationsEnabled: Bool`
- `diagnosticsEnabled: Bool` (for photo analysis)
- `sendAnonymousAnalytics: Bool`
- `languageCode: String?`

`UnitsPreference` enum:

- `metric`
- `imperial`

## 3. Future / Pro Entities

These entities are designed for later milestones and Pro features but can be sketched now for compatibility.

### 3.1. NutrientProfile

Describes a nutrient product or recipe used in feeding events.

- `id: UUID`
- `name: String`
- `brand: String?`
- `npkLabel: String?` (e.g., `"3-1-2"`)
- `notes: String?`

### 3.2. FeedingSchedule

Represents a planned feeding schedule tied to stages or weeks.

- `id: UUID`
- `plantId: UUID`
- `name: String`
- `createdAt: Date`
- `isActive: Bool`

Associated schedule items (simplified):

- `FeedingScheduleItem`
  - `id: UUID`
  - `scheduleId: UUID`
  - `weekIndex: Int`
  - `targetPpm: Int?`
  - `notes: String?`

### 3.3. EnvironmentSnapshot

Captures environment readings (manual or from controllers) at a point in time.

- `id: UUID`
- `plantId: UUID?` (optional; could be tent‑level)
- `timestamp: Date`
- `temperatureC: Double?`
- `humidityPercent: Double?`
- `vpd: Double?`
- `lightIntensityApprox: Double?` (e.g., derived PPFD estimate)
- `notes: String?`

## 4. Relationships

- `Plant` 1‑to‑many `Event`
- `Plant` 1‑to‑many `DiagnosticsResult`
- `Event` 0‑to‑1 `DiagnosticsResult` (via `eventId`)
- `Plant` 0‑to‑many `FeedingSchedule` (future)
- `FeedingSchedule` 1‑to‑many `FeedingScheduleItem`
- `Plant` 0‑to‑many `EnvironmentSnapshot`

All relationships should be optional where appropriate to make migrations easier.

## 5. Migration and Extensibility

- Prefer adding new optional fields and enums cases over destructive changes.
- When adding new event types or stages:
  - Keep existing cases intact.
  - Ensure UI and logic handle unknown or legacy values gracefully.
- Avoid embedding complex logic into the persistence schema; keep logic in services and view models.

