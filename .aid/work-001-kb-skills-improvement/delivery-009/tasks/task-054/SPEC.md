# task-054: housekeep KB-DELTA suspect-scoping rewrite + closure re-verify before commit

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-009

**Depends on:** task-053, task-040 (delivery-007), task-008 (delivery-001)

**Scope:**
- f010 Part 2 (FR-33) + Part 3 (FR-34) -- rewrite `aid-housekeep`'s KB-DELTA Steps 1-2 scoping and
  wire a standing closure re-verify BEFORE the KB-DELTA commit, in
  `canonical/skills/aid-housekeep/references/state-kb-delta.md`. The boundary contract record is
  task-053; the behavioral grep guards are task-055.
- **Cross-delivery reuse (cite explicitly):**
  - Steps 1-2 consume **task-040 (delivery-007, f007)**'s `kb-freshness-check.sh` per-doc suspect
    verdicts as the source-keyed drift signal (replacing the git-date hint as the cheap drift
    signal). f010 adds NO flag to the script -- it calls `--root .aid/knowledge --format tsv`.
  - The closure re-verify consumes **task-008 (delivery-001, f004)**'s `closure-check.sh` oracle
    (the ungrounded-term set). f010 adds NO flag/behavior to the script -- it calls it as f004
    defines it. **[SPIKE-C2]:** f004 pins the script inputs (candidate-concepts.md + spine + KB
    docs) but not the literal flag names; wire the exact invocation as task-008/f004 ships it --
    do NOT guess flags. The dependency holds for any input shape.
  - Realizes the boundary recorded in **task-053** (this delivery).
- **Step 1 rewrite (deterministic suspect pre-pass):** run
  `bash .claude/aid/scripts/kb/kb-freshness-check.sh --root .aid/knowledge --format tsv` and
  capture the per-doc `{current,suspect,unknown}` verdicts + `suspect_sources_csv`. The `suspect`
  rows are the commit-graph-exact drifted-doc set (source-driven-global signal). The optional
  `git fetch origin master` convenience is retained; offline = scope against the local graph, no
  pause (no hard offline gate). The git-date range STOPS being the scoping boundary.
- **Step 2 rewrite (two-tier; CRITICAL -- whole-KB review RETAINED):** Tier 1 = the `suspect` docs
  are the priority re-review set (read doc + its `suspect_sources_csv`, plan the correction).
  Tier 2 = **the autonomous whole-KB content re-review of ALL docs including `current` ones is
  RETAINED** -- no doc is skipped (preserves AC1 "subtly-wrong-all-along"; a `current` verdict
  proves only source-ancestry, not summary-correctness). The verdict sets PRIORITY only: suspect
  first, unknown next (no baseline -- f011 unstamped), current still content-reviewed at lower
  priority. The optimization is prioritization + a fast no-drift exit, NEVER skipping a doc's
  content review.
- **Step 3 banner edit:** the proposed scope at Step 3 names each drifted doc annotated by the
  signal that flagged it (suspect: `<suspect_sources_csv>` drifted / content drift on a
  current-verdict doc -- AC1 catch). Steps 3-6 (confirm-and-adjust gate, `Impact: Required` Q&A +
  `/aid-discover` targeted re-entry, read-back/commit) are otherwise retained verbatim.
- **No-drift exit (AC4) refined:** fires only when zero `suspect` docs AND the retained whole-KB
  content review found nothing -- both the deterministic signal and the content review must be
  clean before the run exits.
- **Closure re-verify step (Part 3, new in f010):** insert into KB-DELTA's PASSED path BETWEEN the
  staged KB edits and Step 6's `branch-commit.sh --commit` -- re-run `closure-check.sh` over the
  refreshed-but-not-yet-committed KB (true f008 parity: verify before committing, never commit a
  hole). Closure intact (empty output) -> write `**Closure:** verified` to the run-state, then let
  Step 6 commit and CHAIN to SUMMARY-DELTA. Closure broken (non-empty) -> break-handling below,
  refresh UNCOMMITTED. On the no-drift/skipped path the closure step is NOT run (nothing changed).
