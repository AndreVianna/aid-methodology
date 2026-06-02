# KB Delta Refresh

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-02 | Feature identified from REQUIREMENTS.md §5 (FR1, FR2), §7 (C2), §8 (D1) | /aid-interview |
| 2026-06-02 | Q1 resolved: delegation via synthesized Q&A/IMPEDIMENT entry (existing re-entry, not a new entrypoint); naming disambiguated (path→doc scoping map) | /aid-interview (cross-reference) |
| 2026-06-02 | Technical Specification authored (detect-delta.sh CLI/exit contract, path→doc scoping map, synthesized Q&A delegation, Approved-At-Commit baseline + D1 edit, gate output, offline/bootstrap, tests) | /aid-specify |
| 2026-06-02 | FIX (review C+→re-gate): no-resolvable-owner branch in scope-delta (MEDIUM); baseline-ref reconciliation origin/master vs HEAD (LOW); Q&A cite 541-546 (LOW); build-project-index path cite (MINOR) | /aid-specify (review) |

## Source

- REQUIREMENTS.md §5 FR1 (SHA-anchored delta detection, online-first, date fallback),
  FR2 (auto-scoped, delegated, gated KB refresh)
- REQUIREMENTS.md §7 C2 (online-first, permissioned offline)
- REQUIREMENTS.md §8 D1 (approval writeback records the SHA)
- REQUIREMENTS.md §9 AC1–AC5
- REQUIREMENTS.md §6 NFR3 (transparency), NFR5 (tested)

## Description

The KB stage of `/aid-housekeep` — the core new logic the skill owns. It detects what changed
on `master` since the KB was last approved and refreshes only the affected Knowledge Base
documents. Detection is **SHA-anchored**: a new `Approved-At-Commit:` field in
`knowledge/STATE.md` records the approved `master` commit, and the skill computes
`git log/diff <approved-sha>..origin/master` after an **online-first** `git fetch`; if the
fetch fails it halts and requests explicit user permission before diffing local `master`
(no silent offline fallback). When no SHA exists yet (bootstrap/legacy), it falls back to the
recorded approval date and records a SHA at the next approval. It then **auto-maps** the
changed file paths to the owning KB docs/sub-agents via a new **path→doc scoping map**
(distinct from — and not to be conflated with — the existing filename→owner doc-set
ownership in `doc-set-resolve.md`),
shows the proposed refresh scope for confirm-and-adjust, and **delegates** the actual update
to `/aid-discover`'s targeted re-discovery + REVIEW→APPROVAL gate — reusing the approval
machinery rather than duplicating it — ending in a fresh `User Approved: yes`. This feature
also owns the matching small edit to `/aid-discover`'s approval writeback so it records
`Approved-At-Commit:` going forward (dependency D1).

**Delegation mechanism (resolved — Q1, 2026-06-02):** housekeep drives `/aid-discover`'s
**existing** targeted re-entry by **synthesizing a Q&A/IMPEDIMENT entry** in
`knowledge/STATE.md` populated with the affected doc/owner set produced by the path→doc
scoping map. `/aid-discover`'s dispatch path is **not** modified — only its approval writeback
is touched (the D1 SHA edit). This keeps the integration surface minimal and reuses the proven
re-entry rather than adding a new scoped-dispatch entrypoint.

## User Stories

- As an AID maintainer, I want the skill to find exactly what changed on `master` since the
  KB was approved so that I refresh only the affected docs, not everything.
- As an AID maintainer, I want to see and adjust the proposed refresh scope before anything
  runs so that I stay in control of what gets re-discovered.
- As an AID maintainer, I want detection anchored on a commit (not a fuzzy date) so that no
  change is missed or double-counted.

## Priority

Must

## Acceptance Criteria

- [ ] **AC1** — Given a KB approved at commit `X` with merges to `origin/master` since, when
  the skill runs, then it fetches and reports the changed paths from `X..origin/master`.
- [ ] **AC2** — Given no `Approved-At-Commit:` recorded, when the skill runs, then it falls
  back to the approval date and records a SHA at the next approval.
