# work-009 Crash Recovery Report

> **UPDATE — execution phase fully recovered.** The initial report below was written
> before I found the **48 sub-agent transcripts** under
> `…/0a0f750a…/subagents/`. Those captured the entire execution phase. The
> "unrecoverable code" section below is now **superseded** — see this update.

## Execution-phase recovery (from sub-agent transcripts)
The dispatched sub-agents recorded their own tool calls. Replaying every Write/Edit across
all 48 transcripts + the orchestrator, in global timestamp order, onto the `master` base
reconstructed **168 files** — **157 byte-for-byte clean**, 11 with a minor gap.

**Recovered scripts (the ones you asked about):**
- `canonical/aid/scripts/execute/writeback-state.sh` — the new YAML STATE.yml writer (1,718 lines)
- `dashboard/reader/reader.py` (1,671), `parsers.py` (2,165), `derivation.py`, `state_schema.py`
- `dashboard/server/reader.mjs` — Node reader twin (5,484 lines; 34 of 35 edits applied)
- `bin/aid`, `bin/aid.ps1`, migration scripts, install libs

**Recovered skills/templates:** 40+ `canonical/skills/**` retargeted to YAML, plus 3 new
`.yml` templates (`work-state-template.yml`, `task-state-template.yml`, `delivery-state-template.yml`)
and 6 new `STATE.yml` fixtures.

**Recovered tests:** 18 `tests/canonical/*.sh` + ~30 dashboard test suites.

**Recovered work docs (full now):** SPEC (107/111 edits), REQUIREMENTS, PLAN, BLUEPRINT, all 21 task DETAILs.

### The 11 files with a minor gap (one or more edits didn't cleanly re-apply — spot-check these)
`STATE.md` (tracking file — restored from stitched reads instead), `SPEC.md` (4/111),
`BLUEPRINT.md` (1), `bin/aid` (1/10), `canonical/aid/templates/shortcut-engine.md` (1/23),
`canonical/skills/aid-describe/references/elicitation-engine.md` (1), `dashboard/scripts/writeback-state.sh`
(9/12 — this is a vendored twin; the canonical writer is clean), `dashboard/server/reader.mjs` (1/35),
`tests/canonical/test-housekeep-workfolder-safety.sh` (1), task-006 & task-018 DETAILs (1 each).

Cause: a few edits sat on top of a Bash/`sed`-produced intermediate state that isn't captured as a
tool Write/Edit, so the base drifted by a few lines. Everything else is exact.

---
_Original (pre-sub-agent-discovery) report follows._


**Recovered:** 2026-08-13 (after a disk-wipe erased the `work-009-refactor` worktree,
including its `.git`; the branch was never pushed).
**Source:** the Claude Code session transcript that survived the wipe at
`C:\Users\andre.vianna\.claude\projects\C--Projects-Personal-AID--claude-worktrees-work-009-refactor\0a0f750a-b003-4602-9986-a376027afbbe.jsonl`
(5,958 lines; session ran a FULL AID pipeline and crashed 2026-08-14 02:14 UTC).

## What work-009 was
A **behavior-preserving refactor**: convert the per-work `STATE.md` tracking files to a
machine-readable `STATE.yml` — preserving every scalar/row/section, **without** changing the
data model. Target design captured in `design/STATE-yml-target.md`.

## How recovery worked (and its hard limit)
The transcript records what the **orchestrator** did directly (Write/Edit) and every file it
**Read**. It does **not** contain the file edits made by the 48 dispatched **sub-agents** —
those lived only in the wiped worktree. So:
- Orchestrator **writes** → recovered in full.
- Orchestrator **edits** that apply to clean `master` → recovered in full.
- Files only **read** → recovered *as far as the slice that was read* (large files are partial).
- Sub-agent code edits → **not in the transcript**; only partial read-fragments survive.

## Recovery tiers

### ✅ High confidence — full content
| File | Lines | How |
|---|---|---|
| `design/STATE-yml-target.md` | 77 | full write |
| `.aid/works/work-009-refactor/known-issues.md` | 39 | full write |
| `.aid/works/work-009-refactor/tasks/task-021/DETAIL.md` | 88 | full write |
| `.gitignore` | — | edit applied cleanly to master |

### 🟨 Medium — read snapshots, likely complete (small task specs read whole)
`tasks/DETAIL.md` for tasks **002, 003, 004, 005, 006, 009, 010, 011, 012, 013, 015, 016, 017, 018**
and `.aid/.temp/review-pending/shortcut-work-009-refactor-defn.md`.

### 🟧 Partial — only a read slice survived (incomplete)
| File | Recovered | Note |
|---|---|---|
| `.aid/works/work-009-refactor/SPEC.md` | ~30 of ~700 lines | only the tail (§D-6 on) was ever read; rest lost |
| `.aid/works/work-009-refactor/STATE.md` | 209 of 386 lines | stitched from 14 timestamped reads (latest-wins); missing lines 23–181 and 260–277 are marked inline with `<<< LINE N NOT CAPTURED >>>` |
| `tasks/task-007/DETAIL.md` | empty | no usable content captured |

### 🟥 Could not recover cleanly (sub-agent changed them first)
Best-effort reconstruction + read-fragments saved under **`recovery/partial/`**:
- `bin/aid`
- `dashboard/server/reader.mjs`
- `canonical/aid/templates/reviewer-dispatch.md`

These are real work-009 changes (e.g. `reader.mjs` is one of the STATE readers), but the
orchestrator's edits sat on top of sub-agent versions that the transcript never fully captured.

### ⬛ Not in the transcript at all (gone)
- Task specs for **task-001, 008, 014, 019, 020**.
- The actual conversion **code** produced by sub-agents: the `STATE.yml` writer
  (`writeback-state.sh`), the Python/Node readers, the `STATE.yml` template, and the
  cross-runtime conformance corpus. These were written into the worktree by sub-agents and
  are unrecoverable from this transcript.

## Note on location
`.aid/works/**` and `.aid/.temp/**` are **gitignored** (work folders are local-only), so those
recovered files exist on disk but will not show in `git status` and will not commit. The
durable source of truth is the transcript above — recovery can be re-run from it at any time.
