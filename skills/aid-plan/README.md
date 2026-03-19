
# High-Level Roadmap

Take SPEC.md and produce a strategic roadmap: MVP definition, module identification, deliverable scoping, test scenario definition, and risk assessment. Plan answers "what do we build and in what order?" Detail (aid-detail) answers "how do we build it?"

## Core Principle

**Plan is strategy. Detail is tactics.** Plan identifies what the MVP is, what modules exist, what deliverables make sense, and what test scenarios prove the system works. It does NOT decompose features into individual tasks or define execution waves — that's aid-detail's job. A good plan gives the Detail phase enough structure to work with, but doesn't micromanage.

## Inputs

- `SPEC.md` — what to build.
- `knowledge/` directory — for scoping and risk assessment. Read at minimum:
  - `architecture.md` — to understand module boundaries.
  - `module-map.md` — to identify affected modules.
  - `tech-debt.md` — to anticipate complications.
  - `test-landscape.md` — to define test scenarios.

## Process

### Step 1: Define the MVP

Identify the minimum viable product — the smallest set of features that delivers value:

- Which features from SPEC.md are Must-have for first release?
- What's the smallest shippable unit that proves the concept?
- What can be deferred without blocking the core value proposition?

```markdown
## MVP Definition

**Core value:** {One sentence — what the MVP proves}

**Included features:**
- Feature A (Must) — {why it's essential}
- Feature B (Must) — {why it's essential}
- Feature C (Should) — {included because it unblocks A}

**Deferred to v2:**
- Feature D (Should) — {why it can wait}
- Feature E (Could) — {nice-to-have, not blocking}
```

### Step 2: Identify Modules

Map the features to system modules — logical groupings of functionality:

```markdown
## Module Map

### Module: Recording Engine
**Features:** A, B
**Existing code:** knowledge/module-map.md → RecordingService, AudioCapture
**New code:** TranscriptionService, ExportManager
**Risk:** Medium — touches existing audio pipeline

### Module: User Interface
**Features:** C, F
**Existing code:** Views/, ViewModels/
**New code:** New views for transcription, export dialogs
**Risk:** Low — follows established MVVM patterns
```

For each module:
- What features does it contain?
- Does it touch existing code or is it entirely new?
- What's the risk level (based on tech debt, test coverage, complexity)?

### Step 3: Scope Deliverables

Group modules into deliverables — shippable increments:

**Good deliverable boundaries:**
- Features that touch different modules with no shared state.
- Features with a natural progression (core before extensions).
- Features that can be tested independently.

**Bad deliverable boundaries:**
- Splitting a feature across deliverables when both halves are needed.
- Grouping unrelated features just to fill a sprint.

```markdown
## Deliverables

### Deliverable 1: Core Recording
**Modules:** Recording Engine (core)
**Features:** A, B
**Depends on:** Nothing (first deliverable)
**Validates:** Audio capture pipeline works end-to-end

### Deliverable 2: Transcription
**Modules:** Recording Engine (transcription), UI (transcription views)
**Features:** C, D
**Depends on:** Deliverable 1
**Validates:** Whisper integration, transcription accuracy

### Deliverable 3: Export & Polish
**Modules:** UI (export), Recording Engine (export)
**Features:** E, F
**Depends on:** Deliverable 1
**Validates:** Multi-format export, UI completeness
```

### Step 4: Define Test Scenarios

For each deliverable, define the high-level test scenarios that prove it works:

```markdown
## Test Scenarios

### Deliverable 1: Core Recording
- **TS-01:** Record 5-second audio → file saved → playback matches input
- **TS-02:** Record > 60 minutes → auto-save triggers, no data loss
- **TS-03:** Cancel mid-recording → no orphaned files
- **TS-04:** Concurrent recording attempt → clear error, no crash

### Deliverable 2: Transcription
- **TS-05:** Transcribe 30-second clear speech → accuracy > 90%
- **TS-06:** Transcribe empty audio → graceful handling, no crash
```

Test scenarios are NOT test specs. They describe what to prove, not how to test it. The Detail phase turns these into task-level test requirements.

### Step 5: Risk Assessment

Identify risks that could derail the plan:

```markdown
## Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|-----------|------------|
| Whisper API latency > 5s | High | Medium | Spike: benchmark in Step 1 |
| Audio library incompatible with Linux | High | Low | Test early in Deliverable 1 |
| Tech debt in RecordingService | Medium | High | Budget extra time in Deliverable 1 |
```

### Step 6: Identify Spikes

A spike is a time-boxed research task needed before planning can be finalized:

**Generate a spike when:**
- A deliverable requires technology the team hasn't used.
- A risk needs investigation before committing to a plan.
- The KB has an open question that blocks deliverable scoping.

Spikes are documented in PLAN.md and executed before the Detail phase.

## Output

`PLAN.md` — the high-level roadmap containing:
- MVP definition.
- Module map.
- Deliverables with ordering and dependencies.
- Test scenarios per deliverable.
- Risk assessment.
- Spikes (if any).

## Feedback Loops

### → Discovery (Loop 3)

**Trigger:** Planning reveals the KB is incomplete.

**Protocol:**
1. Generate GAP.md:
   ```markdown
   # GAP: GAP-{id}
   **Source:** aid-plan, Deliverable {id}
   **Type:** discovery-needed
   **Description:** {What's missing from the KB}
   **KB Gap:** {Which document(s) need updating}
   **Blocking:** {Which deliverables can't be scoped}
   **Resolution:** discovery
   ```
2. Trigger targeted aid-discover.
3. KB updated → resume planning with corrected data.

### → Specify (Loop 4)

**Trigger:** The spec is ambiguous or contradictory.

**Protocol:**
1. Generate GAP.md:
   ```markdown
   # GAP: GAP-{id}
   **Source:** aid-plan, Deliverable {id}
   **Type:** ambiguity | contradiction
   **Description:** {What's unclear in the spec}
   **Blocking:** {Which deliverables can't be scoped}
   **Resolution:** needs-interview | spec-revision
   ```
2. If `needs-interview` → trigger targeted aid-interview.
3. If `spec-revision` → trigger aid-specify revision.
4. Updated spec → resume planning.

### ← Detail (plan too vague)

If the Detail phase can't decompose the plan into tasks because deliverables are too broad or modules are unclear:

1. Receive feedback from aid-detail identifying the gap.
2. Revise the specific section of PLAN.md.
3. Detail resumes with corrected plan.

## Quality Checklist

- [ ] MVP is clearly defined with justification.
- [ ] Every feature in SPEC.md is assigned to a deliverable (or explicitly deferred).
- [ ] Module boundaries are clear and match KB architecture.
- [ ] Deliverables have meaningful dependencies (not arbitrary grouping).
- [ ] Test scenarios are defined for every deliverable.
- [ ] Risks are assessed with mitigations.
- [ ] Spikes are identified for uncertain areas.

## See Also

- [AID Methodology](../../business/playbook-v2/aid-methodology.md) — The complete methodology.
