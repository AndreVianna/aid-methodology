# task-015: Engine-driven guided triage in state-triage.md

**Type:** IMPLEMENT

**Source:** work-001-aid-interview-improvements -> delivery-003

**Depends on:** task-013, task-014

**Scope:**
- Make `canonical/skills/aid-interview/references/state-triage.md` an engine CONSUMER (feature-004):
  replace Step 1's free-form self-description with an engine-driven draw-out while PRESERVING the
  Steps 2-4 routing computation. The state position is unchanged
  (`FIRST-RUN -> TRIAGE -> {full: CONTINUE | lite: CONDENSED-INTAKE / recipe}`); the State Detection
  table, dispatch rows, and `Path:` sentinel semantics are untouched. No script and no schema change.
- **Step 1 (engine turn 1):** emit the D1 opener ONCE (already re-pointed by task-014), read, capture
  the opener intent verbatim (first vocabulary + seed calibration read).
- **New Step 1b (TRIAGE-mode engine loop)** over the triage gap inventory -- the 5 route-deciding
  signals: (1) scope size/shape via backbone-first + walking-skeleton [primary, full-vs-lite];
  (2) work-type bug-fix/new-feature/refactor [lite Sub-path]; (3) target artifact identity via
  concrete-example probe [recipe match]; (4) behavior/flow span via event-first [scope secondary];
  (5) KB anchoring [sharper sizing / skip-what-KB-answers]. Stop predicate =
  route-with-confidence (full-vs-lite decided AND recipe confidence in {single clear winner, several
  plausible, none}); the common case is the opener alone suffices and the stop check fires immediately
  (preserves the one-turn-common-case). Record sink = `STATE.md ## Triage`.
- **KB-context detection at state entry** (AC-7 / FR-5): classify Full brownfield KB
  (`source: generated` / as-built docs; recon `BROWNFIELD-*`) vs Seed KB (only forward-authored docs,
  `source: forward-authored` / absence of `source: generated`, marker-based not a fixed count; recon
  `GREENFIELD`) vs No KB (INDEX.md absent), and gap-target accordingly -- skip any inventory signal the
  KB already answers and convert it to a confirm-not-elicit straw-man; NFR-7 holds either way.
- **Step 3 (route-confirmation turn)** reframed as an engine NFR-7 straw-man reflect-back (the existing
  single confirmation turn, now an engine emission). **Steps 2 / 2a / 2b / 4** routing computation
  RETAINED UNCHANGED (workType heuristic, recipe summary-match + confidence, the conservative routing
  table, escalate-lite->full), now fed by the DRAWN-OUT signals not a raw line.
- **Step 6** gains the new grep-recoverable `**Opener:**` capture field alongside the existing
  `Path` / `Work Type` / `Sub-path` / `Recipe` / `Decision rationale` schema (this is the field
  task-016's de-dup reads). Steps 5a/5b/6/7 mechanisms otherwise unchanged.
- `parse-recipe.sh`, `recon-classify.sh`, the recipe set, and the escalation reference docs are
  REUSED UNCHANGED (no edit). ASCII-only.
- **Out of scope:** the state-continue.md conditional opener skip (task-016); the engine docs
  themselves (tasks 010-013); generator render (task-017).

**Acceptance Criteria:**
- [ ] `state-triage.md` Step 1b is a new TRIAGE-mode engine loop over the 5-signal gap inventory with the route-with-confidence stop predicate and `## Triage` record sink; the D1 opener fires exactly ONCE in Step 1. *(AC-7, gate criterion 4)*
- [ ] KB-context detection classifies Full-KB vs Seed-KB vs No-KB and gap-targets (skip-what-KB-answers -> confirm-not-elicit straw-man) so triage works and routes in BOTH full-KB and seed-KB contexts; NFR-7 holds in every case. *(AC-7 / FR-5, gate criterion 4)*
- [ ] Steps 2 / 2a / 2b / 4 routing computation is RETAINED byte-unchanged (workType heuristic, recipe summary-match + confidence, conservative routing table, escalate-lite->full); Step 3 is the engine NFR-7 confirmation turn. *(AC-10 / NFR-2, feature-004 D3)*
- [ ] Step 6 writes the new `**Opener:**` field (grep-recoverable) alongside the existing `## Triage` schema. *(opener-seam de-dup enabler for task-016)*
- [ ] `parse-recipe.sh`, `recon-classify.sh`, the recipe set, and the escalation docs are NOT edited (verify via diff); ASCII-only; skill is prose-executed (no unit test; IMPLEMENT default overridden). Brownfield regression verified at task-018; render deferred to task-017.
- [ ] All REQUIREMENTS.md §6 quality gates pass.
