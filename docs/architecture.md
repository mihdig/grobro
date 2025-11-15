# GroBro – Architecture Overview

This document provides a high‑level overview of the GroBro system architecture. Detailed, sharded documents live under `docs/architecture/`.

## 1. System Overview

GroBro v1 is a local‑first iOS application with:

- An on‑device data store for plants, events, and configuration.
- On‑device or privacy‑preserving ML models for L1 photo diagnostics.
- Optional calls to external AI services for text‑based assistance.
- StoreKit 2 integration for managing subscriptions and Pro entitlements.

Future phases may introduce:

- A backend service for optional multi‑device sync and analytics.
- Read‑only integrations with grow controllers.
- More advanced AI pipelines (RAG, multi‑image analysis).

## 2. Main Components

- **iOS App (SwiftUI)**
  - Feature modules for Garden, Plant Detail, Diary, Watering, Diagnostics, Debug Console, and Settings.
  - MVVM architecture with clear separation between views, view models, domain logic, and persistence.

- **Local Persistence**
  - Core Data (or an equivalent abstraction) for storing plants, events, and configuration on device.

- **ML and AI**
  - Core ML models bundled in the app for coarse, safe plant diagnostics (hydration, light stress, leaf condition, pests signals).
  - Optional integration with external LLM providers for debug console responses and educational content.

- **Subscriptions**
  - StoreKit 2 for handling in‑app subscriptions and Pro entitlements.

## 3. Sharded Architecture Documents

The architecture is described in more detail in the following documents:

- `docs/architecture/tech-stack.md` – technology choices and rationale.
- `docs/architecture/source-tree.md` – source tree layout and module boundaries.
- `docs/architecture/coding-standards.md` – coding style, testing, and commit standards.
- `docs/architecture/dev-environment.md` – recommended development environment and tooling.

These documents together define how GroBro should be built and maintained across phases.

