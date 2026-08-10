# task-069: The count guard extended, its two ratchets raised, and the replay driven to zero

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-069/STATE.md.
Shape: 6 sections matching .claude/aid/templates/delivery-plans/task-template.md.

> **Execution protocol (binding on whoever executes this task -- no
> exceptions):** the moment this task's `State` changes, write it --
> `In Progress` before starting work, `In Review` before dispatching the
> reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally
> whether the main/orchestrator agent executes this task directly or
> dispatches it to a sub-agent; neither may skip, batch, or defer these
> writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- it is never
> self-written by the task being executed.) Full mandate:
> `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** IMPLEMENT

**Source:** work-006-design-phase-skills -> delivery-003

**Depends on:** task-068

**Scope:**
- Source: `features/feature-006-integration-and-close-out/SPEC.md` §3, its constants (a), (b) and (c),
  and its §10 rows *Counts true repo-wide (guarded phrasings)*, *Counts true repo-wide (**un**guarded
  phrasings)* and *`shortcuts` untouched*. It closes BLUEPRINT criterion **4** -- both its
  surfaces-state-their-own-value half, whose per-file work task-051, task-059 and task-065 through
  task-068 did, and its two oracles.
- **It runs last of the count work, because the durable half cannot be sized earlier.** `CLAIM_FLOOR`
  must be set near the **post-change** live figure, and the set of lines a new `CLAIMS` entry newly
  exposes is not knowable until every document is final. So the earlier tasks fixed what the existing
  guard reports; this one closes the blind spot and re-ratchets.
- **Extend `CLAIMS` to cover modes M2, M3 and M4** (`check-skill-counts.mjs:63-118`, 26 entries today,
  each binding one phrasing to one **quantity**). Three constraints on the new regexes, every one of
  them learned from an entry already in the array: bound the noun to a **named set** rather than opening
  it to `\w+` (`:75-77`); keep the `repurpose` / `shortcut` negative lookarounds intact (`:87-90`) so a
  correct number is never reported as wrong; and remember that a false positive costs the guard the
  credibility its real findings depend on (`:93-95`) -- a phrasing that cannot be bounded safely is
  better rewritten in the document than forced into a regex.
- **M1 and M5 are already closed by document rewrites, not by this task.** M1 was the Total row's
  missing noun (task-068) and M5 the deliberate `*` lookbehind at `:84-86` (task-065's
  `module-map.md:76`, task-068's `diagram-content-reference.md:109` and `:111`). Widening the `*`
  exclusion would re-import the false positives it was written to remove; that is not done here.
- **M6 is closed by neither route and is not this task's.** `.aid/knowledge/kb.html` states the corpus
  total in three places and `EXT` (`:170`) admits no `.html`, so no `CLAIMS` entry can reach it. It is
  **regenerated** in task-071 instead, which is a third route and the only one that applies to a
  generated file. This task must not add an `.html` extension to `EXT` to reach it.
- **`SUPERSEDED` (constant (a), `:133`) is not a blank cheque.** A `count-history`-marked line may only
  claim a value the quantity actually held, so the superseded values must be **added**, per quantity:
  `76` joins `corpus total`; `58` joins `catalog rows` and `catalog canonical names`; `24` joins
  `repurpose rows`. `'emitting shortcuts'` is **not** touched -- 34 is still current. Note a collision
  that is safe but looks alarming: `94` is already listed under `corpus total` as a historical corpus
  size and becomes the **current** `catalog rows` value; `SUPERSEDED` is keyed per-quantity, so the two
  never meet.
- **`MARKER_CAP` (constant (b), `:319`) is a ratchet held at exactly the number of exemptions in use,
  with no headroom, and tripping it is designed behaviour rather than a malfunction.** The guard
  currently reports exactly 12 marker-exempted lines against a cap of 12, so adding even one
  `count-history` marker trips it. Whether this work adds a marker at all is a per-line decision made
  while doing `SUPERSEDED`; the raise is **conditional on that**, and the condition is the point. If a
  marker is added, raise the cap to the new live figure in the same commit with the reason stated
  there; if none is added, leave the cap at 12 and record that decision.
- **`CLAIM_FLOOR` (constant (c), `:374`) is raised unconditionally.** It guards against a regex
  refactor silently neutering the scan and its own note says to set it near the live figure. The run
  currently checks 175 against a floor of 120, and widening `CLAIMS` raises the checked count further,
  so a floor left at 120 would be slack rather than a ratchet. Raise it to the post-change live figure
  in the same commit as the new entries, with the reason stated there. This is a real edit, not a
  considered-and-skipped note.
- **The stage-2 replay is the acceptance oracle, and the hand inventory in §3 is not.** Load the guard's
  own `CLAIMS` array and its own file walk, and for every occurrence of `58`, `76` or `24` on a
  non-history, unmarked line, ask whether any `CLAIMS` regex claims **that occurrence** -- testing the
  line alone and both straddle joins, exactly as the guard does. It reported **36** unclaimed
  occurrences over the pre-work corpus; it must reach **zero** here. A guard run that exits 0 while the
  replay still reports unclaimed occurrences is a passing gate over a false document, which is the exact
  failure §3 exists to prevent.
- **Three count-bearing surfaces inside the guard's scan belong to no other task, and they are named
  here so they are not left orphaned.** `canonical/skills/aid-triage/references/state-classify.md:85`
  (mode M2 -- feature-006 §3's surface table lists it, and task-052 explicitly defers it here);
  `README.md`, the one individually-named file in the guard's scan, which §3 records as **clean today**
  and which therefore needs an edit only if the guard reports one; and
  `.claude/skills/release-aid/SKILL.md`, a repo-local maintainer skill inside the guard's scan that
  delivery-001 already edited. Editing the last of these cannot break the byte-identity gate:
  `test-dogfood-byte-identity.sh:150` puts `skills/release-aid/*` in the documented allowlist, and the
  skill has no `canonical/` source, so it needs no re-render.
- **Any further residual line the new entries newly expose is fixed here**, since this task is the only
  one that can see it -- and each such fix is recorded with the document and the mode that hid it.
- **feature-001 AC-3 is not violated by this write**, for the reason task-062 states once: AC-3's
  tree-scoped clean-diff over `tests/canonical/` is evaluated at feature-001's own close, and its
  substance is the seed-count suite set it enumerates -- none of which is touched here. This delivery's
  BLUEPRINT criterion 4 requires this write. `site/scripts/__tests__/` stays writer-free.
- Out of scope: `tests/canonical/test-deploy-monitor-repurpose.sh` and
  `tests/canonical/test-catalog-dirs-parity.sh` (task-062); `tests/coverage-baseline.{tsv,meta}`
  (task-063); adding an `.html` extension to `EXT`; widening the `*` lookbehind at `:84-86`; and
  `INDEX.md` and `kb.html` (task-070, task-071).

**Acceptance Criteria:**
- [ ] **BLUEPRINT criterion 4, oracle 1 -- the guard exits 0 at its raised floor.**
      `node tests/canonical/check-skill-counts.mjs` exits **0**, and its own summary line reports
      `claims checked` **>= `CLAIM_FLOOR`** at the raised value. Both numbers are recorded from the run
      output, not from this DETAIL
- [ ] **BLUEPRINT criterion 4, oracle 2 -- the stage-2 replay reaches zero.** The replay reports
      **0** unclaimed occurrences of `76`, `58` or `24` over the guard's own scanned trees, and its
      output is recorded. The replay, not a hand list, is the oracle
- [ ] **The new `CLAIMS` entries cover M2, M3 and M4 and respect all three constraints.** Each new
      entry is recorded with the mode it closes, the quantity it binds, and the named noun set it is
      bounded to; none opens its noun to `\w+`; and every existing `repurpose`/`shortcut` negative
      lookaround is intact (`git diff HEAD -- tests/canonical/check-skill-counts.mjs` shows no deletion
      inside `:87-90`)
- [ ] **No false positive was introduced.** The guard's report over the finished corpus names no line
      that states a correct figure -- checked by reading the full `--list` output, not just the exit
      code, and recorded as a verdict
- [ ] **`SUPERSEDED` gained exactly the four values and no more**: `76` under `corpus total`, `58` under
      `catalog rows` **and** under `catalog canonical names`, `24` under `repurpose rows`; and
      `'emitting shortcuts'` is byte-unchanged in the diff
- [ ] **`MARKER_CAP` moved only if a marker was added, and either way the decision is recorded.** If a
      `count-history` marker was added, the cap equals the guard's newly reported marker-exempted line
      count and the reason is stated at the constant; if none was added, the cap is still `12` and the
      record says so. A raise with no new marker is as much a defect as a new marker with no raise
- [ ] **`CLAIM_FLOOR` was raised to the post-change live figure**, with the reason stated at the
      constant, and the recorded value equals the `claims checked` figure the guard now reports
- [ ] **BLUEPRINT criterion 4's negative half, with its three independent witnesses named.** The guard
      reports **34** for `emitting shortcuts`; the re-bootstrapped `tests/coverage-baseline.tsv` still
      holds **34** `CDP{i}e`, **34** `f` and **34** `g` rows (task-063's, cited here as the second
      witness, derived from the coverage inventory rather than from `deriveSkillCounts`); and the third
      witness -- the regenerated `kb.html` reading `34 verb-first` -- is named as **task-071's**, not
      claimed here
- [ ] **The three orphan surfaces are each resolved and recorded.**
      `canonical/skills/aid-triage/references/state-classify.md:85` states its quantity's new value;
      `README.md` is reported either as still clean (its state today) or as fixed, with the guard's own
      output as the evidence either way; and `.claude/skills/release-aid/SKILL.md` likewise. After any
      edit to the last of these, `bash tests/canonical/test-dogfood-byte-identity.sh` is still green
      with both key sets reported -- the allowlist makes that edit safe, and this is where that is
      demonstrated rather than assumed
- [ ] **Every further residual line the new entries newly exposed was fixed and recorded** with its
      document and the mode that hid it, or the record states that none was exposed
- [ ] **`EXT` and the `*` lookbehind are untouched.** `git diff HEAD -- tests/canonical/check-skill-counts.mjs`
      shows no change at `:170` and none inside `:84-86`, and the record states that `kb.html`'s M6 half
      is discharged by regeneration in task-071 rather than by a `CLAIMS` entry
- [ ] Unit-level coverage for this change is the guard's own `--list` mode plus the replay; no new test
      file is authored, `git diff --name-only HEAD -- tests/` lists exactly
      `tests/canonical/check-skill-counts.mjs`, and `git diff --exit-code -- site/scripts/__tests__/` is
      clean -- authoring a suite under either tree is barred by feature-001 AC-3
- [ ] All existing tests still pass: the canonical helper suites are green, and
      `git diff --name-only HEAD` lists **only** `tests/canonical/check-skill-counts.mjs` plus the
      residual count-line fixes this task made -- each of which is enumerated in the record with its
      document and mode. A changed file that appears in neither list is the finding
- [ ] All section-6 quality gates pass
