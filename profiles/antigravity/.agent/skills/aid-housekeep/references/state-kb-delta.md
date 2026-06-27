# State: KB-DELTA

KB-DELTA is a lightweight, drift-focused **re-discovery**: you (the agent)
autonomously inspect the actual repository content against what the Knowledge
Base claims, find what has drifted, and drive a targeted re-approval through
`/aid-discover`'s existing gate. Detecting and scoping the drift is **analysis
you perform**, informed by a **deterministic per-doc suspect pre-pass** (f007
`kb-freshness-check.sh`) that prioritizes which docs to re-examine first and
supplies a fast no-drift exit. No doc is skipped -- a `current` verdict proves
only source-ancestry, not summary-correctness (AC1: subtly-wrong-all-along).

> Cross-delivery reuse: Steps 1-2 consume task-040 (delivery-007, f007)
> `kb-freshness-check.sh` per-doc suspect verdicts. The closure re-verify
> (below) consumes task-008 (delivery-001, f004) `closure-check.sh` oracle.
> The boundary realized here is recorded in task-053 (this delivery,
> `pipeline-contracts.md`).

It is entered after PREFLIGHT succeeds, when `**KB Stage:**` is absent / `-` /
`stalled` / `running` (resume rows 1, 3) and `**Mode:** full` (the default --
not `cleanup-only`). On first entry you run Steps 1-4 (inspect + scope +
delegate); a resume after the user acts on the synthesized Q&A re-enters and
runs Steps 5-6 (read-back + gate). Resume is disk-driven: read
`.aid/knowledge/STATE.md` for the synthesized entry's `**Status:**` and for a
fresh `**User Approved:**` to know which half to run.

WARN **FILESYSTEM IS THE ONLY SOURCE OF TRUTH.** Do NOT rely on memory from a
previous run. Always read the actual files on disk.

---

## On entry -- write run-state + ensure branch

`<STATE_FILE>` is the project-level run-state file resolved by `SKILL.md S State
Detection` (`.aid/.temp/HOUSEKEEP_STATE_<ts>.md`; created on first write). Write
through `housekeep-state.sh` (never hand-edit `## Housekeep Status`):

```bash
bash .agent/aid/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "State" --value "KB-DELTA"
bash .agent/aid/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Stage Status" --value "running"
bash .agent/aid/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Last Run" \
    --value "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
```

KB-DELTA is the first stage to write, so ensure the `aid/housekeep-*` branch
exists, then record it:

```bash
bash .agent/aid/scripts/housekeep/branch-commit.sh \
    --ensure-branch --slug "$(date +%Y-%m-%d)"
BRANCH=$(git rev-parse --abbrev-ref HEAD)
bash .agent/aid/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Branch" --value "$BRANCH"
```

Print the `[State: KB-DELTA]` banner from `SKILL.md S State Detection`.

---

## Step 1 -- Deterministic suspect pre-pass (f007); optionally refresh git

Optionally bring git up to date so the local graph is current before the check:

```bash
git fetch origin master 2>/dev/null || true
```

- **Fetch succeeded** -- the local graph reflects origin/master. The `git fetch`
  is a convenience; the freshness check uses the local graph regardless.
- **Fetch failed (offline)** -- say so plainly and proceed. There is **no hard
  offline gate**: `kb-freshness-check.sh` uses pure local git plumbing (no
  network), so the suspect pre-pass runs against the local graph. Do NOT pause.

Now run the per-doc freshness check (task-040/f007) to capture the commit-graph-
exact set of drifted docs and their drifted sources:

```bash
SUSPECT_TSV=".aid/.temp/kb-freshness-$$.tsv"
bash .agent/aid/scripts/kb/kb-freshness-check.sh \
    --root .aid/knowledge --format tsv > "$SUSPECT_TSV"
# TSV columns (f007): doc-relpath | verdict | approved_at_commit |
#                     n_current | n_suspect | n_unknown | suspect_sources_csv
# verdict in {current, suspect, unknown}
```

Parse the TSV to separate docs by verdict:

- **suspect** rows: docs whose `sources:` changed after their
  `approved_at_commit:` baseline (commit-graph-exact drift signal). These are
  the **priority re-review set**; `suspect_sources_csv` names which source(s)
  drifted each doc -- start the content review there.
- **unknown** rows: docs with no approved baseline (f011 unstamped or untracked
  sources). No baseline to clear -- treat as un-cleared.
