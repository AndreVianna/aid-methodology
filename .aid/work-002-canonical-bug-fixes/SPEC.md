# Canonical Script & Agent Bug Fixes (Copilot findings)

- **Work:** work-002-canonical-bug-fixes
- **Created:** 2026-06-02
- **Source:** /aid-interview lite path — LITE-BUG-FIX
- **Status:** Ready

## Goal

Fix the real defects that Copilot (Bugbot) surfaced when the new AID claude/cursor profiles
were applied to downstream repos. The bugs were reported against the *installed* trees, but
they originate in `canonical/` — so they are fixed here once and propagated to all three
install trees via `/aid-generate`. Success = every confirmed-real finding corrected in
`canonical/`, the canonical test suite green, and the three generated trees regenerated and
verified. This work is isolated from `work-001-aid-housekeep` (it touches a disjoint set of
canonical files: the two `scripts/execute/` scripts and seven `agents/*/AGENT.md` files).

## Context

Thirteen distinct findings were confirmed real against canonical source (see the analysis
that seeded this work). Two reported findings are **false positives** and excluded; two are
minor/already-handled (one folded into a fix, one out of scope). Reproduction in every case
is "read the canonical file at the cited line."

**Scripts — `canonical/scripts/execute/complexity-score.sh`:**
- **A1** (`:168`) Risk scoring greps only `^\*\*Type:\*\*` (bold), but the canonical recipe
  template and all six recipes emit the flat `- Type: …` form (`recipe-template.md:58`,
  `bug-fix.md:57`, etc.). Every recipe-generated IMPLEMENT/TEST/REFACTOR/MIGRATE task scores
  risk=0, silently lowering the DELIVERY-GATE tier.
- **A2** (`:81`) `match($0, /delivery-([0-9]+)/, m)` is the gawk-only 3-arg form. On BSD/macOS
  awk and mawk it errors → empty graph → wrong tier. (`compute-block-radius.sh` already uses
  the portable 2-arg `match` + `substr` — mirror that.)
- **A3** (`:80-90`) `--plan-file` extraction only matches `#### Execution Graph` nested under
  `### delivery-`. Lite/recipe specs use a top-level `## Execution Graph`
  (`lite-spec-template.md:38`, every recipe) → empty graph → exit 2.
- **A4** (`:131-153`) `compute_depth` memoizes but has no in-progress guard; a cyclic
  `Depends On` table recurses until bash aborts.

**Scripts — `canonical/scripts/execute/compute-block-radius.sh`:**
- **B1** (`:138`) Graph parser only matches `/^####[[:space:]]+Execution Graph/`; lite/recipe
  `## Execution Graph` → empty graph.
- **B2** (`:31,281`) Header documents exit 2 as "warn but succeed with empty set," but the code
  `exit 2` (non-zero) — under `set -e` callers treat a valid case as failure. Contract and
  behavior must agree.
- **B3** (`:277-282`) `build_reverse_graph_from_plan` emits only *edges*; a declared leaf task
  with no deps and no dependents appears in no TSV row, so the existence check fails and the
  script exits 2 instead of returning an empty radius (exit 0). (Folds in **B5**: the first
  existence `grep` uses an unanchored `^task-001` that can prefix-match `task-0010` — replace
  with the anchored check.)
- **B4** (`:124-194,277`) No `--delivery-id` scoping: in a multi-delivery PLAN.md the parser
  merges every delivery's graph, so colliding per-delivery task IDs contaminate the radius.
  Asymmetric with `complexity-score.sh`, which already scopes by delivery.

**Agents:**
- **D1** Every agent carries the `## Heartbeat protocol` block, which mandates a shell-generated
  timestamp, but three lack the `Bash` tool: `interviewer` (Read, Glob, Grep),
  `simple-formatter` (Read, Write, Edit), `tech-writer` (Read, Glob, Grep, Write, Edit). Grant
  Bash to `interviewer` and `tech-writer`; `simple-formatter` is intentionally shell-less, so
  exempt it from the heartbeat protocol instead.
- **D2** (`discovery-quality/AGENT.md:69,86`) The agent is told to produce `infrastructure.md`
  but its Output Documents section embeds inline skeletons only for `test-landscape.md` and
  `tech-debt.md`. Add the `infrastructure.md` skeleton (the canonical
  `templates/knowledge-base/infrastructure.md` is the source of truth).
- **D3** (`discovery-reviewer/AGENT.md:94,206`) Internal contradiction: "14 primary KB docs"
  vs "16 primary KB docs." 14 is correct (15 KB templates minus README).
