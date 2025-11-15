# GroBro – Coding Standards

This document defines coding conventions and best practices for the GroBro codebase. All contributors and AI agents should follow these guidelines.

## General Principles

- Prefer clear, maintainable code over cleverness.
- Keep features small and modular; avoid god objects and massive view or view model types.
- Place business logic in Domain and Services, not inside SwiftUI views.
- Write tests for non‑trivial logic, especially around scheduling, diagnostics mapping, and data transformations.

## Swift and SwiftUI Style

- Follow Swift API Design Guidelines.
- Naming:
  - Types: `PascalCase`
  - Methods and variables: `camelCase`
  - Avoid abbreviations unless they are standard (e.g., `URL`, `ID`, `PPM`).
- Use `struct` for SwiftUI views.
- Use appropriate property wrappers:
  - `@State` for simple local state within a view.
  - `@ObservedObject` / `@StateObject` for reference‑type view models.
  - `@EnvironmentObject` for shared app‑wide state where justified.

### View and ViewModel Separation

- Views should focus on layout and rendering.
- ViewModels should:
  - Expose state via `@Published` properties or immutable value types.
  - Provide intent methods (e.g., `onAppear()`, `onAddEvent()`, `onRunDiagnostics()`).
  - Avoid directly performing UI navigation; communicate via observable state.

## Architecture and Modules

- Follow the source tree layout described in `source-tree.md`.
- New user‑facing features belong under `Features/<FeatureName>/`.
- Shared domain logic and services belong under `Domain/` and `Domain/Services/`.
- Persistence and networking implementation details live under `Persistence/` and `Networking/`.
- Avoid cross‑module imports that break layering (e.g., views should not know about Core Data implementations).

## Testing

- Use XCTest for unit tests and view model tests.
- Minimum expectations:
  - Watering scheduler logic is covered by unit tests.
  - Diagnostics mapping from ML outputs to user‑facing messages is tested.
  - Any non‑trivial state machine or business rule should have test coverage.
- Add tests alongside new behavior; avoid large feature changes without tests when practical.

## Git and Commit Standards

- Use small, focused commits.
- Prefer Conventional Commits style for messages:
  - `feat:` – new user‑facing features
  - `fix:` – bug fixes
  - `chore:` – maintenance and tooling
  - `docs:` – documentation only
  - `refactor:` – non‑functional refactors
  - `test:` – add or update tests

Examples:

- `feat: add plant overview tab`
- `fix: correct watering interval adjustment`

## Dependencies

- Prefer Apple frameworks and the Swift standard library.
- Avoid introducing new third‑party dependencies without explicit approval.
- If a new dependency is required, it should be:
  - Added via Swift Package Manager where possible.
  - Evaluated for license, maintenance status, and security.

## Code Review Checklist

Before merging changes, ensure:

- Code compiles and tests pass.
- New code follows the layering described in the architecture docs.
- Naming and public APIs are consistent with existing patterns.
- No debug or temporary code is left behind.