- **current** rows: docs whose declared `sources:` are at-or-before the baseline.
  A `current` verdict proves source-ancestry only, NOT summary-correctness. Still
  content-reviewed at lower priority (Tier 2 below).

The git-date range from `**Last KB Review:**` **is no longer the scoping
boundary**. The suspect pre-pass replaces it as the cheap, deterministic drift
signal. You are **not limited to suspect docs** -- proceed to Step 2 to review
all docs.

## Step 2 -- Two-tier whole-KB content review; find drift (AC1, f010 FR-33)

Review the entire KB in two tiers. Both tiers are always executed -- the verdict
sets **priority**, never a skip gate.

**Tier 1 -- Priority (suspect docs, definite drift).**
For each `suspect` doc (from Step 1), read the doc and each entry in its
`suspect_sources_csv`. Ask: *does what this doc asserts still match the repo
state in those changed sources?* Plan the correction: what specifically drifted
and what change is needed. This is the precise, source-keyed drift signal -- the
definite/priority re-review set with an exact pointer to where drift occurred.

Common patterns to look for:

- Skills/scripts/agents added, removed, or renamed since the doc's baseline
  (`architecture.md`, `module-map.md`, `feature-inventory.md`,
  `pipeline-contracts.md`).
- Contracts, schemas, or templates that changed (`pipeline-contracts.md`,
  `schemas.md`).
- Test suites added or removed (`test-landscape.md`).
- Setup or infra changes (`infrastructure.md`).
- Stale counts, file lists, or anchors that no longer resolve.

**Tier 2 -- Retained whole-KB content re-review (preserves AC1).**
After the Tier 1 suspect docs, content-review the remaining docs -- `unknown`
docs next (no baseline cleared), then `current` docs. For each, ask: *does what
this doc asserts still match the repo?* A `current` verdict proves only that the
declared `sources:` have not moved since approval; it does **not** prove the
doc's *summary* was ever correct. A doc can be subtly-wrong-at-approval with
stable `sources:` -- the exact AC1 "subtly-wrong-all-along" case. No doc is
skipped. Tier 2 is why KB-DELTA is the **broad/global/periodic** skill vs
`aid-update-kb`'s targeted speed.

**Result.** Collect the full drift list across both tiers:

- Suspect docs that confirmed drift (Tier 1 hit): note `suspect_sources_csv` as
  the flagging signal.
- Any unknown/current doc whose content review found a summary that no longer
  matches reality (Tier 2 hit): note "content drift (current-verdict doc -- AC1
  catch)" as the flagging signal.

If the full drift list is **empty** (zero suspect docs AND the retained whole-KB
content review found nothing), go to the **no-drift** exit below (AC4). Both the
deterministic signal and the content review must be clean before the exit fires.

## Step 3 -- Propose the scope; confirm-and-adjust (AC2, NFR3)

Present the affected docs annotated by the flagging signal, and pause for the
user to confirm or adjust before any KB change (NFR3 transparency -- no silent
KB edits):

```
KB drift detected (signal: kb-freshness-check suspect verdicts, prioritizing a whole-KB content review).
Proposed KB refresh scope:
  architecture.md   -- suspect: <suspect_sources_csv> drifted
  module-map.md     -- suspect: <suspect_sources_csv> drifted
  test-landscape.md -- content drift (current-verdict doc; summary no longer matches repo -- AC1 catch)
[1] Confirm -- refresh this scope
[2] Adjust  -- add/remove docs: ___
[3] Cancel  -- stall this stage
```

- `[1]` -> carry the confirmed doc list to Step 4.
- `[2]` -> the user adds or drops docs; recompute the confirmed list.
- `[3]` -> write `**KB Stage:** stalled` + `**Stall Reason:** KB refresh scope
  cancelled` and PAUSE (stalled exit below).

## Step 4 -- Synthesize an `Impact: Required` Q&A entry + invoke `/aid-discover` (AC3)

You do **not** duplicate the review/approval machinery -- you reuse
`/aid-discover`'s **existing** Targeted Discovery re-entry
(`.agent/skills/aid-discover/SKILL.md S Targeted Discovery (Re-entry)`),
which runs *only* the affected sub-agents when a Pending Q&A entry with
`**Impact:** Required` names what needs refreshing (entered from `/aid-discover`'s
State Detection State 3). Drive it by **writing exactly such an entry**.

Append one Q&A entry to `.aid/knowledge/STATE.md` `## Q&A (Pending)` in the
canonical Style A schema (`### Q{N}` + sub-bullets -- `coding-standards.md S12`).
`{N}` is the next integer after the highest existing `### Q{N}`
(`grep '### Q[0-9]\+'`). Populate it with the user-confirmed scope from Step 3:

