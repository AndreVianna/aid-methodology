# Delete Pipeline (Destructive)

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-17 | Feature identified from REQUIREMENTS.md §5.2 (FR-PL3) | /aid-define |
| 2026-07-17 | Technical Specification authored (autonomous run): `pipeline.delete` op + new `delete-pipeline.sh` writer on feature-001's OP_TABLE; worktree-aware folder+worktree removal; branch RETAINED; Running / current-worktree guards; type-to-confirm Danger-zone modal. OQ-PL3 resolved. Two candidate KIs (worktree-aware write path + branch-retention) flagged in the return — not registered here. | /aid-specify |
| 2026-07-17 | Fix cycle: corrected the false claim that the modal reads `branch_label` — that field is excluded from the DM-1 JSON envelope on both twins (Node non-enumerable, Python `_ser_work` omit), so the delete modal is now specified as worktree-agnostic (keyed only on `work_id`), with no plumbing/envelope change; rewrote the modal copy to drop the hardcoded `.claude/worktrees/<work_id>` path and the always-removed implication (shared-worktree caveat + branch-retention now stated conditionally). | /aid-specify (review fix) |
| 2026-07-17 | Fix cycle (REVIEW D+): dropped the phantom KI-009a/KI-009b citations (Change Log + §Data Model + §Security Specs) — never registered in this work's `known-issues.md`, so re-stated as candidate KIs surfaced in the return (mirrors feature-007's phantom-KI-010 fix); minted feature-local **AC-PD1** to replace the reused REQUIREMENTS §9 AC1, whose closed P1 interaction list excludes the P2 Delete feature (mirrors feature-008's AC-EC1); reconciled the work_id/args validation placement — the server validates `work_id` regex+len and rejects non-empty `args` **inline before spawn** (§Feature Flow step 7; dash in the failure table), with `delete-pipeline.sh` re-validating as a defense-in-depth backstop (exit 4/5 via feature-001's map), and gave the args-empty check a numbered Feature Flow step. | /aid-specify (review fix) |
| 2026-07-17 | Fix cycle (REVIEW E+, Phase-2): consumed feature-001's Q5 re-open hand-off. Removed the now-stale `cross_worktree` op-schema flag entirely (Applicable-sections, Feature Flow, Layers, API Contracts, Migration) — feature-001's step-6 `resolve_work_dir` (invariant **WT-1**) now resolves EVERY pipeline-scoped op's target incl. `pipeline.delete`, so no main-tree existence precheck survives for a flag to skip. Referenced `resolve_work_dir` + WT-1 + the `enumerate_worktree_roots` `(branch_label, aid_dir)` hand-off (`aid_dir.parent` = worktree root; verified `locator.py` 126/164) as the source of the worktree root+branch the destructive `git worktree remove` needs. Corrected the stale "main-tree write-op gap is an open candidate risk" narration (Data Model + Security Specs) — feature-001 remediated it at the foundation. Fixed the delete Algorithm to act on the SINGLE reconciled winner (`_reconcile_same_work` step 2, `reader.py` 131) rather than every found root — a `work_id` shadowed in multiple worktrees is no longer bulk-deleted (WT-1 symmetry; re-surface edge case documented, candidate KI in return). Pinned the `work_id`-validation failure to 422 (was "400/422"); reframed branch-retention as a resolved design decision (OQ-PL3); dropped the stale KI-001..004 enumerations (`known-issues.md` now holds KI-001..005). | /aid-specify (review fix) |

## Source

- REQUIREMENTS.md §5.2 FR-PL3 (Delete pipeline — destructive)

## Description

Completely remove a pipeline from the dashboard: its work folder
(`.aid/works/work-NNN-*`), and any associated worktree (`.claude/worktrees/work-NNN-*` via
`git worktree remove`), and — scope to confirm — its git branch. Because any pipeline
information not pushed to git is permanently lost, the operation requires a strong
confirmation gate.

This is distinct from Remove Project (feature-003), which only unregisters a whole project
and removes no files. Depends on the write-infrastructure foundation (feature-001) for the
operation endpoints.

## User Stories

- As a developer running AID on my own project, I want to delete a pipeline and its worktree
  from the dashboard behind a clear confirmation, so that I can clean up abandoned work
  without hand-removing folders and worktrees.

## Priority

Should

## Acceptance Criteria

- [ ] AC-PD1 — Given a pipeline, when I confirm deletion from the dashboard, then the delete is
  performed from the dashboard and the on-disk artifacts are removed. (Feature-local criterion,
  derived from FR-PL3 — a P2/"Should" feature. This is NOT the REQUIREMENTS.md §9 AC1, whose
  enumerated closed P1 interaction list excludes Delete; the shared "performed + artifacts-removed"
  shape is intentional, the identifier is not. AC2 and AC7 below map directly to the same-numbered
  REQUIREMENTS.md ACs.)