- **D4** (`discovery-reviewer/AGENT.md:232,251`) The ledger File Writing section uses
  `cat >` (full overwrite) with a single-row example while the prose says "append rows" — a
  literal cycle-2 write truncates prior findings. Make explicit that the heredoc must re-emit
  the complete carried-forward table.
- **D6** (`reviewer/AGENT.md`) Has tools `Read, Glob, Grep, Bash` (no Write) and an
  append-rows Output contract, but **no File Writing section** at all — no safe write
  mechanism. Add the `cat >`-heredoc File Writing section mirroring `discovery-reviewer.md`
  (with the complete-table contract from D4).

**Propagation:** all edits are in `canonical/`; the install trees and `.aid/generated/` are
stale until `/aid-generate` is run (task-014).

**Out of scope (with rationale):**
- A5 `find -maxdepth … -name A -o -name B` — false positive; `-maxdepth` is a global find
  option, both branches are depth-limited. No change.
- C1 `writeback-state.sh --findings "$2"` — false positive; `$2` holds the full quoted argv
  element including newlines. No change.
- D5 grade-vs-grade-free ledger — already handled: `discovery-reviewer/AGENT.md:226` routes the
  grade to the return message and keeps the ledger grade-free.

## Acceptance Criteria

- [ ] All thirteen confirmed-real findings (A1–A4, B1–B4, D1–D4, D6) are corrected in their
      canonical source files.
- [ ] `bash tests/run-all.sh` passes, including `tests/canonical/test-compute-block-radius.sh`
      and any new/extended coverage added by the script tasks.
- [ ] The two scripts work on lite/recipe specs (top-level `## Execution Graph`) as well as
      full multi-delivery `PLAN.md`, and remain portable under non-gawk awk.
- [ ] `/aid-generate` regenerates the claude-code, codex, and cursor trees; all three reflect
      the fixes and the generator's VERIFY step passes.
- [ ] All §6 quality gates pass.

## Tasks

> Each `tasks/task-NNN.md` uses `**Source:** work-002-canonical-bug-fixes → delivery-001`
> (lite path always uses `delivery-001`). Findings that share a document are fixed in one task.

| Task | Type | Document | Title |
|------|------|----------|-------|
| task-001 | IMPLEMENT | `scripts/execute/complexity-score.sh` | A1–A4: Type match, portable awk, lite/recipe graph, cycle guard |
| task-002 | IMPLEMENT | `scripts/execute/compute-block-radius.sh` | B1–B4: any-level graph, exit-2 contract, leaf-node radius (+B5), `--delivery-id` scoping |
| task-003 | CONFIGURE | `agents/{interviewer,tech-writer,simple-formatter}/AGENT.md` | D1: grant Bash (interviewer, tech-writer); exempt simple-formatter |
| task-004 | DOCUMENT | `agents/discovery-quality/AGENT.md` | D2: add `infrastructure.md` Output Document skeleton |
| task-005 | DOCUMENT | `agents/discovery-reviewer/AGENT.md` | D3+D4: fix 14-vs-16 doc count; ledger heredoc complete-table contract |
| task-006 | DOCUMENT | `agents/reviewer/AGENT.md` | D6: add File Writing (heredoc) section, mirroring discovery-reviewer |
| task-007 | CONFIGURE | (build) | Regenerate install trees (`/aid-generate`) and verify all three + full test suite |

## Execution Graph

### Task Dependencies

Each fix task owns a distinct document, so the six fix tasks run in parallel. task-006 takes a
content-consistency dependency on task-005 (it mirrors the finalized discovery-reviewer File Writing
section — different files, no edit collision). task-007 gates on all fixes.

| Task | Depends On |
|------|------------|
| task-001 | — (none) |
| task-002 | — (none) |
| task-003 | — (none) |
| task-004 | — (none) |
| task-005 | — (none) |
| task-006 | task-005 |
| task-007 | task-001, task-002, task-003, task-004, task-005, task-006 |

### Can Be Done In Parallel

| Wave | Tasks |
|------|-------|
| 1 | task-001, task-002, task-003, task-004, task-005 |
| 2 | task-006 |
| 3 | task-007 |

## Revision History

| Date | Change | Source |
|------|--------|--------|
| 2026-06-02 | Initial lite-path SPEC created from Copilot findings analysis | manual scaffold |
| 2026-06-02 | Merged same-document tasks: 14 → 7 (per-file fix passes); 13 findings unchanged in scope | task review |