- [ ] **AC3** — Given the fetch fails, when the skill runs, then it halts and requests
  explicit permission before diffing local `master`; without permission it does not proceed.
- [ ] **AC4** — Given a delta, when the skill scopes it, then it auto-maps changed paths to
  owning docs/sub-agents, shows the scope for confirm/adjust, dispatches only those
  sub-agents through `/aid-discover` REVIEW→APPROVAL, ending in `User Approved: yes`.
- [ ] **AC5** — Given no delta, when the KB stage runs, then it reports "current," dispatches
  no sub-agents, and advances.
- [ ] **D1** — Given a KB approval (via `/aid-discover` or housekeep), when the writeback
  runs, then `Approved-At-Commit:` is set to the current `master` SHA in `knowledge/STATE.md`.

---

## Technical Specification

> Scope note: this feature authors the **body** of the KB-DELTA state that
> feature-001's skeleton routes into. feature-001 owns the thin-router, the
> `## Housekeep Status` run-state, `housekeep-state.sh`, `branch-commit.sh`, the
> `## Dispatch Protocol (L1+L2+L3)` block on `SKILL.md`, and the CHAIN/PAUSE/HALT
> advance machinery. This feature fills `references/state-kb-delta.md` (a stub
> per feature-001 SPEC § Layers & Components) and adds two new helper scripts plus
> one small edit to `/aid-discover`. **Contracts honored** (see § Cross-feature
> contracts honored): on exit this body writes `**KB Stage:** passed|skipped|stalled`
> in `## Housekeep Status`, reaches a fresh `**User Approved:** yes` in
> `.aid/knowledge/STATE.md` for the `passed` case, writes `**Approved-At-Commit:**`
> there, commits via `branch-commit.sh`, and inherits the L1/L2/L3 dispatch protocol
> for its sub-agent run.

### Data Model

**N/A as a relational schema** — AID ships no database
(`.aid/knowledge/schemas.md` § "There is NO relational database in AID"). The
persistent state this feature touches is two key-value fields in
`.aid/knowledge/STATE.md` (the KB approval baseline) and the `**KB Stage:**` field in
the work-area `## Housekeep Status` block — both defined in *Data/State Contracts*
below. The detection engine's intermediate data (changed paths, affected docs) is
ephemeral, computed per run.

### Data/State Contracts

#### S-1. Approval baseline — `**Approved-At-Commit:**` (FR1, D1, AC2)

A new field that joins the existing approval anchors in the `### Discovery State`
header block at the top of `.aid/knowledge/STATE.md` — alongside
`**User Approved:**` and `**Last KB Review:**` (see `.aid/knowledge/STATE.md:24-25`,
the `> **User Approved:**` / `> **Last KB Review:**` blockquote lines). It records the
`master` commit SHA at the moment the KB was approved:

```
> **Approved-At-Commit:** <40-char-sha> (recorded YYYY-MM-DD by <aid-discover|aid-housekeep>)
```

**Decision — blockquote line, same shape as its siblings.** The anchors it joins are
authored as `> **Field:** value` blockquote lines (verified `.aid/knowledge/STATE.md:22-26`),
so `**Approved-At-Commit:**` matches that shape and is grep-recoverable with
`grep -m1 '\*\*Approved-At-Commit:\*\*' .aid/knowledge/STATE.md`. *Rationale:* zero new
file conventions; it reads/writes with the same one-line `grep`/`sed` the sibling
anchors already use. *Rejected:* a structured table — the approval anchors are not a
table, and a one-value field does not warrant one.

**Readers:** the detection engine (S-1 → primary delta ref) and the bootstrap-fallback
date reader (AC2, reads `**Last KB Review:**` when this field is absent).
**Writers:** `/aid-discover`'s APPROVAL writeback (the D1 edit, § D1 Writeback) and this
feature's own post-approval writeback.

#### S-2. `**KB Stage:**` in `## Housekeep Status` (feature-001 contract)