- **Term-universe freshness contract (closure re-verify input):** `closure-check.sh`'s
  term-universe input -- `candidate-concepts.md` -- is a TRANSIENT f004 artifact harvested during
  `/aid-discover`; at housekeep-closure time it may be STALE or ABSENT, which would make the
  closure verdict wrong (computed against the old KB's term universe, not the staged refresh). The
  closure re-verify MUST therefore run against a **freshly-(re)generated `candidate-concepts.md`**:
  it consumes the `candidate-concepts.md` produced by KB-DELTA's `/aid-discover` targeted re-entry
  (Steps 3-6 / the break-handling re-entry), which re-runs f004's harvest over the staged-but-not-
  committed KB so the term universe matches the current KB. If a run reaches the closure step
  WITHOUT a fresh `candidate-concepts.md` (none was regenerated on this run, or it predates the
  staged edits), the f004 harvest is (re)run FIRST -- before `closure-check.sh` -- to refresh the
  term universe. The closure verdict is NEVER computed against a stale/absent term-universe. (No
  new script: this is a wiring/ordering requirement reusing f004's harvest + closure-check.)
- **Break-handling (reuses existing mechanisms, NO new mechanism):** on an ungrounded term, do NOT
  auto-fix/commit/silently-proceed. Append one Q&A to `.aid/knowledge/STATE.md ## Q&A (Pending)`
  (Style A: Category `Closure / Standing Invariant Break`, Impact `Required`, Status `Pending`,
  naming the ungrounded term(s) @ doc:anchor). Route the `Impact: Required` Q&A to `/aid-discover`
  targeted re-entry naming `domain-glossary.md` (the spine) + the using-doc (resolved routing, not
  a spike). Then take the existing `stalled` exit (state-kb-delta "Exit -- stalled") with
  `**Stall Reason:** closure invariant broken -- undefined native term in the staged KB refresh
  (not committed)` and PAUSE-FOR-USER-ACTION with the refresh uncommitted. Re-running
  `/aid-housekeep` resumes at KB-DELTA; once grounded and `closure-check.sh` is empty, the stage
  advances and then commits.
- **Thin-router (C8) preserved:** SKILL.md state machine, run-state file, branch/commit machinery,
  Dispatch table, and chaining are untouched -- the only edits are inside `state-kb-delta.md`.
- **Render note:** edits `canonical/` only; render-drift RED on this branch is by construction
  (f009 renders, out of scope).
- ASCII-only (C2): no non-ASCII glyphs introduced into `state-kb-delta.md`.

**Acceptance Criteria:**
- [ ] Step 1 of `state-kb-delta.md` runs `kb-freshness-check.sh --root .aid/knowledge --format tsv`
  (task-040/f007) and captures per-doc verdicts + `suspect_sources_csv`; the git-date range is no
  longer the scoping boundary (retained only as an optional convenience hint).
- [ ] Step 2 RETAINS the autonomous whole-KB content re-review of ALL docs including `current`
  ones (no doc is skipped); the suspect verdict sets review PRIORITY only (suspect first, unknown
  next, current still reviewed). The two-tier structure is explicit and AC1 coverage is preserved.
- [ ] The no-drift exit fires only when zero suspect docs AND the whole-KB content review found
  nothing (both signals clean).
- [ ] Step 3's proposed-scope banner names each drifted doc annotated by the flagging signal
  (suspect-sources vs current-verdict content drift).
- [ ] A CLOSURE re-verify step calling `closure-check.sh` (task-008/f004) is wired into the PASSED
  path BEFORE Step 6's commit; closure-intact proceeds to commit, closure-broken stalls with the
  refresh uncommitted (never commits a hole). The step is NOT run on the no-drift/skipped path.
- [ ] The closure re-verify runs against a freshly-(re)generated `candidate-concepts.md`: it
  consumes the harvest output of KB-DELTA's `/aid-discover` targeted re-entry over the staged KB,
  and if the closure step is reached without a fresh `candidate-concepts.md` the f004 harvest is
  (re)run FIRST so the term universe matches the staged refresh -- the closure verdict is never
  computed against a stale/absent term-universe (no new script; reuses f004 harvest + closure-check).
- [ ] On a closure break the skill appends a Style-A Q&A to `.aid/knowledge/STATE.md ## Q&A
  (Pending)` (Category `Closure / Standing Invariant Break`, Impact `Required`) routed to
  `/aid-discover` targeted re-entry naming `domain-glossary.md` + the using-doc, then takes the
  existing stalled exit and PAUSEs -- reusing existing mechanisms (no new escalation invented).
- [ ] No new script is added and no new flag is added to `kb-freshness-check.sh` or
  `closure-check.sh` (pure reuse, NFR-3/C2 by reuse); the thin-router SKILL.md/run-state/Dispatch
  shape is unchanged.
- [ ] The cross-delivery reuse is cited in the doc: Steps 1-2 -> task-040 (f007); closure re-verify
  -> task-008 (f004); boundary realized -> task-053.
- [ ] `state-kb-delta.md` is ASCII-only.
- [ ] All section-6 quality gates pass.