- [ ] AC2 — Given a pipeline is deleted, when the view re-renders, then the pipeline no longer
  appears and the view matches disk with no drift.
- [ ] AC7 — Given a delete request, when I trigger it, then it requires an explicit
  confirmation and removes the work folder + associated worktree.

## Open Questions

- **OQ-PL3 — Delete scope + guard — RESOLVED (2026-07-17, /aid-specify).**
  **Scope = work folder + its worktree; the git branch is RETAINED (NOT deleted).**
  Grounding: on disk a worktree-isolated work lives *inside* its worktree
  (`.claude/worktrees/<work_id>/.aid/works/<work_id>` — verified via `git worktree list`),
  so `git worktree remove --force` removes folder-and-worktree in one step; a main-tree work
  (no dedicated worktree) is removed with `rm -rf` on the folder alone. The **branch is kept**
  because (a) it is the sole recovery anchor — with the branch alive, `git worktree add <path>
  <branch>` fully reconstitutes a removed worktree, so worktree removal is *reversible* whereas
  branch deletion is *not* (unpushed commits become reflog-only and expire); (b) branch lifecycle
  belongs to the merge/PR flow (`gh pr merge --delete-branch`), not the dashboard; and (c) a
  dangling branch is **invisible to the dashboard** — the reader enumerates the *working-tree
  filesystem* across worktree roots (`enumerate_worktree_roots`, `git worktree list --porcelain`),
  and a branch with no checked-out worktree contributes no `.aid/works/*` directory, so the
  pipeline disappears from the view (AC2) without touching the branch. A manual `git branch -D`
  remains the explicit escape hatch. **Guard** (a safety measure this /aid-specify run introduces —
  REQUIREMENTS §5.2/AC7 mandate confirmation + folder/worktree removal but specify no such guard):
  the writer refuses (a) any work whose STATE.md frontmatter
  `lifecycle == Running`, and (b) the worktree the delete process is itself running from (and it
  never removes the main worktree — only the work folder within it). **Confirmation UX:** a
  type-to-confirm modal (type the `work_id` to enable the destructive button) in a Danger-zone
  region of the pipeline detail view — see §UI Specs.

---

## Technical Specification

> Authored by `/aid-specify` (autonomous run, 2026-07-17). This feature **consumes** the write
> mechanism delivered by **feature-001-write-infrastructure** — it does not re-invent it. It
> appends one row (`pipeline.delete`) to feature-001's `OP_TABLE`, ships one new co-vendored
> shell writer (`delete-pipeline.sh`), and adds one UI affordance (a type-to-confirm Danger-zone
> modal). The server stays LLM-free (SEC-4); all mutation happens in the dispatched child writer
> (SEC-3); no in-process fs-write is added to the server; the `--allow-writes` gate (AC8) and the
> reader-twin byte-parity discipline (AC4) are preserved by feature-001 and unchanged here.
>
> **Grounding anchors:** dashboard server twins `dashboard/server/server.py`
> (`do_POST` line 906; `_reject_bad_host` 871; `_route_get` 928; `_serve_repo_route` 999; id_map
> resolution `id_map.get(rid)` 1004; `_parse_args` 1113) + `dashboard/server/server.mjs`
> (non-GET→405 guard `method !== "GET"` line 682; `parseArgs` 65; `serveRepoRoute` 765; `idMap.get`
> 768); reader worktree enumeration `dashboard/reader/locator.py` `enumerate_worktree_roots` (126)
> + `dashboard/reader/derivation.py` `run_worktree_list` (287) / `detect_main_branch_label` (352);
> `dashboard/reader/reader.py` `read_repo` (318) enumerating worktree roots (435); the bash mirror
> of that enumeration `.../aid/scripts/works/enumerate-works.sh`; the existing single writer
> `.../aid/scripts/execute/writeback-state.sh` (exit-code alphabet, header lines 142–149; sentinel
> lock); the dashboard file-set manifest `dashboard/MANIFEST`; UI `dashboard/home.html`
> (`renderWorkHeader` 1901; `work-overview-body` 831; `doFetch`/poll loop 1020–1065; route dispatch
> `render` 1217 + `parseRoute` 1158; `renderStaleWorkNotice` call 1251; `_renderWorkCard` 1476).

### Applicable sections

