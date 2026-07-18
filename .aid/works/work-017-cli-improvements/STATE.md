---
pipeline:
  path: full
  initiator: aid-describe
started: "2026-07-16"
minimum_grade: "A+"
user_approved: yes
lifecycle: Paused-Awaiting-Input
phase: Detail
active_skill: none
updated: '2026-07-18T05:45:45Z'
pause_reason: 'DETAIL DONE (A+, 0 issues). 33 tasks across 5 deliveries fully detailed; execution graphs + wave-maps in PLAN.md; all deliveries Specified. RESUME = run /aid-execute work-017-cli-improvements to begin delivery-001. Pending (orchestrator, pre-delivery-003-execute, NOT a task): apply feature-007/010 SPEC ownership prose touch (atomic single-entry writer + discover-authoritative/dashboard-atomic narrative; clear feature-010 KI-005-as-blocker).'
block_reason: --
block_artifact: --
---

# Work State -- work-017-cli-improvements

[!NOTE]
This is the WORK-LEVEL STATE.md template. It is divided into three zones:
  FRONTMATTER (single-writer, machine-parsed scalars) -- the YAML block above: pipeline
    identity, work-level lifecycle/phase/approval scalars, and (for flattened single-delivery
    works only) the delivery lifecycle/gate scalars. Written ONLY by `writeback-state.sh`
    (surgical YAML-block rewrite; the markdown body is never touched by that write).
  AUTHORED (single-writer, markdown body) -- Interview State, Lifecycle History,
    Deploy State, the narrative remainder of Delivery Lifecycle (incl. its Tasks lifecycle
    subsection) and Delivery Gate (Updated/Block Reason/Block Artifact/Issue List -- the
    values that don't fit a flat frontmatter scalar).
  DERIVED (read-only, assembled at read time) -- Features State, Plan/Deliveries, Tasks State,
    Delivery Gates, Cross-phase Q&A, Calibration Log, Dispatches.
The DERIVED sections are NEVER written directly; they are union views over the per-delivery and
per-task STATE.md files. Agents that write state must target the per-unit STATE.md files instead.
Inferred values (`number` from the folder name, `branch` from the git worktree,
`title`/`description`/`objective` from REQUIREMENTS/SPEC content files) and derived values
(counts, readiness/execution %, `source_mode`) are NEVER authored here -- computed at read time.

---

## Pipeline State

> Lifecycle enum:    Running | Paused-Awaiting-Input | Blocked | Completed | Canceled
> Phase enum:        Describe | Define | Specify | Plan | Detail | Execute | Deploy
> Active Skill enum: aid-{skill} | none

---

## Interview State

<!-- AUTHORED -- updated by `aid-describe` as each section is completed. -->

**State:** Approved  **Grade:** N/A (user-approved; describe has no reviewer gate)

| # | Section | State | Last Updated |
|---|---------|-------|--------------|
| 1 | Objective | Complete | 2026-07-16 |
| 2 | Problem Statement | Complete | 2026-07-16 |
| 3 | Users & Stakeholders | Complete | 2026-07-16 |
| 4 | Scope | Complete | 2026-07-16 |
| 5 | Functional Requirements | Complete | 2026-07-16 |
| 6 | Non-Functional Requirements | Complete | 2026-07-16 |
| 7 | Constraints | Complete | 2026-07-16 |
| 8 | Assumptions & Dependencies | Complete | 2026-07-16 |
| 9 | Acceptance Criteria | Complete | 2026-07-16 |
| 10 | Priority | Complete | 2026-07-16 |

**Cross-Reference:** Complete — **Grade A+** (2026-07-17). 7 findings resolved across 3
review cycles (aid-reviewer); no new defects. Q2/Q3/Q4 remain Pending Q&A, routed to
`/aid-specify` as design decisions.

---

## Lifecycle History

<!-- AUTHORED -- append-only audit trail of phase transitions and gate approvals.
     Newest entry last (append to bottom). -->

| Date | Phase Transition / Gate | Grade | Notes |
|------|------------------------|-------|-------|
| 2026-07-16 | Work created | -- | Initial scaffold by aid-describe (FIRST-RUN) |
| 2026-07-17 | Describe complete — requirements approved | -- | User-approved; reconciled work-018 + work-016; paused awaiting /aid-define |
| 2026-07-17 | Define: feature decomposition | -- | 10 features created (feature-001..010); approved by user |
| 2026-07-17 | Define: cross-reference validated | A+ | 7 findings resolved (3 cycles); cleared to DONE |
| 2026-07-17 | Specify: feature-001 Ready | A+ | write-infra foundation spec'd + graded A+ (3 review cycles); checkpoint before cascading |
| 2026-07-17 | Specify cascade (workflow, 58 agents): features 002-010 | mixed | 7 A+ (002,003,005,006,007,008,010); 004 (D) + 009 (D+) hit 3-round cap — re-run pending |
| 2026-07-17 | Specify: feature-001 re-opened for worktree-aware resolution (Q5), re-graded | A+ | resolve_work_dir + WT-1; survived reboot; duplicate Q5→Q6 fixed | /aid-specify |
| 2026-07-17 | Specify Phase 2 (workflow, 17 agents): 004/005/006/008/009 re-checked/cleared | A+ | ALL 10 feature specs now A+; KI-006/007 registered; Q6 (external-sources ownership) pending before feature-010 EXECUTE | /aid-specify |
| 2026-07-18 | Plan: 5 deliverables sequenced + graded | A+ | Q6/Q7 resolved (discover-authoritative + dashboard-atomic; external-sources→Should); 007+010 merged (List Management); feature-001 re-opened for status_map/OP-SM hook + re-graded A+; Q2/Q3 synced | /aid-plan |
| 2026-07-18 | Detail: 33 tasks across 5 deliveries + execution graphs; whole-list reviewed | A+ | 33 task DETAIL+STATE written (workflow, per-delivery A+); execution graphs + wave-maps added to PLAN.md (totality verified 33/33); whole-list re-review cleared 8 findings to A+ (0 issues); BLUEPRINT Tasks tables filled; deliveries advanced Pending-Spec→Specified; DESIGN-skip decision documented (Q8) | /aid-detail |

---

## Deploy State

<!-- AUTHORED -- written ONLY by `aid-deploy`. One row per delivery. -->

| Delivery | State | PR | KB Updated | Tag | Notes |
|----------|-------|----|-----------|-----|-------|
| _none yet_ | | | | | |

---

<!-- ============================================================
     DERIVED / READ-ONLY VIEWS
     Assembled at READ TIME from per-delivery and per-task STATE.md files.
     ============================================================ -->

## Features State

<!-- DERIVED -- read-only view assembled from features/{feature}/SPEC.md progress. -->

| # | Feature | Spec State | Spec Grade | Q&A Count | Notes |
|---|---------|------------|------------|-----------|-------|
| 1 | feature-001-write-infrastructure | Ready | A+ | Q1(ans) Q3(ans) Q5(ans) | Foundation A+ (resolve_work_dir/WT-1 + per-op status_map/OP-SM hook; re-graded after plan-review re-open) |
| 2 | feature-002-project-header-edit | Ready | A+ | -- | spec A+ (1 cycle) |
| 3 | feature-003-project-registry | Ready | A+ | OQ-P1(ans) OQ-P2(ans) | spec A+ (2 cycles) |
| 4 | feature-004-update-tools | Ready | A+ | Q4(ans) | spec A+ (Phase 2; self-update hazard documented → KI-006) |
| 5 | feature-005-display-rename | Ready | A+ | Q3(ans) OQ-T1(ans) | spec A+; worktree-consumption re-verified (Phase 2) |
| 6 | feature-006-task-notes | Ready | A+ | -- | spec A+; worktree-consumption fixed (Phase 2) |
| 7 | feature-007-connectors-list | Ready | A+ | Q2(ans) | spec A+ |
| 8 | feature-008-execution-control | Ready | A+ | OQ-PL2(ans) OQ-T2(ans) | spec A+; worktree signal-target re-verified (Phase 2); KI-007 |
| 9 | feature-009-pipeline-delete | Ready | A+ | OQ-PL3(ans) | spec A+ (Phase 2; consumes resolve_work_dir; stale cross_worktree flag removed) |
| 10 | feature-010-external-sources-list | Ready | A+ | OQ-P4(ans) | spec A+ (new external-sources writer) |

## Plan / Deliveries

<!-- DERIVED -- read-only view assembled from delivery-NNN/STATE.md lifecycle fields. -->

| Delivery | State | Tasks | Notes |
|----------|-------|-------|-------|
| _none yet_ | | | |

## Tasks State

<!-- DERIVED -- read-only view assembled at read time from per-task STATE.md files.
     State enum (closed): Pending | In Progress | In Review | Blocked | Done | Failed | Canceled -->

| # | Task | Type | Wave | State | Review | Elapsed | Notes |
|---|------|------|------|-------|--------|---------|-------|
| _none yet_ | | | | | | | |

## Delivery Gates

<!-- DERIVED -- read-only union of each delivery-NNN/STATE.md ## Delivery Gate section. -->

_None yet. Each delivery-NNN/STATE.md carries its own gate block._

## Cross-phase Q&A

<!-- DERIVED -- read-only union of delivery-gate Q&A plus work-owner-authored entries.
     WORK-OWNER-AUTHORED entries may appear below this block (single writer, work active branch). -->

### Q1

- **Category:** Architecture
- **Impact:** High
- **Status:** Answered
- **Context:** Surfaced by /aid-define FEATURE-DECOMPOSITION (aid-architect). REQUIREMENTS §3 / NFR2 / AC8 assume dashboard writes and operations function under `aid dashboard --remote` (container/VM, single-user, no auth). But `.aid/knowledge/infrastructure.md` records `aid dashboard --remote` as a **clear-fail stub (exit 10)** — i.e. it may not be a live capability today. This conflict MUST be reconciled. Scoped to feature-001-write-infrastructure; gates AC8.
- **Suggested:** In /aid-specify feature-001, confirm whether `--remote` is live or a stub. If a stub, decide: (a) this work implements `--remote` write support, or (b) NFR2/AC8 are re-scoped to loopback-only for now and `--remote` remains out. Do not implement AC8 against `--remote` until resolved.
- **Update (2026-07-17, cross-reference):** Premise flipped. `bin/aid` shows `--remote` is **live** (tailscale `serve`, commit `bd9e4a04`, 2026-06-11) — NOT the stub `infrastructure.md` records (that KB doc is stale). Critically, `--remote` by default exposes the dashboard to **every device on the user's tailnet**, not a single owner, and adds **no auth**. So NFR2's "single user, no authentication required" is factually wrong for `--remote`, and a *writable* dashboard over `--remote` is a security exposure. **Awaiting user decision** (see cross-reference presentation).
- **Answer (2026-07-17, user):** **Opt-in remote writes.** Loopback = full interactivity (single trusted local user). Under `--remote` the dashboard is **read-only by default**; writable interactions require an explicit opt-in (e.g. `--remote --allow-writes`) plus a documented, user-scoped tailnet ACL. No built-in auth is added — the opt-in flag + ACL is the gate.
- **Applied to:** REQUIREMENTS.md §3, NFR2, C3, AC8; `features/feature-001-write-infrastructure/SPEC.md`.

### Q2

- **Category:** Architecture
- **Impact:** High
- **Status:** Answered
- **Context:** Surfaced by /aid-define cross-reference (aid-reviewer). FR-P5 / feature-007's Add-Connector path requires `aid-set-connector`'s `AskUserQuestion` interactive elicitation, which the LLM-free dashboard server cannot invoke (`integration-map.md` SEC-4: "no agent/LLM import"). The Remove half (`aid-unset-connector`, Read/Bash-only) is unaffected.
- **Suggested:** In /aid-specify feature-007, decide: (a) a native dashboard form calling `connector-registry.sh` / `connector-secret.sh` directly (bypassing the skill), (b) hand Add-Connector to an agent session rather than a same-page action, or (c) revisit SEC-4.
- **Answer (2026-07-17, /aid-specify feature-007):** Option (a), refined — **native dashboard forms → a new non-interactive `write-connector.sh` writer** (+ `INDEX.md` regen); the server never invokes the agent skills (SEC-4 held). The secret VALUE is captured out-of-band via the existing `connector-secret.sh` path; the dashboard writes only the descriptor + `secret_reference` form. (See also Q7: discover-authoritative + dashboard-atomic ownership.)
- **Applied to:** `features/feature-007-connectors-list/SPEC.md`.

### Q3

- **Category:** Architecture / Scope
- **Impact:** High
- **Status:** Answered
- **Context:** Surfaced by /aid-define cross-reference. FR-PL1 prescribes writing `REQUIREMENTS.md **Name:**`, but no writer exists (`writeback-state.sh` is STATE.md-only) and §8 "New plumbing" omits it; feature-005 wrongly called it "unblocked."
- **Suggested:** In /aid-specify feature-001/005, either design a new non-interactive REQUIREMENTS.md-field writer (parallel to the FR-P3 settings writer) or retarget FR-PL1 to an already-writable cell. Update §8 either way.
- **Answer (2026-07-17, /aid-specify feature-001):** **Build a writer, not retarget** — a new non-interactive `write-requirement.sh` (surgical single-line rewrite of the `- **Name:**`/`- **Description:**` bullet the reader parses into `WorkModel.title`), owned by feature-001. Retargeting to a STATE.md frontmatter cell was rejected (no `title` key; template forbids authoring identity fields there). §8 "New plumbing" lists it; feature-005 consumes it via the pre-seeded `pipeline.rename` OP_TABLE row.
- **Applied to:** `features/feature-001-write-infrastructure/SPEC.md` (writer), `features/feature-005-display-rename/SPEC.md` (consumer).

### Q4

- **Category:** Requirements accuracy / Scope
- **Impact:** Medium
- **Status:** Answered
- **Context:** Surfaced by /aid-define cross-reference. FR-P6 / OQ-P3 assume a nonexistent `aid update <tool>` form; only `aid update` (all installed tools) and `aid update self` (the CLI) exist.
- **Suggested:** In /aid-specify feature-004, decide whether Update Tools means (a) trigger `aid update` as-is (all tools, zero new CLI) or (b) build per-tool selection (net-new CLI + plumbing). Correct FR-P6/OQ-P3 wording either way.
- **Answer (2026-07-17, /aid-specify feature-004):** (a) **trigger `aid update` as-is** (all installed tools; zero new CLI); option (b) per-tool selection rejected (no `aid update <tool>` form exists; §10 P1 scopes FR-P6 as "wire to existing `aid update`"). **`aid update self` is also exposed** as a separate global "Update CLI" control. Both controls placed on `index.html` (the only surface that renders the version effect). FR-P6/OQ-P3 wording already corrected to the real verbs.
- **Applied to:** REQUIREMENTS.md §5.1 FR-P6 + OQ-P3; `features/feature-004-update-tools/SPEC.md`.

### Q5

- **Category:** Architecture
- **Impact:** High
- **Status:** Answered
- **Context:** Surfaced by /aid-specify feature-009 review (aid-reviewer). The dashboard write ops assume a pipeline lives in the served tree's `.aid/works/<work>/`. A **worktree-isolated** pipeline (the exact topology work-017 itself uses) lives under `.claude/worktrees/<wt>/.aid/works/<work>/`, so every pipeline/task-scoped write op (features 001/005/006/008/009) would 404 for it. Verified against the reader/locator code.
- **Answer (2026-07-17, user):** **Re-open feature-001 (foundation) NOW** to make work-path resolution **worktree-aware** — the write ops must resolve a pipeline's ACTUAL on-disk root (the same location the reader enumerated it from), not assume `<servedTree>/.aid/works/`. Re-grade feature-001, then re-check the work-scoped consumers (005/006/008/009). Project/repo/home-scoped features (002/003/004/007/010) are unaffected.
- **Applied to:** `features/feature-001-write-infrastructure/SPEC.md` (re-opened); re-check on 005/006/008/009.

### Q6

- **Category:** Architecture / Data ownership
- **Impact:** High
- **Status:** Answered
- **Context:** Surfaced by /aid-specify feature-010 (external-sources dashboard writer). feature-010's OQ-P4 resolution makes the dashboard a **second writer** of `.aid/knowledge/external-sources.md`'s frontmatter `sources:` list (via new `write-external-source.sh`), but `aid-discover`'s `state-elicit.md` documents Scout as the file's single writer (`canonical/skills/aid-discover/references/state-elicit.md:119`: "Scout remains its single writer") and states that on an ELICIT E1 path-set change, "Scout fully rewrites the doc (including frontmatter) on its next pass regardless" (same file, line 115). This is a genuine silent-data-loss path: a dashboard-added `sources:` entry survives the immediate dashboard round-trip (satisfying feature-010's AC1/AC2 within that round-trip) but can be wholesale-overwritten by a later discovery GENERATE pass that has no knowledge of it. feature-010's SPEC (`§Migration / New Plumbing`) flags this as "must be reconciled with a human before build" but the conflict was not registered as a Cross-phase Q&A item, so it risks being lost before feature-010 reaches PLAN/EXECUTE.
- **Suggested:** Decide the ownership model before feature-010 is built: (a) make Scout's rewrite merge/preserve dashboard-managed `sources:` entries rather than replace outright, (b) mark dashboard-added entries so Scout retains them across a rewrite, or (c) accept the loss and re-document `external-sources.md` as discovery-owned with dashboard edits declared explicitly transient (softening feature-010's AC1 wording accordingly). Update `state-elicit.md`'s "Scout remains its single writer" language to reflect whichever model is chosen.
- **Answer (2026-07-17, user):** **Discovery-owned; Scout is the AUTHORITATIVE writer** (full authority to overwrite/update, including a wholesale rewrite, on any run). The **dashboard is a subordinate maintainer** making **atomic, surgical single-entry edits** (add/remove one `sources:` entry via `write-external-source.sh`; never a whole-file rewrite, so it cannot corrupt Scout's content/structure). A dashboard-added entry persists between Scout passes but Scout MAY drop it on its next authoritative run — accepted (Scout wins). No `/aid-discover` behavior change (Scout stays authoritative) → **feature-010 UNBLOCKED for EXECUTE**.
- **Applied to:** feature-010 SPEC (`write-external-source.sh` = atomic single-entry; AC1 → "persists until next discovery pass"; document the Scout-authoritative + dashboard-atomic-subordinate model); KI-005 (resolved); `state-elicit.md` "single writer" → "authoritative writer; dashboard makes subordinate atomic edits" (doc follow-up, post-ship KB-DELTA).

### Q7

- **Category:** Architecture / Data ownership
- **Impact:** Medium
- **Status:** Answered
- **Context:** Raised by the user during /aid-plan, extending the Q6 model to connectors. `/aid-discover` ELICIT also catalogues connectors (per CLAUDE.md "Connectors are catalogued via aid-discover (ELICIT)"), so feature-007's dashboard connector list is NOT the sole writer of `.aid/connectors/` — discover defines them too. Same dual-writer shape as Q6/external-sources.
- **Answer (2026-07-17, user):** **Same ownership model as Q6.** `/aid-discover` (ELICIT) is the **AUTHORITATIVE** definer of connectors — whatever discover defines wins, and it may overwrite/update on its runs. The **dashboard is a subordinate maintainer** doing **atomic single-entry edits** to the connector list (add/remove one connector via `write-connector.sh` + `INDEX.md` regen; never a wholesale rewrite). Discover may redefine/overwrite dashboard-added connectors on a later ELICIT — accepted. No `/aid-discover` behavior change.
- **Applied to:** feature-007 SPEC (`write-connector.sh` = atomic single-entry; document discover-authoritative + dashboard-atomic-subordinate ownership; align AC wording to "persists until next discovery ELICIT"); reinforces the delivery-003 List-Management grouping (007+010 now share UI AND ownership model). Doc follow-up (post-ship): note the discover/dashboard connector co-ownership wherever the connector registry's writer is documented.

### Q8

- **Category:** Process / Task typing
- **Impact:** Low
- **Status:** Answered
- **Context:** Surfaced by /aid-detail whole-list review. `task-decomposition.md` Type Detection Rule #2 ("UI Specs section in SPEC.md -> DESIGN task before IMPLEMENT") would normally emit a standalone DESIGN task for each of the 9 features whose SPEC Applicable-Sections table marks "UI Specs: Present" (all except feature-001). The approved 33-task breakdown contains no DESIGN-typed task; the reviewer flagged the absence as an undocumented decision (LOW).
- **Answer (2026-07-18, detail phase — orchestrator decision, ratified by prior user approval of the 33-task breakdown):** **No standalone DESIGN tasks; UI design is folded into the owning IMPLEMENT task.** Rationale: each feature SPEC's own "UI Specs" section is already element-/class-level prescriptive (it names the concrete DOM structure, controls, panels, and interaction the IMPLEMENT task realizes), so it substitutes for the DESIGN deliverable — there is no open design space left to explore before implementation. Emitting separate DESIGN tasks would produce empty restatement of the SPECs and contradict the task breakdown the user already approved. This is the "task explicitly overrides" escape in `task-decomposition.md` applied at the delivery level.
- **Applied to:** All 5 deliveries' IMPLEMENT tasks (UI work — home.html/index.html panels, modals, card-actions — lives inside the owning IMPLEMENT task, not a separate DESIGN task); the PLAN.md Execution Graphs (no DESIGN wave); this Q&A entry is the documented decision record the reviewer asked for.

## Calibration Log

<!-- DERIVED -- read-only union of per-task ## Dispatch Log entries. -->

| Date | Agent | Task / Cycle | ETA Band | Actual | Notes |
|------|-------|-------------|----------|--------|-------|

## Dispatches

<!-- DERIVED -- read-only union of per-task dispatch logs. -->

_None yet. Delivery task dispatch logs live in delivery-NNN/tasks/task-NNN/STATE.md._