This body is the sole writer of `**KB Stage:**` (`passed` | `skipped` | `stalled`) in
the work-area `## Housekeep Status` block (feature-001 SPEC § C-2 field table). It writes
through feature-001's `canonical/scripts/housekeep/housekeep-state.sh` writer (the same
helper that owns every `**Field:**` in that block) — this body does NOT hand-edit the
block. The gate before SUMMARY-DELTA reads this field.

### Feature Flow (the KB-DELTA state body)

`references/state-kb-delta.md` runs as a linear sequence inside one KB-DELTA entry,
mirroring the step-numbered body style of `/aid-summarize`'s state docs (e.g.
`canonical/skills/aid-summarize/references/state-preflight.md`). On its first entry it
runs Steps 1–4 (detection + scope); subsequent re-entries (resume after the user acts
on the synthesized Q&A) run Steps 5–6 (read-back + gate). Resume is disk-driven: the
body checks `.aid/knowledge/STATE.md` for the synthesized entry's `**Status:**` and for
a fresh `**User Approved:**` to know which half to run (mirroring the
`⚠️ FILESYSTEM IS THE ONLY SOURCE OF TRUTH` rule both sibling skills enforce).

```
KB-DELTA entry
  Step 1  detect-delta.sh ──► no delta ─► **KB Stage:** skipped, CHAIN  (AC5)
              │ fetch fails ─► PAUSE-FOR-USER-ACTION (offline permission)  (AC3)
              ▼ changed paths
  Step 2  scope-delta.sh  (path→doc map → affected docs → owning agents)
  Step 3  confirm-and-adjust scope with user                              (AC4)
  Step 4  synthesize Q&A entry in knowledge/STATE.md + dispatch /aid-discover
              targeted re-discovery (REVIEW→Q&A→FIX→APPROVAL)             (AC4)
  ── (re-entry) ──
  Step 5  read back: fresh **User Approved:** yes ?  ── no ─► **KB Stage:** stalled, PAUSE
  Step 6  write **Approved-At-Commit:** = master SHA; **KB Stage:** passed; commit; CHAIN
```

### Detection Engine (FR1, C2, AC1–AC3)

**Decision — a standalone deterministic script `canonical/scripts/housekeep/detect-delta.sh`.**
The git logic is pure, side-effect-light (one network call, the rest read-only), and the
highest-value thing to unit-test (NFR5); isolating it from the prose body lets the test
suite drive it with a fixtured repo. It sits beside feature-001's
`canonical/scripts/housekeep/housekeep-state.sh` and `branch-commit.sh` in the new
`canonical/scripts/housekeep/` directory (created by feature-001). *No existing
`canonical/scripts/` script runs git for branch/diff* — the only git reference today is
`canonical/scripts/kb/build-project-index.sh:44` listing `.git` as a prune dir — so these helpers are new and
presented as new (consistent with feature-001 SPEC § Git/VC Boundary).

**CLI contract:**

```
detect-delta.sh [--state-file <path>] [--offline-ok]
```

| Flag | Effect |
|------|--------|
| `--state-file` | KB STATE.md path (default `.aid/knowledge/STATE.md`). |
| `--offline-ok` | The user has granted offline permission (AC3). Without it, a failed fetch is fatal (exit 3); with it, diff falls back to local `master`. |

**Behavior (in order):**

1. **Read the baseline.** `grep -m1 '\*\*Approved-At-Commit:\*\*'` from `--state-file`,
   extract the 40-hex SHA. If absent → **bootstrap mode** (step 5).
2. **Online-first fetch.** Run `git fetch origin master 2>/dev/null`. On success the
   comparison ref is `origin/master`; record the resolved tip via
   `git rev-parse origin/master` (robust SHA read — never assume `origin/master` equals a
   local ref).
3. **Offline gate (C2/AC3).** If the fetch exits non-zero: WITHOUT `--offline-ok`, print the
   offline-permission prompt to stderr and **exit 3** (no diff — no silent fallback). WITH
   `--offline-ok`, set the comparison ref to local `master` (`git rev-parse master`) and
   continue. The prose body (Step 1) is what asks the user and re-invokes with `--offline-ok`;
   the script never prompts interactively (keeps it testable).
