# task-014: Panel orchestration -- 5 mandate bodies + state-review fan-out/aggregate + injectable scope seam

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-001

**Depends on:** task-008, task-012

**Scope:**
- Split today's monolithic `canonical/skills/aid-discover/references/reviewer-prompt.md` into 5
  focused per-mandate FOCUS bodies (`reviewer-prompt-correctness.md`, `-anatomy`,
  `-concept-closure`, `-teachback`, `-calibration`): M1 = today's Accuracy checklist; M2 =
  Completeness/Anatomy vs `document-expectations.md`; M3 = closure self-containment + `sources:`-anchored
  coverage (consumes `closure-check.sh` outputs (a) + (b)); M4 = teach-back (fixed question set + binary
  bar, two limbs: per-term + non-lexical engine-narration); M5 = Calibration round-trip (consumes
  output (c) + (b)). Each FOCUS body MUST instruct its reviewer to write to its OWN scratch ledger
  `.aid/.temp/review-pending/<scope>-<mandate>.md` (7-column schema), NOT to STATE.md (drop the
  STATE.md write wording). `reviewer-prompt.md` becomes a thin index pointing to the five.
- Rewrite `canonical/skills/aid-discover/references/state-review.md`:
  - Step 1: single dispatch -> 5 PARALLEL mandate dispatches (full-panel default; A3 capability-probe
    degrade-to-sequential; per-mandate transient scratch ledgers).
  - Step 2: merge the 5 scratch ledgers' data rows into the single `<scope>.md` ledger, assigning
    STABLE per-mandate IDs in the `#` column (`M1-001`..`M5-NNN`, `TB-NNN`) + a `[Mi]`/`[TEACHBACK]`
    description prefix; run the EXISTING `grade.sh` unchanged; derive the teach-back verdict purely
    from open `[TEACHBACK]` rows (NO separate verdict sentinel); delete the 5 transient scratch ledgers.
  - Step 3: exit print + STATE report the `Grade: <g> | Teach-back: <PASS|FAIL>` pair.
  - Parameterize the ledger `{{SCOPE}}` (default `discovery`) + the graded doc-set as injectable
    inputs (`{{ARTIFACTS}}`/`{{CONTEXT}}`) -- the f005-owned injectable-scope + doc-set seam f008's
    `aid-update-kb` consumes; `aid-discover`'s call site injects `discovery` + `discovery.doc_set`
    byte-identical to today. Clean-context/contamination blocks preserved (stronger for teach-back).
- M3/M5 consume `closure-check.sh` outputs (a)/(b)/(c); M4 covers both teach-back limbs (per-term +
  engine-narration). No new grading infra; no `grade.sh` change.
- Edit canonical only; re-run `run_generator.py`; commit regenerated `profiles/`.

**Acceptance Criteria:**
- [ ] `reviewer-prompt.md` is a thin index; the 5 per-mandate FOCUS bodies exist, each writing to its
  own `<scope>-<mandate>.md` scratch ledger (7-column schema), with the STATE.md write wording dropped
  from every per-mandate body.
- [ ] M3 consumes `closure-check.sh` outputs (a)+(b); M5 consumes (c)+(b); M4 quizzes the fixed
  question set (per-term limb) AND grades the engine-narration (non-lexical limb) as an independent
  FAIL source.
- [ ] `state-review.md` Step 1 dispatches all 5 mandates in parallel (full-panel default) with A3
  degrade-to-sequential and per-mandate transient scratch ledgers.
- [ ] Step 2 merges the 5 scratch ledgers into the single `<scope>.md` with stable per-mandate IDs +
  `[Mi]`/`[TEACHBACK]` prefixes, runs the unchanged `grade.sh`, derives teach-back PASS/FAIL purely
  from open `[TEACHBACK]` rows (no sentinel), and deletes the 5 transients.
- [ ] Step 3 reports the `Grade | Teach-back` pair; an open `[HIGH] [TEACHBACK]` row forces
  grade <= D (keystone gate via the existing grader, no second boolean).
- [ ] The ledger `{{SCOPE}}` (default `discovery`) + graded doc-set are injectable;
  `aid-discover`'s call site injects `discovery` + `discovery.doc_set` byte-identical to today's
  behavior; the seam is exposed for f008 reuse.
- [ ] No `grade.sh` change; clean-context/contamination blocks preserved (stronger for teach-back).
- [ ] `run_generator.py` re-run; regenerated `profiles/` committed (render-drift green).
- [ ] All section-6 quality gates pass.