```markdown
### Q{N}
- **Category:** Housekeep / KB Delta Refresh
- **Impact:** Required
- **Status:** Pending
- **Context:** /aid-housekeep reconciled the repo against the KB and found drift in:
  <architecture.md, module-map.md, ...>. Corrections: <one line per doc>. These docs
  need targeted re-discovery.
- **Suggested:** Re-run the sub-agents that own these docs (targeted re-discovery),
  then REVIEW -> APPROVAL.
```

`**Impact:** Required` is what forces `/aid-discover` into Q-AND-A -> targeted
re-entry regardless of the current grade. `/aid-discover`'s re-entry resolves
each named doc to its owning sub-agent via its own `owns-<agent>` accessor -- you
do not resolve owners yourself.

The targeted re-entry of `/aid-discover` also (re)runs f004's harvest over the
staged KB -- the fresh `candidate-concepts.md` it produces will be consumed by
the closure re-verify step after the KB edits land. Record the run start time
so the closure step can verify the harvest is fresh:

```bash
bash .agent/aid/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "KB-DELTA Run Start" \
    --value "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
```

Then invoke `/aid-discover` to drive its state machine (targeted re-entry ->
REVIEW -> Q-AND-A -> FIX -> APPROVAL). Because sub-agents run, this dispatch
operates **under `SKILL.md S Dispatch Protocol (L1+L2+L3)`** (heartbeat
pre-create via `read-setting.sh --path traceability.heartbeat_interval
--default 1`, three armed L2 timers as separate background dispatches,
Calibration-Log writeback). Inherit that protocol -- do not re-implement it. Take
the ETA band from `.agent/aid/templates/rough-time-hints.md` for the
discovery-subagent class.

After invoking, the stage pauses for `/aid-discover` to settle; the re-entry
(below) reads back the result.

---

## Step 5 -- Read back: did a fresh approval land? (re-entry)

On re-entry, re-read `.aid/knowledge/STATE.md` (filesystem = source of truth):

- `/aid-discover`'s targeted re-entry flips the synthesized entry's
  `**Status:**` to `Answered` and resets `**Grade:**` to `Pending`, so a fresh
  REVIEW runs; on APPROVAL it writes `**User Approved:** yes` with a fresh date
  (`aid-discover/references/state-approval.md`).
- Check that `**User Approved:** yes` carries a date **newer than this run's
  start** (`grep -m1 '\*\*User Approved:\*\*'`).

If a fresh approval is present -> Step 6 (passed). If it is missing, declined, or
the grade is still below minimum with no resolution -> the **stalled** exit.

## Step 6 -- Passed: closure re-verify BEFORE commit, then commit and chain

A fresh `**User Approved:** yes` was reached. The staged KB refresh is approved
but **not yet committed**. Before committing, re-verify concept-closure to
ensure the refresh left no native term undefined -- a standing invariant
(FR-34, task-008/f004). This step is inserted BETWEEN the approved KB edits and
the `branch-commit.sh --commit` call.

### Step 6a -- Ensure a fresh candidate-concepts.md

`closure-check.sh` (f004) requires `.aid/generated/candidate-concepts.md` as
its term-universe input. This file is produced by f004's harvest, which the
`/aid-discover` targeted re-entry ran in Step 4. Verify the file exists and is
newer than the `**KB-DELTA Run Start:**` timestamp recorded in Step 4:

```bash
CONCEPTS=".aid/generated/candidate-concepts.md"
RUN_START=$(grep -m1 '\*\*KB-DELTA Run Start:\*\*' <STATE_FILE> | \
    sed 's/.*\*\*KB-DELTA Run Start:\*\* *//')
CONCEPTS_MTIME=$(date -r "$CONCEPTS" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "")
```

If `candidate-concepts.md` is absent or its modification time is NOT newer than
`$RUN_START` (stale or predates the staged edits), re-run f004's harvest FIRST
so the term universe matches the staged-but-not-committed KB -- the closure
verdict must never be computed against a stale or absent term universe:

```bash
# Re-run harvest if candidate-concepts.md is stale or absent:
bash .agent/aid/scripts/kb/harvest-coined-terms.sh \
    --root . \
    --output .aid/generated/candidate-concepts.md
```

The closure verdict is **never** computed against a stale/absent term universe.
No new script -- this reuses f004's harvest + `closure-check.sh` (task-008/f004).