4. **Compute the delta.** `git diff --name-only <baseline-sha>..<compare-ref>` for changed
   paths; `git log --oneline <baseline-sha>..<compare-ref>` for the human-readable commit
   list. Print changed paths one-per-line to stdout. Exit **0** if paths exist, **10** if the
   range is empty (no-delta → AC5 / no-op signal — a distinct exit so the body branches
   deterministically rather than parsing stdout emptiness).
5. **Bootstrap mode (AC2).** No `**Approved-At-Commit:**`: read the date from
   `**Last KB Review:**` (fallback `**User Approved:** yes (YYYY-MM-DD…)` — both carry the
   date in `.aid/knowledge/STATE.md:24-25`), then
   `git log --since=<date> --name-only --pretty=format: <compare-ref>` (still online-first /
   offline-gated as above). Emit the same changed-path list + exit 0/10. The SHA is recorded
   at the next approval (Step 6 below), so subsequent runs use the precise SHA path.

**Exit-code contract:** `0` = delta found (paths on stdout) · `10` = no delta (clean) ·
`3` = fetch failed and `--offline-ok` not given (offline-permission needed) · `2` = arg/usage
error (matches the project convention in `read-setting.sh` Exit codes, `read-setting.sh:27-30`).

### Path→Doc Scoping Map (FR2 — the new logic this feature owns)

This is the **delta-scoping** map: changed **repo path** → affected **KB docs**. It is
**distinct from** the filename→owner map in `aid-discover`'s
`references/doc-set-resolve.md` (the `owner-of`/`owns-<agent>` accessors map a *KB filename*
to its owning discovery agent). The cross-reference Q1 flagged this naming: the scoping map's
*output* (KB filenames) is the *input* to the ownership accessor. This map is owned here; the
ownership accessor is reused, not duplicated.

**Decision — data, not code: a path-prefix→docs table embedded in
`canonical/scripts/housekeep/scope-delta.sh`** as a longest-prefix-match assoc-list. *Rationale:*
the mapping is project-knowledge that will drift as the repo grows; keeping it as a single
visible table (one writer) makes it auditable and unit-testable (NFR5), and the resolution
(longest-prefix match) is trivial deterministic bash. The KB docs it names are exactly the
declared doc-set filenames (`.aid/knowledge/architecture.md` etc.).

| Changed path prefix | Affected KB docs |
|---|---|
| `canonical/skills/` | architecture.md, module-map.md, feature-inventory.md, pipeline-contracts.md |
| `canonical/scripts/` | module-map.md, pipeline-contracts.md |
| `canonical/agents/` | architecture.md, module-map.md |
| `canonical/templates/` | schemas.md, pipeline-contracts.md |
| `canonical/recipes/` | pipeline-contracts.md, module-map.md |
| `profiles/` | architecture.md, pipeline-contracts.md, infrastructure.md |
| `.claude/skills/aid-generate/` | architecture.md, pipeline-contracts.md |
| `tests/` | test-landscape.md |
| `setup.sh`, `setup.ps1`, `run_generator.py` | infrastructure.md, architecture.md |
| `README.md`, `docs/`, `examples/` | repo-presentation.md |
| `methodology/` | architecture.md, domain-glossary.md |
| `.aid/knowledge/` (KB docs themselves) | **skip** (a KB self-edit is not a source delta) |
| *anything unmapped* | **flag for user** (conservative default) |

**Resolution algorithm (`scope-delta.sh`):**

1. Read changed paths on stdin (the `detect-delta.sh` output).
2. For each path, longest-prefix match against the table. `.aid/knowledge/**` matches → skip.
   Unmapped paths are collected into an `UNMAPPED` list.
