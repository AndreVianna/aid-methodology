# State: KB-DELTA

KB-DELTA is a lightweight, drift-focused **re-discovery**: you (the agent)
autonomously inspect the actual repository content against what the Knowledge
Base claims, find what has drifted, and drive a targeted re-approval through
`/aid-discover`'s existing gate. Detecting and scoping the drift is **analysis
you perform**, not deterministic logic encoded in a script — there is no
delta-detection or path-mapping helper, no `Approved-At-Commit:` field. Git
history is an *optional hint* about where to look first, not the boundary of
what you inspect.

It is entered after PREFLIGHT succeeds, when `**KB Stage:**` is absent / `—` /
`stalled` / `running` (resume rows 1, 3) and `**Mode:** full` (the default —
not `cleanup-only`). On first entry you run Steps 1–4 (inspect + scope +
delegate); a resume after the user acts on the synthesized Q&A re-enters and
runs Steps 5–6 (read-back + gate). Resume is disk-driven: read
`.aid/knowledge/STATE.md` for the synthesized entry's `**Status:**` and for a
fresh `**User Approved:**` to know which half to run.

⚠️ **FILESYSTEM IS THE ONLY SOURCE OF TRUTH.** Do NOT rely on memory from a
previous run. Always read the actual files on disk.

---

## On entry — write run-state + ensure branch

Locate `<STATE_FILE>` as this work's `.aid/work-NNN-*/STATE.md`. Write through
feature-001's `housekeep-state.sh` (never hand-edit `## Housekeep Status`):

```bash
bash .cursor/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "State" --value "KB-DELTA"
bash .cursor/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Stage Status" --value "running"
bash .cursor/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Last Run" \
    --value "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
```

KB-DELTA is the first stage to write, so ensure the `aid/housekeep-*` branch
exists, then record it:

```bash
bash .cursor/scripts/housekeep/branch-commit.sh \
    --ensure-branch --slug "$(date +%Y-%m-%d)"
BRANCH=$(git rev-parse --abbrev-ref HEAD)
bash .cursor/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Branch" --value "$BRANCH"
```

Print the `[State: KB-DELTA]` banner from `SKILL.md § State Detection`.

---

## Step 1 — Read the hint, optionally refresh git (C2: git is a hint)

Read `**Last KB Review:**` from `.aid/knowledge/STATE.md`
(`grep -m1 '\*\*Last KB Review:\*\*'`) — the date the KB was last approved. This
is your *starting hint* for where to look, not a boundary.

Optionally bring git up to date so the hint reflects the real remote state:

```bash
git fetch origin master 2>/dev/null || true
```

- **Fetch succeeded** → you may run `git log --oneline <Last-KB-Review-date>..origin/master`
  and `git diff --name-only` over that range to see what *recently* changed —
  useful to focus attention first.
- **Fetch failed (offline)** → say so plainly and proceed from local state and
  broader content inspection. There is **no hard offline gate** (C2): the
  reconciliation is not bounded by git, so a missing network only removes a
  convenience hint. Do NOT pause for offline permission.

The git range is a hint only. You are **not limited to it** — proceed to Step 2
regardless of whether git was available.

## Step 2 — Inspect repo content vs KB claims; find the drift (AC1)

Autonomously read the actual repository content (code, data, docs) and
reconcile it against what each KB document claims. Use the git hint to
prioritize recently-changed areas first, then widen: a purely git-scoped pass
would miss drift that was subtly wrong all along (KB claims that never matched
reality), and AC1 requires catching that too.

For each KB document, ask: *does what this doc asserts still match the repo?*
Look for, e.g.:

- Skills/scripts/agents that were added, removed, or renamed but the KB still
  describes the old shape (`architecture.md`, `module-map.md`,
  `feature-inventory.md`, `pipeline-contracts.md`).
- Contracts, schemas, or templates that changed (`pipeline-contracts.md`,
  `schemas.md`).
- Test suites added/removed (`test-landscape.md`).
- Setup/infra changes (`infrastructure.md`).
- Stale counts, file lists, or anchors that no longer resolve.

Plan the corrections: the specific KB docs that have drifted and *what* in each
needs to change. This is your analysis — record it as the proposed scope for
Step 3. If you find **no drift** (the KB already matches the repo), go to the
**no-drift** exit below (AC4).

## Step 3 — Propose the scope; confirm-and-adjust (AC2, NFR3)

Present the affected docs and the corrections you found, and pause for the user
to confirm or adjust before any KB change (NFR3 transparency — no silent KB
edits):

```
KB drift detected (hint: git delta since <Last-KB-Review>, plus content review).
Proposed KB refresh scope:
  architecture.md   — <one-line: what drifted / correction>
  module-map.md     — <one-line>
  test-landscape.md — <one-line>
[1] Confirm — refresh this scope
[2] Adjust  — add/remove docs: ___
[3] Cancel  — stall this stage
```

- `[1]` → carry the confirmed doc list to Step 4.
- `[2]` → the user adds or drops docs; recompute the confirmed list.
- `[3]` → write `**KB Stage:** stalled` + `**Stall Reason:** KB refresh scope
  cancelled` and PAUSE (stalled exit below).

