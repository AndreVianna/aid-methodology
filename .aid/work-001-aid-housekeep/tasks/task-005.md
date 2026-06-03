# task-005: Real SUMMARY-DELTA body — `state-summary-delta.md` (replaces the stub)

**Type:** IMPLEMENT

**Source:** feature-003-summary-delta-refresh → delivery-002

**Depends on:** task-001, task-002, task-003, task-004

**Scope:**
- **Replace** the delivery-001 stub no-op at
  `canonical/skills/aid-housekeep/references/state-summary-delta.md` (authored by task-003) with
  the **real SUMMARY-DELTA body** — short, step-numbered prose in the style of
  `canonical/skills/aid-summarize/references/state-*.md` (feature-003 SPEC § Feature Flow). This
  feature ships **no new `canonical/scripts/`** and **no new dedicated test suite** (feature-003
  SPEC § "No new scripts" + § Testing — justified): it is pure delegation plus a three-way result
  classification.
- **Step 0 — C1 guard:** read `**KB Stage:**` from `## Housekeep Status` via feature-001's
  `canonical/scripts/housekeep/housekeep-state.sh`; if it is not `passed` or `skipped`, refuse to
  run (defensive restatement of the C1 invariant; the read itself is feature-001's gate, no new
  gate machinery — feature-003 SPEC § Ordering precondition). Note in the body that
  `/aid-summarize`'s own `summarize-preflight.sh` (`requires **User Approved:** yes`) is a second,
  independent confirmation.
- **Step 1 — state-entry banner:** print the "you are here" map and **warn** the user that a
  regeneration will require them to open and visually confirm the HTML (the V1 human gate fired by
  `/aid-summarize`), per NFR3 transparency (feature-003 SPEC § The V1 human gate).
- **Step 2 — delegate:** invoke `/aid-summarize` with **no staleness flags** (not `--reset`),
  forwarding **only** the optional `--grade X` the user passed to `/aid-housekeep` (feature-001 §
  Invocation/CLI pass-through; feature-003 SPEC § The delegation decision). `/aid-summarize` runs
  its own PREFLIGHT → STALE-CHECK → … → DONE / pauses for V1 verbatim — this body adds no
  staleness or grading logic and edits nothing in `canonical/skills/aid-summarize/`.
- **Step 3 — classify the outcome by re-reading the filesystem** (`knowledge-summary.html`,
  `## Knowledge Summary Status`, `## Summarization History` in `.aid/knowledge/STATE.md` — the
  "filesystem is the only source of truth" rule), and write `**Summary Stage:**` **only** through
  `housekeep-state.sh` (never hand-edit `## Housekeep Status`), per the feature-003 SPEC mapping
  table:
  - **Regenerated & approved** (new dated `## Summarization History` entry + `**User Approved:**
    yes`) → `**Summary Stage:** passed`; **commit** the regenerated HTML *and* the `STATE.md`
    history edit `/aid-summarize` made in a **single** `branch-commit.sh` call (message
    `chore(housekeep): summary delta refresh [feature-003]`); **CHAIN → CLEANUP**. `passed` also
    covers the `CURRENT_UNAPPROVED → APPROVAL` sub-path (HTML current but unsigned → approve-only;
    commit just the `STATE.md` approval edit).
  - **Already current** (`CURRENT_APPROVED` → DONE-IDEMPOTENT; no new history entry, STATE.md
    unchanged) → `**Summary Stage:** skipped`; **no commit** (NFR2); **CHAIN → CLEANUP**.
  - **Below-min grade / V1 visual fail / diagram-parse F / user declined** (no fresh
    `**User Approved:** yes` after `/aid-summarize` returns) → `**Summary Stage:** stalled`; also
    write `**Stage Status:** stalled` + `**Stall Reason:**` (e.g. `summary V1 visual gate failed`
    / `summary grade B < A`); **PAUSE-FOR-USER-ACTION** (feature-001 resume banner; re-run resumes
    at SUMMARY-DELTA, State Detection row 4).
- Commit boundary (C3): exactly one commit per stage on the `aid/housekeep-*` branch, **never
  push**, via feature-001's `branch-commit.sh`; the `skipped`/DONE-IDEMPOTENT path commits nothing.
  This feature introduces no new commit mechanism (feature-003 SPEC § Commit boundary).
- **No new design** — every decision (delegation, the mapping table, the C1 guard, the V1
  handling, the single per-stage commit) is dictated verbatim by feature-003 SPEC; this task only
  slices it into the body that fills the feature-001 stub slot.

**Acceptance Criteria:**
- [ ] `state-summary-delta.md` no longer reads as a stub no-op: it invokes `/aid-summarize` (no
  staleness flags; forwards only `--grade X` if the user gave one) and classifies the outcome via
  filesystem reads, with no reimplemented staleness or grading logic and no edit under
  `canonical/skills/aid-summarize/`.
- [ ] Step 0 refuses to run unless `**KB Stage:**` reads `passed`/`skipped` (C1), reading it via
  `housekeep-state.sh`; the state-entry banner warns up front that a regeneration triggers the V1
  visual check (NFR3).
- [ ] The three-way result→`**Summary Stage:**` mapping matches the feature-003 SPEC table
  exactly: regenerated&approved (incl. `CURRENT_UNAPPROVED` approve-only) → `passed` + one
  `branch-commit.sh` commit + CHAIN→CLEANUP; `CURRENT_APPROVED`/DONE-IDEMPOTENT → `skipped` + no
  commit + CHAIN→CLEANUP (NFR2/AC6); below-min/V1-fail/declined → `stalled` + `**Stage Status:**
  stalled` + `**Stall Reason:**` + PAUSE-FOR-USER-ACTION (AC9).
- [ ] `**Summary Stage:**` is written **only** through `housekeep-state.sh`; the body never
  hand-edits `## Housekeep Status`.
- [ ] A `passed` run produces exactly one commit on the `aid/housekeep-*` branch (regenerated HTML
  + the `STATE.md` history edit, one `branch-commit.sh` call, never push — C3); `skipped` produces
  none.
- [ ] The full sequence now terminates `KB-DELTA → SUMMARY-DELTA → CLEANUP → DONE` with
  SUMMARY-DELTA exercising real logic; the stub→real swap is verified by dogfooding +
  render-drift CI, with no bespoke integration test (AID has no E2E tier; no new dedicated suite
  per feature-003 SPEC § Testing).
- [ ] All §6 quality gates pass; build/render passes (CI render-drift re-emits the body to all 5
  profiles, no renderer edit); all existing tests pass (`/aid-summarize`'s own suites for
  staleness/grade + feature-001's `test-housekeep-state.sh` for the gate-field write/resume).
