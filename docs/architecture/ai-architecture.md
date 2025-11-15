# GroBro – AI & ML Architecture

This document describes the AI and ML architecture for GroBro, focusing on safe, privacy‑aware diagnostics and assistance.

## 1. Goals

- Provide coarse, safe photo‑based diagnostics (L1) on device where possible.
- Offer a helpful debug console that uses plant history and photos to answer “what might have gone wrong?”.
- Enable future RAG‑style educational assistance without violating legal or content constraints.
- Keep user data private and minimize what is sent to external services.

## 2. L1 Diagnostics (On‑Device)

### 2.1. Pipeline

1. User captures or selects a plant photo inside the app.
2. App performs basic pre‑processing (resize, normalize, etc.).
3. Core ML model (`PlantDiagnostics.mlmodel`) runs on device:
   - Outputs logits or probabilities for:
     - Hydration classes
     - Light stress
     - Leaf condition
     - Pests suspicion
4. App maps raw model outputs to enum values:
   - `HydrationStatus`
   - `LightStressStatus`
   - `LeafConditionStatus`
   - `PestsStatus`
5. A `DiagnosticsResult` is created and persisted, including:
   - Model version
   - Status enums
   - Optional confidence score
   - Generated checklist items (human‑readable suggestions)

### 2.2. Checklist Generation

Checklist items are generated on device using deterministic rules, for example:

- If `hydrationStatus == .possibleOverwatering`:
  - Add items like:
    - "Check if water is standing in the tray."
    - "Verify that the pot has proper drainage."

Multiple statuses can contribute to a merged checklist. This keeps v1 explainability offline and predictable.

## 3. L2 Assistance (Debug Console)

The debug console can optionally use an external LLM to provide richer, conversational help.

### 3.1. Context Construction

When the user asks a question in the debug console, the app builds a context payload that may include:

- High‑level plant info (stage, age, pot/substrate, light hours).
- Recent events (e.g., last N watering/feeding/stress events).
- Most recent `DiagnosticsResult` summary (no raw model outputs).
- The user’s question text.

Sensitive or personal data should not be included:

- No user identifiers, email, or account details.
- No precise location data.
- Photos should only be sent if explicitly required and if the user has consented to cloud diagnostics.

### 3.2. LLM Call (v1+)

- App sends the constructed context to an external LLM endpoint via HTTPS.
- The prompt enforces:
  - No advice on consumption/selling.
  - No law‑bypassing guidance.
  - No hard diagnoses or medical claims.
  - Framing as horticultural guidance and observation checklists.

The LLM response is:

- Rendered as a chat message in the debug console.
- Optionally summarized and stored as part of the debug thread (without sending it back to any server).

### 3.3. Offline Behavior

- If offline or if external AI is disabled, the debug console:
  - Falls back to rule‑based responses and checklists derived from recent events and diagnostics.
  - May show “Limited mode” messaging.

## 4. RAG and Knowledge Base (Future)

### 4.1. Knowledge Sources

- Curated internal documentation on:
  - Growth stages and basic care.
  - Over/underwatering basics.
  - Light stress basics.
  - Nutrient concepts (PPM/EC) in a horticultural, non‑medical framing.

### 4.2. RAG Architecture (Phase 2+)

- Pre‑process internal docs into chunks and embed them using an embedding model.
- Store embeddings in:
  - PostgreSQL + pgvector, or
  - A dedicated vector database.
- When answering a user question:
  - Retrieve top‑K relevant chunks.
  - Construct a prompt with:
    - Retrieved content.
    - Plant context / events (high‑level).
  - Ask the LLM to answer strictly based on provided content, respecting safety rules.

### 4.3. Safety and Guardrails

- System prompt should explicitly:
  - Ban consumption/selling advice.
  - Ban medical claims.
  - Emphasize checklists, observations, and gradual adjustments.
- Responses should clearly state uncertainty where applicable.

## 5. Privacy and Data Handling

- Default assumption: diagnostics can run on device without sending images to a server.
- If future features require remote image analysis:
  - Obtain explicit, informed consent from the user.
  - Offer an option to disable cloud diagnostics.
  - Avoid storing raw images on servers unless absolutely necessary.

- Text data sent to LLMs:
  - Should be minimal and anonymized.
  - Should not contain personal identifiers or precise location data.

## 6. Logging and Telemetry

- Local logs:
  - Errors and diagnostics failures should be logged locally for debugging.
  - Do not log raw images or sensitive payloads.

- Analytics (optional, opt‑in):
  - Aggregate metrics such as:
    - Feature usage (diagnostics runs, debug console usage).
    - Anonymous error rates or model failure rates.
  - No per‑user or per‑plant identifiable tracking.

## 7. Extensibility

- L1 model:
  - Can be replaced/upgraded by shipping a new Core ML model with a new version.
  - The app should treat unknown labels gracefully and map them to `unknown` or generic states.

- L2 and RAG:
  - The app should decouple LLM provider selection behind an abstraction (e.g., `DebugAssistantService`).
  - Provider, endpoints, and keys should be configurable without changing the rest of the app.