| Section | Status | Why |
|---------|--------|-----|
| Data Model | Present (no DB) | The "store" is the on-disk `.aid/works/<work_id>` folder + its git worktree; this op *removes* those, so the relevant model is the removal target set, not a schema. |
| Feature Flow | Present | The confirm → POST → gate → dispatch → `delete-pipeline.sh` → navigate-to-main + re-fetch round-trip is the whole feature. |
| Layers & Components | Present | One `OP_TABLE` row (both server twins), one new writer, one UI affordance; reader twins unchanged. |
| API Contracts | Present | The `pipeline.delete` op row + the `delete-pipeline.sh` contract + one added row on feature-001's writer-exit→HTTP map. |
| Security Specs | Present | A destructive `rm -rf` / `git worktree remove` primitive lives in the writer — path-containment, the closed op allowlist, the Running / current-worktree guards, and SEC-1/3/4/6 preservation are the crux. |
| Migration / New Plumbing | Present | Co-vendor `delete-pipeline.sh` via `dashboard/MANIFEST`; no new op-schema flag (feature-001's worktree-aware `resolve_work_dir`/WT-1 already resolves this op's target); no envelope/schema-version change. |
| UI Specs | Present | A Danger-zone Delete control + type-to-confirm modal on the pipeline detail view, gated by `write_enabled`. |
| State Machines | N/A | No new state machine. Delete removes the unit outright; it does not transition a lifecycle enum (contrast feature-008 Finish, which sets `lifecycle=Completed`). |
| Telemetry & Tracking | N/A | Single-user trust model; no audit requirement. The writer prints one `OK:` summary line; the server logs failures to stderr. |
| Events & Messaging, DDD, BDD, CQRS, Cache, External Integrations, Batch/Jobs, Mobile, Search, AI, Recovery, Cloud, Hardware | N/A | None apply to a loopback, single-shot file/worktree removal. |

### Data Model

**No database, no schema change.** The removal targets, and the writer that owns each:

| Target | Removed how | Condition | Owning writer |
|--------|-------------|-----------|---------------|
| `<root>/.aid/works/<work_id>/` (the work folder) | `rm -rf` on the folder only | `<root>` is the **main** worktree, or a **shared** non-main worktree that also hosts other works | `delete-pipeline.sh` (**new**) |
| `<root>/` (a dedicated worktree — folder + worktree together) | `git -C <repo> worktree remove --force -- <root>` | `<root>` is a **non-main** worktree hosting **only** this work (its `.aid/works/` contains just `<work_id>`), *whatever its path* | `delete-pipeline.sh` (**new**) |
| git branch (e.g. `work-NNN`) | **NOT removed** | — | — (retained; see OQ-PL3) |

**Topology (verified on disk, `git worktree list`).** A worktree-isolated work lives *inside* its
worktree: `<repo>/.claude/worktrees/work-017-cli-improvements/.aid/works/work-017-cli-improvements/`.
The work folder is therefore **not present in the main tree** for such works — it is enumerated only
under the worktree root. This is why the delete op is **worktree-aware**: given only `work_id`, its
target on-disk directory is resolved exactly as the reader resolves it — via feature-001's
`resolve_work_dir(served_root, work_id)` (invariant **WT-1**, feature-001 SPEC §Layers), which reuses
`enumerate_worktree_roots` (`locator.py` line 126) and the `_reconcile_same_work` winner rule
(`reader.py` line 131) — never a reconstructed `<repo>/.aid/works/<work_id>` main-tree path.
feature-001's Q5 re-open added exactly this resolver and made **every** pipeline/task-scoped write op
worktree-aware, so the main-tree-assumption gap this feature originally surfaced is now **remediated
at the foundation** (feature-001 WT-1) — no longer an open, unregistered risk. The destructive delete
needs one thing beyond the resolved directory: the owning **worktree root + branch** for
`git worktree remove`. feature-001 hands both off explicitly (its §Layers Consumer Note, SPEC lines
275–281): derive them from the same `enumerate_worktree_roots` `(branch_label, aid_dir)` pairs, where
`aid_dir.parent` is the worktree root (verified `locator.py` line 164) and `branch_label` feeds the
same reconcile winner rule — so the writer targets exactly the copy `resolve_work_dir` returned (see
§API Contracts Algorithm).

**No frontmatter/field is written** — nothing calls `writeback-state.sh`; C1 (STATE writes through
the single writer) is not implicated because delete performs *no* STATE write, and C2 (DERIVED
read-only) is trivially honored (nothing is written; the folder is removed and the DERIVED union
views recompute without it).

### Feature Flow