### Step 6b -- Run closure-check.sh

```bash
CLOSURE_OUT=".aid/.temp/closure-verify-a.md"
bash .agent/aid/scripts/kb/closure-check.sh \
    --output-a "$CLOSURE_OUT" \
    --output-b .aid/.temp/closure-verify-b.md
```

Read `$CLOSURE_OUT` (output (a) -- ungrounded/un-closed concept set). An empty
table body (no data rows beyond the header) means closure is intact. A non-empty
table body means the refresh introduced or exposed an undefined native term.

Clean up transients after reading:

```bash
rm -f .aid/.temp/closure-verify-a.md \
      .aid/.temp/closure-verify-b.md
```

### Step 6c -- Closure intact: mark, commit, chain

Closure is intact (output (a) is empty). Write the gate fields and commit the
refreshed KB:

```bash
bash .agent/aid/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Closure" --value "verified"
bash .agent/aid/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "KB Stage" --value "passed"
bash .agent/aid/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Stage Status" --value "passed"
bash .agent/aid/scripts/housekeep/branch-commit.sh \
    --commit --message "chore(housekeep): KB delta refresh [feature-002]" \
    --add .aid/knowledge/
```

**Advance:** CHAIN -> SUMMARY-DELTA.

### Step 6d -- Closure broken: escalate via Q&A + stall (never commit a hole)

Closure is broken (output (a) contains ungrounded term rows). Do NOT commit.
Append one Q&A entry to `.aid/knowledge/STATE.md ## Q&A (Pending)` (Style A;
`### Q{N}` where `{N}` is next after the highest existing `### Q{N}`):

```markdown
### Q{N}
- **Category:** Closure / Standing Invariant Break
- **Impact:** Required
- **Status:** Pending
- **Context:** A KB change by /aid-housekeep (KB-DELTA refresh) left native term(s) undefined
  in the spine: <ungrounded-term @ doc:anchor, ...> (closure-check.sh output (a)). The KB is
  no longer self-contained -- a fresh reader cannot resolve these terms from the spine.
- **Suggested:** Ground each term into domain-glossary.md (a spine entry) via /aid-discover
  targeted re-entry naming domain-glossary.md + the using-doc, then re-verify closure.
```

The `Impact: Required` routes `/aid-discover`'s targeted re-entry to
`domain-glossary.md` (the spine) and the using-doc -- the same escalation
mechanism KB-DELTA Step 4 already uses. No new routing is introduced.

Then take the **stalled exit** (below) with:

```
**Stall Reason:** closure invariant broken -- undefined native term in the staged KB refresh (not committed)
```

The staged KB refresh is **left uncommitted** -- the KB hole is never committed
to the housekeep branch. Re-running `/aid-housekeep` resumes at KB-DELTA; once
the term is grounded and `closure-check.sh` output (a) is empty, the stage
advances and then commits.

---

## Exit -- no drift (AC4)

Step 2 found the KB already matches the repo: zero suspect docs (Step 1
deterministic check) AND the retained whole-KB content review (Step 2 Tier 2)
found nothing wrong -- both the deterministic signal and the content review are
clean. Print:

```
KB current -- no drift between the repo and the Knowledge Base; skipping refresh.
```

Then write `**KB Stage:** skipped`, dispatch **no** sub-agents, make **no**
commit (NFR2 idempotent), and do NOT run the closure re-verify step (nothing
changed):

```bash
bash .agent/aid/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "KB Stage" --value "skipped"
bash .agent/aid/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Stage Status" --value "skipped"
```

**Advance:** CHAIN -> SUMMARY-DELTA.

## Exit -- stalled (scope cancelled, re-approval declined, or closure broken)

Reached when Step 3 was cancelled (`[3]`), Step 5 found no fresh approval
(declined / still below grade with no resolution), or Step 6d detected a
closure invariant break (refresh uncommitted):

```bash
bash .agent/aid/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "KB Stage" --value "stalled"
bash .agent/aid/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Stage Status" --value "stalled"
bash .agent/aid/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Stall Reason" --value "<reason>"
```

Print the resume banner, then PAUSE:

```
[!] /aid-housekeep paused at KB-DELTA -- <reason>.
   Fix: <actionable instruction>.
   Resume: re-run /aid-housekeep -- it will pick up at KB-DELTA (not job 1).
```

**Advance:** PAUSE-FOR-USER-ACTION (re-run resumes at KB-DELTA via `SKILL.md S
State Detection` row 3).