3. Union the matched KB docs into the **affected-doc set**.
4. Resolve each affected doc → its **owning discovery agent** using `aid-discover`'s
   **existing** `owner-of <filename>` accessor (`references/doc-set-resolve.md` § "owner-of",
   the snippet `resolve_doc_set "$raw" | awk -F'\t' -v f="$fn" '$1==f{print $2}'`, sourced over
   `read-setting.sh --path discovery.doc_set`). This is the link between the two maps and the
   reason they must not be conflated. Two cases produce **no sub-agent dispatch** and are
   instead routed to the orchestrator-regeneration step of `/aid-discover`'s targeted re-entry:
   - **Owner = `orchestrator`** — feature-inventory.md, README.md, INDEX.md (per
     `doc-set-resolve.md` Ownership map).
   - **Owner resolves to empty** — the affected doc is **not present in the active doc-set
     ownership map** (e.g., `repo-presentation.md` under the default seed, or any
     project-custom KB doc that the active `discovery.doc_set` does not enumerate). Such a doc
     has no owning sub-agent; treat it exactly like the `orchestrator` case — surface it at
     confirm-and-adjust (Step 3) as *"no owning sub-agent — flagged for orchestrator/manual
     refresh"* and route it to the orchestrator regeneration step rather than dispatching or
     silently dropping it. This keeps the resolution algorithm **total** over any doc-set
     (default seed or custom override) and satisfies NFR3 transparency.
5. Emit two lists: **affected docs** and **owning agents** (deduped). Print `UNMAPPED` to
   stderr so the body can surface it at confirm time.

**Behavior for unmapped paths (conservative):** the body lists them at confirm-and-adjust
(Step 3) and asks the user whether to widen scope; default is to **flag, not silently drop**,
satisfying NFR3 transparency. Empty affected-doc set after mapping (every changed path was a
KB self-edit) is treated as no-delta → AC5 skip.

### Scope Confirmation Flow (FR2, AC4, NFR3)

Step 3 of the body. The orchestrator prints the proposed scope and pauses for confirm/adjust
before any dispatch — mirroring `/aid-discover`'s propose→confirm pattern for the doc-set
(`test-doc-set-propose-confirm.sh` exercises the analogous flow):

```
KB delta detected since <baseline> (N commits, M changed paths).
Proposed KB refresh scope:
  Docs:   architecture.md, module-map.md, test-landscape.md
  Agents: discovery-architect, discovery-analyst, discovery-quality
  Unmapped (not auto-scoped): scripts/new-thing.xyz  ← review?
[1] Confirm — refresh this scope
[2] Adjust — add/remove docs: ___
[3] Cancel — stall this stage
```

`[2]` lets the user add an unmapped path's docs or drop a doc; the agent set is recomputed from
the adjusted doc set via the same `owner-of` accessor. `[3]` writes `**KB Stage:** stalled` +
`**Stall Reason:** KB refresh scope cancelled` and PAUSES (feature-001 halt/resume).

### /aid-discover Delegation (Q1 resolved — mechanism (a))