```
Pipeline detail view (home.html #/work/<work_id>)        Dashboard server (server.py | server.mjs)
──────────────────────────────────────────────           ──────────────────────────────────────────
user opens Danger zone → clicks "Delete pipeline"
  │  (control only rendered when model.write_enabled === true)
  ▼ type-to-confirm modal: user types <work_id> to arm the button, clicks Confirm
POST /r/<id>/api/op                          ── HTTP ──▶  do_POST → _serve_op (feature-001)
  body: {op:"pipeline.delete",                          │  1. SEC-6 Host-header allowlist   → 403 bad-host
         target:{work_id:"work-NNN-slug"}}              │  2. write gate write_enabled?      → 403 read-only
                                                         │  3. parse body; oversize/malformed → 400
                                                         │  4. op ∈ OP_TABLE?                  → 400 unknown op
                                                         │  5. resolve <id> → repo path (id_map, verbatim; SEC-2)
                                                         │  6. validate work_id regex+len, then
                                                         │     resolve_work_dir(repo,work_id) → REAL dir
                                                         │     (worktree-aware, WT-1) → 404 if none
                                                         │  7. reject non-empty `args` (arg-schema) → 422
                                                         │  8. build argv ARRAY:  bash delete-pipeline.sh
                                                         │       --work-id <work_id>   (env AID_REPO_ROOT=<repo>)
                                                         │  9. spawn child (SEC-3: no in-process rm; SEC-4: shell,
                                                         │     not an agent) → capture exit code + stderr
                                                         │ 10. map exit code → HTTP status (feature-001 map + row)
  ◀── 200 {ok:true, op:"pipeline.delete"} ── or ── 4xx/5xx {ok:false, error, detail} ──┘
  │
  ▼ on ok: close modal → location.hash = "" (main route) → doFetch()
GET /r/<id>/api/model  ── truthful re-render (NFR3/AC2): read_repo re-enumerates worktree roots;
                          the removed reconciled-winner copy is gone → pipeline no longer appears.
  ▼ on 4xx/5xx: keep modal open, show inline error
     (e.g. 409 "Pipeline is Running — Finish it first"; 404 "Pipeline not found")
```

Race-safety of the navigation: if the poll happens to re-render the stale `#/work/<deleted>` route
before the hash change lands, `render` (home.html 1217) already routes an unknown `work_id` to
`renderStaleWorkNotice` (called at 1251) — the view degrades gracefully rather than erroring.

### Layers & Components

**1. Server layer** (`server.py` + `server.mjs`, byte-parity twins) — **one `OP_TABLE` row, no new
routing.** feature-001 owns the POST dispatch (its `_serve_op` in `server.py` and the matching
`server.mjs` twin), the Host-header + write-gate order, the argv-array child spawn, and the
exit-code→HTTP map. feature-009 only:
- Appends the `pipeline.delete` row to `OP_TABLE` in **both** twins (identical writer, argv-builder,
  arg-schema, scope) — see §API Contracts.
- Adds **no** op-schema flag. Target existence is resolved by feature-001's step-6
  `resolve_work_dir(repo, work_id)` (invariant WT-1) — the same worktree-aware resolver every
  pipeline-scoped op uses (404 if no worktree holds the `work_id`). feature-001's Q5 re-open made that
  resolution unconditional, so the flag-gated "skip the main-tree existence precheck" branch that an
  earlier draft's `cross_worktree` was invented to control no longer exists: `pipeline.delete` is
  resolved exactly like `pipeline.finish`/`pipeline.rename`. The writer additionally re-derives the
  owning **worktree root + branch** from the same `enumerate_worktree_roots` `(branch_label, aid_dir)`
  pairs (feature-001 §Layers Consumer Note; `aid_dir.parent` = root) to run `git worktree remove`.
- Adds one row to the exit-code→HTTP map: writer **exit 7 → HTTP 409 `pipeline-active`** (guard
  tripped: Running or current-worktree). No other server change; no new endpoint, no new listener.

**2. Writer layer — new `delete-pipeline.sh`** (bash, co-vendored with the dashboard unit,
self-located from `$AID_CODE_HOME`, added to `dashboard/MANIFEST` — same discipline as feature-001's
`write-setting.sh`/`write-requirement.sh`). It is the *only* component that performs removal. Full
contract in §API Contracts; behavior in §Security Specs (guards + containment).

**3. Reader / model layer** (`dashboard/reader/*.py` + `dashboard/server/reader.mjs`): **no change.**
Delete writes nothing the reader parses; after removal the existing `read_repo` enumeration simply
finds no rendered (reconciled-winner) copy of `.aid/works/<work_id>` and omits the pipeline (AC2). The model does
NOT gain a field — the writer re-derives the worktree root/branch itself from the
`enumerate_worktree_roots` `(branch_label, aid_dir)` pairs (feature-001 §Layers Consumer Note) that
`resolve_work_dir` also uses; the UI needs only `work_id` (already present). **`branch_label` never reaches the browser:** it is
deliberately excluded from the DM-1 JSON envelope on **both** twins — Node `reader.mjs` builds it as
`Object.defineProperty(..., { enumerable: false })` ("excluded from JSON.stringify"), and Python
`server.py` `_ser_work` omits it from its serialized whitelist (4425–4429 / 654–680). The delete modal
is therefore **worktree-agnostic and keyed only on `work_id`**, so no plumbing/envelope change is
introduced here (see §UI Specs).

