# GroBro – Next Steps with Architecture

This document explains how to use the current architecture and product documentation to move the project forward, especially when working with AI agents and human developers.

## 1. Documents in Play

Key documents:

- Product / vision:
  - Notion: Product Brief, MVP Spec, Roadmap, Design System & UX Principles
  - Repo: `idea.md`, `docs/architecture.md`
- Architecture:
  - `docs/architecture/tech-stack.md`
  - `docs/architecture/source-tree.md`
  - `docs/architecture/coding-standards.md`
  - `docs/architecture/dev-environment.md`
  - `docs/architecture/data-model.md`
  - `docs/architecture/ai-architecture.md`
  - `docs/architecture/frontend-architecture.md`

These are the primary references for all roles and AI agents.

## 2. Recommended Sequence (Human + AI Team)

### Step 1 – Finalize Product Scope (PM / Analyst)

- Validate that the Notion Product Brief and MVP Spec match the latest decisions.
- Ensure the Roadmap aligns with:
  - v1.0: local‑first iOS app with garden, plant profiles, watering logic, L1 diagnostics, debug console, Free/Pro tiers.
  - v1.1: Pro layers (nutrients, PPM/EC, analytics, early RAG).
  - v2.0: connectivity (controllers), light assistant, deeper AI.

If changes are needed, update the Notion docs first, then adjust architecture docs if necessary.

### Step 2 – Prepare Stories (PO)

- For v1.0, create stories based on the MVP Spec and Frontend Architecture:
  - Example story groups:
    - Garden screen and plant creation flow
    - Plant detail tabs (Overview, Diary, Watering, Debug)
    - Watering scheduler and feedback loop
    - L1 diagnostics integration and checklist generation
    - Debug console (local + LLM mode)
    - Subscriptions (Free vs Pro gating)
- Ensure each story references:
  - The relevant sections in Product Brief and MVP Spec.
  - Relevant architecture docs (frontend, data model, AI).

### Step 3 – Set Up the iOS Project (Dev)

Using:

- `docs/architecture/dev-environment.md`
- `docs/architecture/tech-stack.md`
- `docs/architecture/source-tree.md`

Developers (or AI dev agents) should:

1. Create the Xcode project / workspace with the recommended module layout.
2. Add initial Domain models (`Plant`, `Event`, `DiagnosticsResult`, `SubscriptionState`, `UserSettings`).
3. Set up persistence (Core Data model) matching `data-model.md`.
4. Create skeleton feature modules (Garden, PlantDetail, Diary, Watering, Diagnostics, DebugConsole, Settings).
5. Add a minimal set of unit tests for the first services (e.g., WateringScheduler).

### Step 4 – Implement Stories Incrementally (Dev)

- Work story by story, keeping changes small and focused.
- Follow:
  - `coding-standards.md` for style and structure.
  - `frontend-architecture.md` for navigation and state patterns.
  - `ai-architecture.md` for any diagnostics and debug console behavior.
- For each story:
  - Implement feature code under `Features/`.
  - Add or update domain logic in `Domain/Services/`.
  - Add tests for new business logic.

### Step 5 – Quality & QA (QA)

- Use:
  - Product Brief and MVP Spec to define acceptance criteria.
  - `ai-architecture.md` and `data-model.md` to design test scenarios for:
    - Watering schedule behavior.
    - Diagnostics mapping.
    - Debug console responses (where feasible).
- Maintain QA findings linked back to story IDs and architecture decisions.

## 3. When to Update Architecture Docs

Update the architecture documents when:

- A new major feature (e.g., connectivity, light assistant, RAG) moves from “future” to “planned”.
- Data model changes (new entities, fields, or relationships).
- Tech stack changes (e.g., different backend, new ML approach).

Always:

- Propose changes explicitly (which file/section).
- Keep docs concise and focused.

## 4. How AI Agents Should Use These Docs

- **Analyst / PM / PO**:
  - Use architecture docs to ensure stories and product decisions are technically realistic.
  - Reference these docs in stories so dev agents know where to look.

- **Dev**:
  - Treat architecture docs and Product Brief as constraints, not suggestions.
  - Avoid ad‑hoc decisions that contradict documented architecture.
  - If a story requires deviation, flag it and propose an architecture doc update.

- **QA**:
  - Use data model and AI architecture to design thorough, risk‑based tests.
  - Document quality gates with clear reference to these docs.

## 5. Immediate “Next Moves”

With the current documentation in place, the next recommended steps are:

1. **Create or update Notion pages** so they mirror the content in `docs/architecture/*.md` and the product brief we defined.
2. **Have the PM/PO draft the first batch of v1.0 stories** for:
   - Garden and plant creation
   - Plant detail tabs
   - Watering logic and reminders
   - L1 diagnostics and checklists
   - Debug console
   - Free vs Pro gating
3. **Set up the initial iOS project** in Xcode according to `source-tree.md` and `dev-environment.md`.
4. **Start implementation with AI dev agents** using BMAD stories and these architecture guides.
5. **Bring in QA early** to review AI and data flows against `ai-architecture.md` and to plan tests.

This closes the loop from vision → architecture → implementation → quality in a way that both humans and AI agents can follow consistently.

