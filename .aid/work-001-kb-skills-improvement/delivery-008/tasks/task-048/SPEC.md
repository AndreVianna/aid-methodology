# task-048: aid-update-kb state references (ANALYZE/APPLY/REVIEW/APPROVAL/DONE)

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-008

**Depends on:** task-047, task-014 (delivery-001), task-040 (delivery-007)

**Scope:**
- f008 Part 2 (FR-27, AC8, NFR-6/C4, FR-34) -- author the five
  `canonical/skills/aid-update-kb/references/state-{analyze,apply,review,approval,done}.md`
  reference docs (one per state), the human-gated UPDATE half of the freshness loop.
- **Cross-delivery reuse (cite explicitly):**
  - REVIEW reuses delivery-001 f005's review/calibration panel via the **injectable
    `{{ARTIFACTS}}` / ledger-`<scope>` + doc-set seam** built in **task-014 (delivery-001)** --
    SPIKE-2's confirmed one-line seam. REVIEW does NOT redefine the panel; it sets
    `{{ARTIFACTS}}` = the changed-doc set and `<scope>` = `update-kb`.
  - ANALYZE consumes **task-040 (delivery-007)**'s `kb-freshness-check.sh` suspect verdicts (f007)
    to fold the prompt's named sources against per-doc drift.
- **ANALYZE (`state-analyze.md`)** -- prompt -> (doc, change) set: (1) load `.aid/knowledge/INDEX.md`
  (f002 routing table) to map the prompt onto candidate docs by Objective/Tags/Audience; (2) run
  `kb-freshness-check.sh --root .aid/knowledge --format tsv` (task-040/f007) and intersect
  prompt-implied docs with suspect docs (a prompt-named doc with no drift is still in scope if the
  prompt asserts an unseen content change); (3) read each candidate + its `sources:`, decide the
  concrete change (new summary+pointer entry / corrected fact / new `sources:` entry / new concept
  on the spine), emit the change plan into the run-state file; (4) **closure escalation (FR-32/FR-34
  hook):** an un-groundable project-specific concept is NOT invented -- append a Q&A to
  `.aid/knowledge/STATE.md ## Q&A (Pending)` (Category `Update-KB / Ungroundable Concept`, Impact
  `Required`, Status `Pending`) and PAUSE. Advance: CHAIN -> APPLY (or PAUSE on escalation).