## Step 4 — Synthesize an `Impact: Required` Q&A entry + invoke `/aid-discover` (AC3)

You do **not** duplicate the review/approval machinery — you reuse
`/aid-discover`'s **existing** Targeted Discovery re-entry
(`.cursor/skills/aid-discover/SKILL.md § Targeted Discovery (Re-entry)`),
which runs *only* the affected sub-agents when a Pending Q&A entry with
`**Impact:** Required` names what needs refreshing (entered from `/aid-discover`'s
State Detection State 3). Drive it by **writing exactly such an entry**.

Append one Q&A entry to `.aid/knowledge/STATE.md` `## Q&A (Pending)` in the
canonical Style A schema (`### Q{N}` + sub-bullets — `coding-standards.md §12`).
`{N}` is the next integer after the highest existing `### Q{N}`
(`grep '### Q[0-9]\+'`). Populate it with the user-confirmed scope from Step 3:

```markdown
### Q{N}
- **Category:** Housekeep / KB Delta Refresh
- **Impact:** Required
- **Status:** Pending
- **Context:** /aid-housekeep reconciled the repo against the KB and found drift in:
  <architecture.md, module-map.md, …>. Corrections: <one line per doc>. These docs
  need targeted re-discovery.
- **Suggested:** Re-run the sub-agents that own these docs (targeted re-discovery),
  then REVIEW → APPROVAL.
```

`**Impact:** Required` is what forces `/aid-discover` into Q-AND-A → targeted
re-entry regardless of the current grade. `/aid-discover`'s re-entry resolves
each named doc to its owning sub-agent via its own `owns-<agent>` accessor — you
do not resolve owners yourself.

Then invoke `/aid-discover` to drive its state machine (targeted re-entry →
REVIEW → Q-AND-A → FIX → APPROVAL). Because sub-agents run, this dispatch
operates **under `SKILL.md § Dispatch Protocol (L1+L2+L3)`** (heartbeat
pre-create via `read-setting.sh --path traceability.heartbeat_interval
--default 1`, three armed L2 timers as separate background dispatches,
Calibration-Log writeback). Inherit that protocol — do not re-implement it. Take
the ETA band from `.cursor/templates/rough-time-hints.md` for the
discovery-subagent class.

After invoking, the stage pauses for `/aid-discover` to settle; the re-entry
(below) reads back the result.

---

## Step 5 — Read back: did a fresh approval land? (re-entry)

On re-entry, re-read `.aid/knowledge/STATE.md` (filesystem = source of truth):

- `/aid-discover`'s targeted re-entry flips the synthesized entry's
  `**Status:**` to `Answered` and resets `**Grade:**` to `Pending`, so a fresh
  REVIEW runs; on APPROVAL it writes `**User Approved:** yes` with a fresh date
  (`aid-discover/references/state-approval.md`).
- Check that `**User Approved:** yes` carries a date **newer than this run's
  start** (`grep -m1 '\*\*User Approved:\*\*'`).

If a fresh approval is present → Step 6 (passed). If it is missing, declined, or
the grade is still below minimum with no resolution → the **stalled** exit.

## Step 6 — Passed: mark stage, commit, chain

A fresh `**User Approved:** yes` was reached. Write the gate field and commit the
refreshed KB:

```bash
bash .cursor/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "KB Stage" --value "passed"
bash .cursor/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Stage Status" --value "passed"
bash .cursor/scripts/housekeep/branch-commit.sh \
    --commit --message "chore(housekeep): KB delta refresh [feature-002]" \
    --add .aid/knowledge/
```

**Advance:** CHAIN → SUMMARY-DELTA.

---

## Exit — no drift (AC4)

Step 2 found the KB already matches the repo (or every change you saw was a KB
self-edit, not a source delta). Print:

```
✓ KB current — no drift between the repo and the Knowledge Base; skipping refresh.
```

Then write `**KB Stage:** skipped`, dispatch **no** sub-agents, make **no**
commit (NFR2 idempotent), and CHAIN to SUMMARY-DELTA:

```bash
bash .cursor/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "KB Stage" --value "skipped"
bash .cursor/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Stage Status" --value "skipped"
```

**Advance:** CHAIN → SUMMARY-DELTA.

## Exit — stalled (scope cancelled or re-approval declined)

Reached when Step 3 was cancelled (`[3]`) or Step 5 found no fresh approval
(declined / still below grade with no resolution):

```bash
bash .cursor/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "KB Stage" --value "stalled"
bash .cursor/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Stage Status" --value "stalled"
bash .cursor/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Stall Reason" --value "<reason>"
```

Print the resume banner, then PAUSE:

```
⏸  /aid-housekeep paused at KB-DELTA — <reason>.
   Fix: <actionable instruction>.
   Resume: re-run /aid-housekeep — it will pick up at KB-DELTA (not job 1).
```

**Advance:** PAUSE-FOR-USER-ACTION (re-run resumes at KB-DELTA via `SKILL.md §
State Detection` row 3).