**Decision — synthesize a Q&A entry; reuse the existing Targeted Discovery re-entry; do NOT
modify `/aid-discover`'s dispatch path.** `/aid-discover` already has a re-entry that runs
*only* the affected sub-agents when a Q&A entry or IMPEDIMENT in `.aid/knowledge/STATE.md`
names what is missing — `canonical/skills/aid-discover/SKILL.md § Targeted Discovery (Re-entry)`
(Steps 1–7: read the Q&A entry, resolve owner via `owns-<agent>`, dispatch only that agent,
regenerate INDEX/README, reset `**Grade:** Pending`, report). That re-entry is invoked from the
Q-AND-A state, which the State Detection enters when any Pending Q&A has
`**Impact:** Required` (`SKILL.md § State Detection` State 3: *"has Pending Q&A with Impact:
Required"*; `references/state-q-and-a.md:3`). Housekeep drives this by **writing exactly such an
entry**, then invoking `/aid-discover`.

**Step 4 — what gets written.** Append one Q&A entry to `.aid/knowledge/STATE.md`
`## Q&A (Pending)` in the canonical Style A schema (`coding-standards.md:541-546`;
`### Q{N}` + sub-bullets — the only canonical schema):

```markdown
### Q{N}
- **Category:** Housekeep / KB Delta Refresh
- **Impact:** Required
- **Status:** Pending
- **Context:** /aid-housekeep detected a delta on master since the KB was approved at
  <baseline-sha>. <N> commits touched: <changed-path summary>. The following KB docs are
  affected and need targeted re-discovery: <architecture.md, module-map.md, …>. Owning
  sub-agents: <discovery-architect, discovery-analyst, …>.
- **Suggested:** Re-run the named sub-agents (targeted re-discovery), then REVIEW→APPROVAL.
```

`**Impact:** Required` is what forces `/aid-discover` into Q-AND-A → targeted re-entry
regardless of grade (State 3). `{N}` is the next integer after the highest existing `### Q{N}`
(grep `### Q[0-9]\+`). The affected-doc/agent lists come verbatim from `scope-delta.sh`
(post-confirm), so the entry carries exactly the user-confirmed scope.

**Invocation + L1/L2/L3.** The body invokes `/aid-discover` to drive its state machine
(GENERATE/targeted re-entry → REVIEW → Q-AND-A → FIX → APPROVAL). Because sub-agents run, this
body operates **under feature-001's `## Dispatch Protocol (L1+L2+L3)`** already present on
`canonical/skills/aid-housekeep/SKILL.md` (feature-001 SPEC § Traceability, mirroring
`canonical/skills/aid-discover/SKILL.md § Dispatch Protocol`): heartbeat pre-create via
`read-setting.sh --path traceability.heartbeat_interval --default 1`, three armed L2 timers as
separate background dispatches, Calibration-Log writeback. This body does not re-implement the
protocol; it inherits it. ETA band from `canonical/templates/rough-time-hints.md` for the
discovery-subagent class.

**Read-back + routing to approval (Steps 5–6).** After `/aid-discover`'s machine settles, the
body re-reads `.aid/knowledge/STATE.md` (filesystem = source of truth):
- The synthesized entry's `**Status:**` flips to `Answered` and `**Grade:**` is reset to
  `Pending` by the re-entry (Step 6 of Targeted Discovery), so a fresh REVIEW runs.
- When `/aid-discover` reaches APPROVAL and the user approves, `**User Approved:** yes` is set
  with a fresh date (`references/state-approval.md` Step 3). The body checks the approval date
  is newer than this run's start.
- **Fresh approval present** → Step 6: write `**Approved-At-Commit:**` (master SHA) +
  `**KB Stage:** passed`, commit, CHAIN to SUMMARY-DELTA.
- **Approval declined / still below grade with no resolution** → `**KB Stage:** stalled` +
  `**Stall Reason:** KB re-approval declined`, PAUSE-FOR-USER-ACTION (feature-001 resume banner).

### Approval Baseline Writeback — this feature's own + the D1 edit

**Baseline-ref reconciliation (decision).** `**Approved-At-Commit:**` records the commit on
`master`'s history that the approved KB reflects, and detection always computes the range
`<Approved-At-Commit>..origin/master`. To keep the recorded baseline **symmetric with the
endpoint detection diffs against** (this feature's detection resolves the endpoint as
`git rev-parse origin/master` *after* its `git fetch` — see Detection Engine), each writer
records the commit representing the just-approved state:
- **housekeep (Step 6, below)** records `git rev-parse origin/master` — the post-fetch master
  state it caught the KB up to. (Recording local `master` would be wrong: on a fresh clone /
  worktree local `master` can lag `origin/master`, so the next run would re-report
  already-incorporated commits.)
- **`/aid-discover` (the D1 edit)** has no fetch of its own, so it records `git rev-parse HEAD`
  — the commit the approval was made against (which reaches `master` via the normal branch+PR
  flow).

**Invariant + safety:** the baseline must be an ancestor of `origin/master` for the range to
be meaningful; if it is not (e.g., the approving branch was never merged), detection's
bootstrap mode (AC2, date fallback) is the defined safety path, so a stale/divergent baseline
degrades gracefully rather than failing.

**This feature's writeback (Step 6).** After a fresh approval, the body writes
`**Approved-At-Commit:**` = `git rev-parse origin/master` (post-fetch) into
`.aid/knowledge/STATE.md`, idempotently (replace the line if present, else insert after
`**Last KB Review:**`).

**D1 edit to `/aid-discover` (dependency this feature owns).** Add a single line to
`canonical/skills/aid-discover/references/state-approval.md` Step 3, the `**[1] Approved:**`
bullet (currently `state-approval.md:23`):

> existing: `**[1] Approved:** Add **User Approved:** yes to .aid/knowledge/STATE.md. Add Review History entry…`
>
> add: `Also set **Approved-At-Commit:** to the approved commit SHA (git rev-parse HEAD) — replace the line if present, else insert after **Last KB Review:** (idempotent; back-compatible — older KBs simply lack the line until the next approval, which is the AC2 bootstrap path).`

*Idempotent / back-compatible:* writing replaces-or-inserts a single grep-anchored line; a KB
that predates the field is handled by the detection engine's bootstrap mode (AC2), so the edit
introduces no breaking dependency. After the D1 edit, a plain `/aid-discover` approval *also*
records the SHA, so housekeep stays on the precise SHA path even when the user approved outside
housekeep (satisfies D1's "going forward" intent).

### Gate Output (feature-001 contract)

On exit the body writes `**KB Stage:**` via `housekeep-state.sh`:
- `passed` — fresh `**User Approved:** yes` reached (AC4).
- `skipped` — no delta, or every changed path was a KB self-edit (AC5).
- `stalled` — offline permission denied (AC3), scope cancelled, or re-approval declined; also
  sets `**Stage Status:** stalled` + `**Stall Reason:**` and PAUSES per feature-001's
  halt/resume (the scaffold prints the resume banner; re-run resumes at KB-DELTA via
  feature-001 State Detection row 3).

### No-Delta No-Op (AC5)

`detect-delta.sh` exit 10 (clean range) OR an empty affected-doc set after scoping → the body
prints `✓ KB current — no source delta since <baseline>; skipping refresh.`, writes
`**KB Stage:** skipped`, dispatches **no** sub-agents, makes **no** commit, and CHAINs to
SUMMARY-DELTA. Satisfies NFR2 idempotency.

### Offline / Bootstrap Behavior (C2, AC2, AC3)

- **Offline (AC3/C2):** `detect-delta.sh` exit 3 when `git fetch` fails without `--offline-ok`.
  The body surfaces the explicit-permission prompt (`[1] proceed offline against local master
  / [2] abort`); only `[1]` re-invokes `detect-delta.sh --offline-ok`. `[2]` → `**KB Stage:**
  stalled` + PAUSE. **No silent fallback** — the offline diff runs only after explicit consent.
- **Bootstrap (AC2):** missing `**Approved-At-Commit:**` → date fallback via
  `**Last KB Review:**` + `git log --since`; the SHA is recorded at the next approval (Step 6),
  so the very next run uses the precise SHA path.

### Components / Scripts

**Owned by THIS feature:**

- `canonical/skills/aid-housekeep/references/state-kb-delta.md` — the KB-DELTA body (fills the
  feature-001 stub). Step-numbered prose in the style of
  `canonical/skills/aid-summarize/references/state-*.md`.
- `canonical/scripts/housekeep/detect-delta.sh` — delta detection engine (CLI/exit contract
  above). Pure git + grep; no new dependency (no `yq`/`python`), matching the
  bash-only constraint in `doc-set-resolve.md` § Implementation constraint.
- `canonical/scripts/housekeep/scope-delta.sh` — path→doc scoping map + `owner-of` resolution
  (algorithm above). Sources the `resolve_doc_set` snippet from `doc-set-resolve.md` over
  `read-setting.sh`.

**Edited by THIS feature (D1 dependency):**

- `canonical/skills/aid-discover/references/state-approval.md` — one-line addition to Step 3
  (above). The renderer re-emits it to all 5 profiles automatically
  (`.claude/skills/aid-generate/scripts/render_skills.py`, per feature-001 SPEC § Distribution),
  no renderer edit.

**Consumed (not owned):** feature-001's `housekeep-state.sh` (writes `**KB Stage:**`),
`branch-commit.sh` (one commit per stage, never push), the `SKILL.md` Dispatch Protocol block.
`/aid-discover`'s `SKILL.md § Targeted Discovery (Re-entry)` and `doc-set-resolve.md`
accessors (read-only reuse). `read-setting.sh` (settings + doc-set).

### Testing (NFR5)

New canonical suites under `tests/canonical/`, auto-discovered by the `test-*.sh` glob in
`tests/run-all.sh` (no edit to `run-all.sh` — it discovers by glob, sources `tests/lib/assert.sh`,
runs each under `timeout 300`; confirmed `tests/run-all.sh` lines for glob `suites=( tests/canonical/test-*.sh )`):

- `tests/canonical/test-housekeep-detect-delta.sh` — drives `detect-delta.sh` against a
  **throwaway fixtured git repo** (`git init`, seeded commits, a fake `origin` remote via a
  bare clone so `git fetch origin` is exercisable offline). Asserts: (a) SHA-anchored range
  produces the right changed-path set (AC1); (b) empty range → exit 10 (AC5); (c) missing
  `**Approved-At-Commit:**` → bootstrap date path (AC2); (d) simulated fetch failure without
  `--offline-ok` → exit 3 and no diff (AC3), with `--offline-ok` → local-master diff; (e) arg
  error → exit 2. Mirrors the throwaway-repo approach feature-001 SPEC prescribes for
  `test-housekeep-branch-commit.sh`.
- `tests/canonical/test-housekeep-scope-delta.sh` — drives `scope-delta.sh` with fixtured
  changed-path lists. Asserts each path-prefix row resolves to the expected doc set
  (longest-prefix match), `.aid/knowledge/**` → skip, unmapped path → flagged on stderr, and
  the doc→owner resolution matches `owner-of` for the default seed. Style mirrors
  `tests/canonical/test-doc-set-mapping.sh` and `test-discovery-doc-ownership.sh`
  (both already test the ownership accessors this feature reuses).

Git interactions are exercised against real throwaway repos (not stubbed) where cheap, and the
path→doc map is tested as pure data — both deterministic, both CI-wired via the existing glob.

### Cross-feature contracts honored

- **feature-001 § C-2** — sole writer of `**KB Stage:** passed|skipped|stalled` via
  `housekeep-state.sh`; never hand-edits `## Housekeep Status`.
- **feature-001 § Sequencing & Gates** — `passed`/`skipped` satisfies the gate before
  SUMMARY-DELTA; `stalled` triggers the scaffold's PAUSE-FOR-USER-ACTION resume banner (re-run
  resumes at KB-DELTA, State Detection row 3).
- **feature-001 § Git/VC Boundary** — every commit goes through `branch-commit.sh` (one commit
  per stage, never push); this body runs on the `aid/housekeep-*` branch but writes
  `**Approved-At-Commit:**` = `master` SHA (the branch the KB models).
- **feature-001 § Traceability** — sub-agent dispatch inherits the `SKILL.md` L1/L2/L3 Dispatch
  Protocol; no re-implementation here.
- **`/aid-discover` § Targeted Discovery (Re-entry)** — driven via a synthesized
  `**Impact:** Required` Q&A entry; its dispatch path is unchanged. Only `state-approval.md`
  Step 3 is edited (the D1 SHA line).
- **`doc-set-resolve.md`** — the path→doc scoping map's output feeds the existing
  `owner-of`/`owns-<agent>` accessors; the two maps stay distinct (Q1 naming).

### Sections marked N/A (this domain)

- **API Contracts** — N/A: AID ships no HTTP/RPC services
  (`.aid/knowledge/pipeline-contracts.md` § "AID ships no HTTP services or RPC endpoints").
  The "contracts" here are the `detect-delta.sh`/`scope-delta.sh` CLI + exit codes (above).
- **UI Specs / Mobile Specs** — N/A: no UI/mobile surface; interaction is the CLI/chat
  confirm-and-adjust flow.
- **Events & Messaging** — N/A: inter-skill handoff is filesystem state (the synthesized Q&A
  entry + `## Housekeep Status`), not a broker (`.aid/knowledge/integration-map.md`).
- **Migration Plan / Cache Strategy / Search/Indexing / Telemetry / Cloud / Hardware** — N/A:
  no runtime infrastructure (`.aid/knowledge/infrastructure.md` § "no conventional runtime
  infrastructure").