- **APPLY (`state-apply.md`)** -- per (doc, change): a targeted **summary+pointer** edit at KB
  altitude (NOT a transcription -- authored to pass f005's CAL-1/CAL-2), preserving the doc's native
  language/concept spine (reuse `domain-glossary.md` coined terms; FR-34 closure invariant); update
  `sources:` (f001 schema) if a new underlying source is added; **do NOT restamp
  `approved_at_commit:` in APPLY** (that is DONE, post-gate); edits in place on
  `.aid/knowledge/` docs on an `aid/update-kb-*` branch; the skill NEVER pushes. Advance: CHAIN -> REVIEW.
- **REVIEW (`state-review.md`)** -- REUSE f005's panel (task-014) scoped to the changed docs:
  render the universal reviewer brief, dispatch the five mandate `aid-reviewer` sub-agents in
  parallel against the changed docs (each to its per-mandate scratch ledger), **merge** into the
  single canonical ledger `.aid/.temp/review-pending/update-kb.md` then **delete the scratch
  ledgers** (f005 merge-then-delete; distinct `<scope>` from `discovery.md`), run the unchanged
  `grade.sh`, evaluate the teach-back hard gate. Exit rule (identical to f005):
  `READY iff grade(update-kb.md) >= minimum_grade AND teachback == PASS`; `minimum_grade` resolves
  via `read-setting.sh --skill update-kb --key minimum_grade --default A` (new skill key, default
  A). **Teach-back default = full whole-KB clean-context exit** (SPIKE-1 default -- FR-34 closure
  re-verification; the scoped optimization is f010-tunable). FIX loop routes below-gate findings to
  `aid-discover`'s existing `state-fix.md` over `update-kb.md`, re-REVIEW until the gate passes
  (no new loop invented). Advance: CHAIN -> FIX if below gate; CHAIN -> APPROVAL if gate passes.
- **APPROVAL (`state-approval.md`)** -- the human gate (NFR-6/C4/AC13): present the diff summary
  (docs changed, grade, teach-back verdict), reuse `aid-discover/references/state-approval.md`'s
  `[1] Approved` / `[2] Additional consideration` pattern. On `[1]` -> DONE; on `[2]` record the
  consideration as a Q&A and loop back. **No auto-apply path** -- DONE is unreachable without an
  explicit human `[1]`. Advance: PAUSE-FOR-USER-ACTION -> DONE on approval.
- **DONE (`state-done.md`)** -- restamp each approved doc's `approved_at_commit:` to the commit
  recording the approved edit (f001: generator-written on approval, never hand-authored), commit on
  the `aid/update-kb-*` branch, print the closing summary, remove the transient run-state file.
  **Closure re-verification (FR-34, shared with f010):** before committing, re-run f004's
  `closure-check.sh` over the changed KB to confirm no native term left undefined (a standing
  invariant; the who-runs-closure-when boundary vs `aid-housekeep` is f010, NOT here). Advance: HALT.
- **Degrade-gracefully note:** if f005/f007 land later in the branch ordering, REVIEW falls back to
  the single-blended reviewer until task-014 lands and ANALYZE skips the freshness fold until
  task-040 lands; within this delivery both deps already exist (delivery-001 / delivery-007), so
  the full path is expected.
- ASCII-only (C2).

**Acceptance Criteria:**
- [ ] All five `references/state-{analyze,apply,review,approval,done}.md` exist, one per state.
- [ ] ANALYZE loads INDEX.md, runs `kb-freshness-check.sh` (task-040/f007), intersects
  prompt-implied with suspect docs, emits a (doc, change) plan, and escalates an un-groundable
  concept to `.aid/knowledge/STATE.md ## Q&A (Pending)` (Category `Update-KB / Ungroundable
  Concept`) + PAUSE rather than inventing it.
- [ ] APPLY makes targeted summary+pointer edits preserving the native concept spine, updates
  `sources:` when needed, and does NOT restamp `approved_at_commit:` (verified: only DONE restamps).
- [ ] REVIEW invokes f005's five-mandate panel (task-014 seam) with `{{ARTIFACTS}}` = changed docs
  and ledger `<scope>` = `update-kb`, merges the five scratch ledgers into
  `.aid/.temp/review-pending/update-kb.md` then deletes the scratch ledgers, runs the unchanged
  `grade.sh`, and applies the exit rule `READY iff grade >= minimum_grade AND teachback == PASS`
  with `minimum_grade` from `read-setting.sh --skill update-kb --key minimum_grade --default A`.
- [ ] REVIEW's teach-back is the full whole-KB clean-context exit (SPIKE-1 default); the FIX loop
  reuses `aid-discover`'s `state-fix.md` over `update-kb.md` (no new loop).
- [ ] APPROVAL is human-gated (`[1]`/`[2]`); DONE is unreachable without an explicit `[1]` (no
  auto-apply path exists).
- [ ] DONE restamps `approved_at_commit:` post-gate, commits on `aid/update-kb-*` (never pushes),
  removes the transient run-state, and re-runs `closure-check.sh` (f004) over the changed KB
  before committing (FR-34 re-verification).
- [ ] The cross-delivery reuse is cited in the docs: REVIEW -> task-014 (delivery-001) f005 seam;
  ANALYZE -> task-040 (delivery-007) f007 freshness check.
- [ ] Reference docs are ASCII-only.
- [ ] All section-6 quality gates pass.