**4. UI layer** (`dashboard/home.html`): a Danger-zone Delete control + confirmation modal, rendered
only when `model.write_enabled === true`. See §UI Specs. (index.html is untouched — pipeline-level
ops live on the per-project `home.html`, not the all-projects grid.)

### API Contracts

**`OP_TABLE` row appended by feature-009** (both twins; extends the feature-001 seed which listed
`pipeline.delete … see owning features … FR-PL3 … feature-009`):

| `op` | Scope | Writer + argv | Extra schema | Owning FR | Introduced by |
|------|-------|---------------|--------------|-----------|---------------|
| `pipeline.delete` | per-repo | `delete-pipeline.sh --work-id <work_id>` (env `AID_REPO_ROOT=<repo>`) | `args` MUST be absent/empty (no op-schema flag; target resolved server-side by feature-001 `resolve_work_dir`/WT-1) | FR-PL3 | feature-009 |

**Request** (feature-001 envelope; `POST /r/<id>/api/op`, `Content-Type: application/json`):

```json
{ "op": "pipeline.delete",
  "target": { "work_id": "work-017-cli-improvements" } }
```

- `op` = `pipeline.delete` (closed `OP_TABLE` key).
- `target.work_id` (required): validated `^work-[0-9]+(-[a-z0-9][a-z0-9-]*)?$`, length ≤ 64 — the
  **full folder name** (not the short `work-NNN` branch label). A value that fails the regex/length
  check → **422 `invalid-value`** (per the failure table); a structurally malformed or absent
  `target` envelope is the separate **400 `bad-request`** row. The repo path is
  resolved server-side from `id_map` (SEC-2); **no path is ever taken from the body** — the writer
  gets only the validated `work_id` and the server-resolved `AID_REPO_ROOT`.
- `target.delivery_id` / `target.task_id`: **not used** (whole-pipeline op).
- `args`: none; a non-empty `args` is rejected as an **arg-schema violation → 422 `invalid-value`**
  (aligning with feature-001's op-schema validation — its step 7 / exit-4 mapping, feature-001 SPEC
  lines 156, 287 — not 400, because `args` is a schema field, not a malformed envelope) — delete
  takes no parameters (no branch-delete toggle — branch retention is fixed policy, see OQ-PL3).

**Success (200):** `{ "ok": true, "op": "pipeline.delete" }`. Client then navigates to the main
route and re-fetches `/r/<id>/api/model` (NFR3/AC2).

**Failure** (feature-001 shape `{ok:false, op, error, detail}`), status via the feature-001 map plus
the added exit-7 row:

