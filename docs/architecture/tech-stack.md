# GroBro – Tech Stack

This document defines the core technology choices for GroBro and serves as the reference for all development work.

## Mobile App (v1)

- **Platform:** iOS (iPhone first)
- **Language:** Swift 5+
- **UI:** SwiftUI
- **Architecture:** Modular MVVM with dependency injection via simple containers / environment objects
- **Concurrency:** Swift async/await
- **Local Storage:** Core Data (with an option to adopt CloudKit sync later)
- **Networking:** URLSession with a lightweight async/await wrapper
- **ML:** Core ML models bundled with the app for L1 diagnostics
- **In‑App Purchases:** StoreKit 2 (subscriptions)
- **Testing:** XCTest for unit tests and view model tests, optional snapshot tests

## Backend & AI Services (Future Phases)

Phase 1 of GroBro targets a local‑first architecture with no required custom backend. Later phases may introduce:

- **Backend Service (Phase 2+)**
  - Runtime: Node.js + TypeScript (e.g., NestJS or Express)
  - Database: PostgreSQL (optionally pgvector for embeddings)
  - Auth: Sign in with Apple or token‑based auth (TBD)
  - Deployment: Managed platform such as Render, Fly.io, or similar

- **AI / LLM Integration**
  - External LLM provider accessed via HTTPS
  - RAG built on top of curated GroBro documentation
  - Vector store: PostgreSQL + pgvector or a managed vector database

These backend and AI components are optional and can be introduced without breaking the local‑first iOS experience.