| Condition | Writer exit | HTTP | `error` |
|-----------|-------------|------|---------|
| Untrusted Host header | — | 403 | `bad-host` |
| Write gate closed (read-only) | — | 403 | `read-only` |
| Malformed/oversize body, unknown `op`, bad `target` shape | — | 400 | `bad-request` |
| `work_id` folder found in **no** enumerated worktree root | 1 | 404 | `not-found` |
| Lock contention (a `writeback-state.sh` sentinel held on the work) | 2 | 409 | `busy` |
| Non-empty `args` (op takes no parameters — arg-schema violation, mapped per feature-001 step 7) | — | 422 | `invalid-value` |
| Invalid `work_id` value/charset — rejected **inline server-side** before spawn (§Feature Flow step 6); `delete-pipeline.sh` re-validates as a standalone backstop (exit **4**, mapped via feature-001's 4→422) | — | 422 | `invalid-value` |
| Missing `--work-id` — the server always supplies it, so via the API this is only the writer-standalone backstop (exit **5**, mapped via feature-001's 5→422) | — | 422 | `invalid-value` |
| **Guard tripped — pipeline `lifecycle=Running`, or target is the current worktree** | **7** | **409** | **`pipeline-active`** (row added by feature-009) |
| Removal failed / unverified (`git worktree remove` nonzero, `rm` left residue, containment check failed) | 3 | 500 | `write-failed` |

**`delete-pipeline.sh` contract** (new; bash-only; `set -euo pipefail` — the coding-standards
dominant strict mode and exactly what `enumerate-works.sh` uses, not a weakened mode for an
irreversible destructive op; expected-nonzero git calls (e.g. `worktree list`) are explicitly
guarded / degrade in-subshell rather than relaxing the whole script; fixed-argv git, no shell
string, no `eval` — mirrors the reader's safe git posture and `enumerate-works.sh`):

```
delete-pipeline.sh --work-id <work_id>        [env AID_REPO_ROOT=<abs main repo root>]
```

Algorithm (all git calls are bounded `git -C <repo> …` with a fixed argv, degrading safely, exactly
like `derivation.run_worktree_list` / `enumerate-works.sh`):

1. Parse args (defense-in-depth backstop — the server already validated `work_id` regex+len and
   rejected non-empty `args` inline before spawn, §Feature Flow steps 6–7). Missing `--work-id` → **5**.
   `work_id` fails the regex above → **4**.
2. `REPO="${AID_REPO_ROOT:-$PWD}"`.
3. Enumerate worktree roots via `git -C "$REPO" worktree list --porcelain` — the bash mirror of the
   reader's `enumerate_worktree_roots` (`locator.py` line 126), yielding the same `(branch_label,
   aid_dir)` pairs feature-001's resolver consumes (`aid_dir.parent` = worktree root; main root always
   first, always included; degrade to main-only on any git failure).
4. `FOUND` = every root `R` where `-d "$R/.aid/works/<work_id>"`. Empty → **1** (404). (feature-001's
   step-6 `resolve_work_dir` already 404'd this server-side; the writer re-checks as a standalone
   backstop.)
5. **Select the single reconciled winner `$W` among `FOUND`.** Apply the *same* rule
   `resolve_work_dir` uses — `_reconcile_same_work` step 2 (`reader.py` line 131): newest STATE.md
   frontmatter `updated`; tie → `branch_label` lexical, `main` first. `$W` is therefore **exactly the
   copy the reader rendered and the modal confirmed** (consistency by construction — same rule, same
   enumeration; the reader-mirror pattern, like `enumerate-works.sh`). **Only `$W` is removed** — a
   `work_id` shadowed in another worktree is NOT bulk-deleted, matching WT-1 and every other
   pipeline-scoped write op. `$W`'s worktree root is its `aid_dir.parent`.
6. **Guards (before ANY removal), evaluated on `$W`:**
   - **Running guard:** read `$W/.aid/works/<work_id>/STATE.md` frontmatter `lifecycle` scalar (same
     leading-`---` block scan `enumerate-works.sh` uses). `== Running` → **7**.
   - **Current-worktree guard:** `CUR = git -C "$PWD" rev-parse --show-toplevel`; if `$W` is a
     non-main worktree to be `worktree remove`d and its realpath equals `CUR` → **7** (you cannot
     remove the worktree you are running from; the main worktree is never a removal target).
7. **Removal of `$W`** (best-effort `writeback-state.sh`-style sentinel lock on the work folder first;
   contention → **2**):
   - **Containment check:** realpath of `$W/.aid/works/<work_id>` MUST be a child of realpath
     `$W/.aid/works/`; else **3** (defeats symlink/`..` traversal).
   - `$W` is **main** → `rm -rf -- "$W/.aid/works/<work_id>"` (the main worktree is never removed).
   - `$W` is a **dedicated** non-main worktree — its `.aid/works/` contains **only** `<work_id>` and
     no other work (decided by *content*, not path: persistent worktrees are user-registered at
     arbitrary paths per `aid-execute/SKILL.md`, so a `.claude/worktrees/`+basename match is not a
     reliable signal) → `git -C "$REPO" worktree remove --force -- "$W"` (removes folder + worktree
     together; git auto-cleans the `.git/worktrees/<name>` admin dir).
   - `$W` is a **shared** non-main worktree — its `.aid/works/` hosts other works too →
     `rm -rf -- "$W/.aid/works/<work_id>"` only (never remove a worktree that hosts other works).
8. **Verify:** the removed folder must no longer exist; residue → **3**.
9. **Branch:** not touched (retained — OQ-PL3).
10. Print `OK: deleted <work_id> (folder[, worktree <path>])` to stdout; exit **0**.

### Security Specs

**Preserved feature-001 / KB invariants (no new network surface — C3):**
- **SEC-1** unchanged — literal `127.0.0.1` bind; no listener, port, or process added.
- **SEC-3 refined, not broken** — the server performs **no** in-process fs mutation for delete; the
  `rm -rf` / `git worktree remove` primitives live only in the child `delete-pipeline.sh`. The
  server-file audit (`grep` for `open(...,'w')`, `writeFileSync`, `unlink`, `os.remove`,
  `shutil.rmtree`) stays empty; the only new syscall is `subprocess`/`child_process` of the
  allowlisted writer with an **argv array** (never `shell=True`, never a concatenated string).
- **SEC-4 unchanged** — no agent/LLM import; the dispatched child is a shell script.
- **SEC-6 unchanged and load-bearing** — the Host-header anti-DNS-rebinding allowlist runs before the
  write gate on the POST path (feature-001), so a malicious page cannot drive a delete through a
  victim's browser even on a write-enabled loopback server; CSP `connect-src 'self'` +
  `form-action 'none'` (already on every `home.html` response) confine the modal's `fetch` to
  same-origin and forbid form-action navigation.
- **Write gate (AC8)** — `pipeline.delete`, like every mutation, is refused with HTTP 403 unless the
  server was spawned `--allow-writes` (loopback default ON; `--remote` OFF unless opted in). The UI
  renders the Delete control only when `write_enabled === true`.

**Destructive-primitive containment (this feature's crux):**
- The op is a **closed `OP_TABLE` key**; the writer name and argv shape are pre-declared, never
  client-chosen.
- The writer receives only a **regex-validated `work_id`** and the **server-resolved repo root**;
  it constructs every path itself and **realpath-contains** each removal target under
  `.aid/works/` before deleting — a crafted `work_id` cannot escape the works container, and a
  symlinked work folder fails the containment check (→ 500, no removal).
- `git worktree list --porcelain` (git's own truth), not a body-supplied path, identifies the
  worktree to `remove`; scoping `worktree remove` to worktrees that host **only** this work (a
  single `.aid/works/` entry) — by content, not a path-naming match — fully removes a dedicated
  worktree wherever the user registered it (AC7) while still protecting shared worktrees.
- **Guards** (a /aid-specify-introduced safety measure, not a REQUIREMENTS clause) prevent deleting
  the current/running pipeline: `lifecycle ==
  Running` and current-worktree both → 409, no removal. The main worktree is never removed (only the
  folder within it), so the running dashboard/CLI checkout can never be destroyed.
- **Irreversibility is fenced by UX, not code** (single-user trust model): the type-to-confirm modal
  (§UI Specs) is the human gate for the loses-unpushed-work hazard (AC7); branch retention keeps
  worktree removal itself reversible (`git worktree add <path> <branch>` reconstitutes a removed
  worktree). The fixed branch-retention policy is a **resolved design decision** (OQ-PL3) and the
  reusable design anchor for any future destructive dashboard op.

### Migration / New Plumbing

- **New co-vendored writer `delete-pipeline.sh`.** Added by appending its one path to
  `dashboard/MANIFEST` (alongside the feature-001 writers `write-setting.sh`/`write-requirement.sh`),
  from which `vendor.js`, `vendor.py`, `install.sh`,
  `install.ps1`, and `release.sh`'s CLI bundle all derive their file set;
  `tests/canonical/test-dashboard-manifest.sh` fails CI if the manifest drifts. Self-located from
  `$AID_CODE_HOME` (same rationale as `home.html`/the feature-001 writers).
- **No op-schema flag added.** An earlier draft declared an additive `cross_worktree` boolean so the
  dispatcher would skip a main-tree existence precheck; feature-001's Q5 re-open removed the need —
  its step-6 `resolve_work_dir` (WT-1) now resolves every pipeline-scoped op's target worktree-aware,
  so there is no precheck to skip and the flag is deleted. No envelope field, no `schema_version` bump
  (DM-1 stays 3, DM-2 stays 1) — nothing in the DM model changes for delete.
- **No golden-fixture regeneration** — delete adds no serialized field; the twin byte-parity suites
  (`dashboard/server/tests/test_server_node.mjs`, `test_server_py.py`) gain op-dispatch cases
  (403-gated, 404, 409-guard, 200-happy) applied identically to both twins, but no existing fixture
  bytes change.
- **No data migration** — nothing is rewritten; folders/worktrees are removed in place.

### UI Specs

Grounded in the existing `home.html` pipeline detail view. Pipeline-level ops belong on the
per-pipeline page (`#/work/<work_id>`), not the all-projects `index.html` grid, and not the
main-page work *card* (an `<a class="card card-link">`, `_renderWorkCard` 1476 — nesting a
destructive button inside a whole-card link invites accidental clicks). The user must first drill
into the specific pipeline, which is the correct intentionality bar for a destructive op.

- **Placement — a "Danger zone" block** appended to the work-overview body (`work-overview-body`,
  home.html 831/859), rendered by `renderWorkHeader` (1901) at the end of its build, visually set
  apart (a `--err`-bordered section, matching the existing `border-err` treatment used for Blocked
  works). It contains a single `btn-danger` **"Delete pipeline"** button.
- **Gating:** the entire Danger zone is rendered **only when `model.write_enabled === true`**
  (feature-001's signal). When the server is read-only (`--remote` without `--allow-writes`), no
  delete affordance exists at all — defense-in-depth with the server-side 403.
- **Confirmation modal (AC7 — strong gate):** clicking Delete opens a modal (a native `<dialog>`
  element, or a `role="dialog"` overlay — vanilla JS, no library, consistent with the current
  home.html) that:
  1. Names what will be removed using **only `work_id`** (the JSON envelope carries no `branch_label`
     — non-enumerable on the Node twin, omitted from `_ser_work` on the Python twin — so the modal
     cannot and does not read it): the work folder `.aid/works/<work_id>`, and — **if** that folder
     occupies a dedicated worktree — that worktree as well; a **shared** worktree that hosts other
     works is **not** removed (only the folder within it), and the git **branch is retained** in every
     case. The copy does **not** hardcode a worktree path (persistent worktrees live at arbitrary
     user-registered paths — see §Data Model) and does **not** imply a worktree is always removed; it
     states these outcomes conditionally, because the browser cannot know the on-disk topology — the
     writer is the sole authority on the folder-only vs folder+worktree classification (§Security
     Specs). Concretely: "This removes the work folder `.aid/works/<work_id>`. If this pipeline has its
     own worktree, that worktree is removed too; a worktree shared with other pipelines is kept. The
     git branch is not deleted."
  2. States the irreversibility in strong terms: **"This permanently deletes the pipeline. Any work
     not pushed to git will be lost and cannot be recovered."**
  3. Requires **type-to-confirm**: a text input; the destructive Confirm button stays `disabled`
     until the typed value === `work_id` (the GitHub "type the name to confirm" pattern — the
     strongest lightweight gate; defeats muscle-memory/double-click deletes). A Cancel button, `Esc`,
     and backdrop click dismiss with no side effect.
  4. Accessibility: focus moves into the modal on open and is trapped; the dialog has an
     `aria-label`/labelled heading; the Confirm button carries an explicit destructive label
     ("Delete work-NNN-…"); focus returns to the Delete button on cancel.
- **Action + re-render:** Confirm issues `fetch('/r/<id>/api/op', {method:'POST', body:{op:
  "pipeline.delete", target:{work_id}}})`. On **200**: close the modal, set `location.hash = ""`
  (main route), and call `doFetch()` (home.html 1033) for an immediate truthful re-fetch — the
  deleted pipeline is gone from the grid (AC2). On **4xx/5xx**: keep the modal open and show the
  server `error`/`detail` inline (e.g. 409 → "This pipeline is Running — Finish it before deleting.";
  404 → "Pipeline not found — it may already be gone."). This replaces the read-only "manual CLI
  steps, no write button" pattern (the analogue at index.html 921) with a real guarded action
  (NFR1).

### How the Acceptance Criteria are satisfied

- **AC-PD1 — delete performed from the dashboard; on-disk artifacts removed.** The Confirm action POSTs
  `pipeline.delete`; `delete-pipeline.sh` removes the work folder (and, for isolated works, the
  worktree) via `rm -rf` / `git worktree remove --force`. No hand-removal of folders/worktrees by the
  user; the whole operation is dashboard-driven.
- **AC2 — view re-renders; pipeline gone; matches disk, no drift.** On success the client re-fetches
  `/r/<id>/api/model`; `read_repo` re-enumerates worktree roots and no longer finds the removed
  (reconciled-winner) copy of `.aid/works/<work_id>`, so the pipeline is absent from the fresh model.
  The drift window collapses to one immediate round-trip; the branch is deliberately retained without
  reintroducing the pipeline (branches with no worktree contribute no filesystem `.aid/works/*`
  entry). **Edge case — same `work_id` in more than one worktree:** delete removes only the rendered
  reconciled winner (WT-1 symmetry, §API Contracts Algorithm step 5), so a shadowed copy in another
  worktree becomes the new reconcile winner and the pipeline re-surfaces on the next render — truthful
  to disk (a copy really does remain) and re-deletable. Surfaced as a candidate known-issue in the
  RETURN.
- **AC7 — explicit confirmation + removes folder + associated worktree.** The type-to-confirm modal
  (type the `work_id` to arm the destructive button) is the explicit confirmation; the writer's scope
  is exactly folder + associated worktree; and the Running / current-worktree guards (a /aid-specify
  safety measure, not a REQUIREMENTS clause) prevent two unsafe deletes. (AC4 reader-twin parity and AC8 write-gate are owned by
  feature-001 and preserved here: no parser change, one identical `OP_TABLE` row + one identical
  status-map row per twin.)
