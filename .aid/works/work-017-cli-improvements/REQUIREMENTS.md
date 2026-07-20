# Requirements

- **Name:** Interactive AID Dashboard
- **Description:** Turn the read-only AID dashboard into an interactive control surface for changing the information and state of projects, pipelines, and tasks.

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-16 | Initial interview started | /aid-describe |
| 2026-07-16 | Seeded Objective + Problem Statement from D1 opener answer | /aid-describe |
| 2026-07-16 | Scope set to Tier 2 (state transitions + scalar field edits) | /aid-describe |
| 2026-07-16 | Corrected + recorded entity hierarchy (Project→Pipeline→Delivery/Task) | /aid-describe |
| 2026-07-16 | Captured Project-level editable surface (FR-P1..P6); noted operation-action expansion | /aid-describe |
| 2026-07-16 | Placed Project interactions on index.html (Add/Remove) vs home.html (header/lists); CLI `aid projects add/remove`; header-panel redesign | /aid-describe |
| 2026-07-16 | Consistency review vs settings.yml + CLI: found aid projects/update already exist; flagged NFR2 reversal, --remote safety, work-018 overlap, external-sources/settings writer gaps | /aid-describe |
| 2026-07-16 | Resolved conflicts: read-only reversal = objective; --remote = container/VM single-user no-auth (writes OK); work-018 reconciliation deferred | /aid-describe |
| 2026-07-16 | Header panel edit set = lean (name, description, global minimum_grade); Project level complete | /aid-describe |
| 2026-07-16 | Isolated work onto worktree/branch work-017 | /aid-describe |
| 2026-07-16 | Pipeline level scoped to 3 ops only: Rename, Finish, Delete (FR-PL1..3); other lifecycle edits deferred | /aid-describe |
| 2026-07-16 | Rename resolved = display-title edit (**Name:**), non-destructive; Pipeline level complete | /aid-describe |
| 2026-07-16 | Delivery level = read-only (nothing editable) | /aid-describe |
| 2026-07-16 | Task level = Rename (display) + Notes + Stop/Resume running task (FR-T1..3); no free state override, no review/elapsed | /aid-describe |
| 2026-07-16 | Top-down entity walk complete; refreshed §4 In-Scope summary from per-level decisions | /aid-describe |
| 2026-07-16 | Priority (MoSCoW P1/P2/P3) + 8 Acceptance Criteria captured; all 10 sections Complete | /aid-describe |
| 2026-07-16 | KB hydration assessed — no new as-built facts (all reused from KB); planned change stays in REQUIREMENTS, KB untouched | /aid-describe |
| 2026-07-16 | Approval HELD at COMPLETION — reconcile 2 in-flight agents' (minor) changes before approving, per stakeholder | /aid-describe |
| 2026-07-17 | Reconciled work-018 (merged PR #147): confirmed `aid projects add/remove` signatures + remove-by-index + untrack-only; FR-P1/P2, OQ-P2, deps updated | /aid-describe |
| 2026-07-17 | Reconciled work-016 (merged PR #149): work folders now under `.aid/works/` container; merged master into work-017, migrated work folder, updated hierarchy + FR-PL3 paths | /aid-describe |
| 2026-07-17 | Both agents reconciled; hold cleared; re-presenting approval gate | /aid-describe |
| 2026-07-17 | Interview complete — approved | /aid-describe |
| 2026-07-17 | Define: 10 features decomposed (aid-architect), user-approved | /aid-define |
| 2026-07-17 | Cross-reference (aid-reviewer) graded E: fixed FR-P6/C1 factual errors, feature-004/005/007 SPECs; recorded Q2/Q3/Q4; Q1 (--remote) reopened with new evidence for user decision | /aid-define |
| 2026-07-17 | Q1 resolved (user): opt-in remote writes — loopback interactive, --remote read-only unless flag+ACL; applied to NFR2/§3/C3/AC8 + feature-001; re-verifying | /aid-define |
| 2026-07-17 | Cycle-2 fixes: closed `aid update <tool>` residuals (OQ-P3, §8 dep); added --allow-writes plumbing to §8; FR-P5 Q2 pointer | /aid-define |

## 1. Objective

Transform the AID dashboard from a read-only viewer into an interactive control
surface — one where a user can change the information and state of works (projects),
pipelines, and tasks directly from the rendered HTML, without leaving the dashboard to
edit state files or run skills by hand.

## 2. Problem Statement

The dashboard today is read-only. It visualizes work/pipeline/task state assembled from
the on-disk `STATE.md` files but offers no way to act on what it shows. To change any
state — advance a task, update a field, move a phase — the user must leave the dashboard
and either hand-edit state files or invoke an AID skill. This leaves a gap between
*seeing* the project state and *acting* on it, and makes the dashboard a passive report
rather than a working tool.

_(Term vocabulary captured from stakeholder: "make it alive", "interaction", "change the
information and state", "project / pipelines / tasks", "read-only".)_

## 3. Users & Stakeholders

- **Primary user:** a single developer running AID locally, operating their own
  project's pipeline and viewing its dashboard in a browser.
- **Access model:** local browser against the **loopback-bound** dashboard server
  (localhost only). No remote access, no multiple simultaneous human users, no
  authentication in scope.
- **Only other writer to coordinate with:** AID itself — agents/skills (e.g.
  `aid-execute`) that write task/delivery/work state during a running pipeline. This is
  the sole source of concurrent writes; there is no human-vs-human contention.

- Multi-user / shared / team-hosted dashboard instances.
- Authentication / authorization (not required — single-user trust model).

**Note on `--remote`:** `aid dashboard --remote` (live; tailscale `serve`) exists so the
dashboard can be reached when the CLI/dashboard runs inside a **container or VM**. It
exposes the dashboard to every device on the user's tailnet with no auth, so under
`--remote` the dashboard is **read-only by default**; writable interactions require an
explicit opt-in flag + a user-scoped tailnet ACL (see NFR2). Loopback stays fully
interactive (single trusted local user). No built-in auth is added.

## 4. Scope

### Target entity hierarchy (dashboard display model)

Confirmed against `dashboard/home.html` and `dashboard/reader/models.py`:

```
Home  (CLI home — all projects)
└── Project              — a repo/workspace with an .aid/  (project.name from settings.yml)
    └── Pipeline         — a work-NNN under .aid/works/;  path = Full | Lite  (pipeline.path)
        ├── Full path, WITH deliveries:  Delivery (delivery-NNN) → Task (task-NNN)
        └── Full path WITHOUT deliveries (flattened) OR Lite path:  Task (task-NNN) directly
```

Vocabulary note: in the dashboard, **"Pipeline" = a `work-NNN`** (the main grid is the
"Pipelines" section); **"Project" = the repo/workspace** above it. Editable interaction
is scoped to Project, Pipeline, Delivery, and Task levels. _Per work-016 (merged PR #149),
work folders live under the **`.aid/works/`** container (`.aid/works/work-NNN-{name}/`), not
directly under `.aid/`; the dashboard reader enumerates `.aid/works/*`. (`.aid/knowledge/`,
`.aid/connectors/`, and `settings.yml` are unchanged.)_

### In Scope

Interaction is defined **per level** in §5 (authoritative). Summary of decided scope:

- **Project** — edit name/description/grading; add/remove external sources & connectors;
  Add/Remove Project (via `aid projects`); Update Tools (via `aid update`). (§5.1)
- **Pipeline** — three operations only: **Rename** (display title), **Finish** (stop
  running work + mark concluded), **Delete** (destructive: folder + worktree). (§5.2)
- **Delivery** — **read-only** (no editable interactions). (§5.3)
- **Task** — **Rename** (display), edit **Notes**, **Stop/Resume** the running task. (§5.4)
- All state/field writes persist to disk (via `writeback-state.sh` for Pipeline/Task
  state; settings/CLI writers for Project) and the dashboard re-renders truthfully.

### Out of Scope

- **Creating** pipelines, deliveries, or tasks from the dashboard.
- **Structural edits/deletes of deliveries and tasks** (add/remove/reorder within a
  pipeline). _(Whole-pipeline **Rename / Finish / Delete** ARE in scope — see §5.2.)_
- Editing **free-text / prose content** — requirement text, SPEC prose, task
  descriptions, blueprint bodies.

_(Tier chosen by stakeholder: "State + field values" for the Pipeline/Delivery/Task
levels. **Refinement:** at the **Project** level the stakeholder additionally wants
structural add/remove of registries (external sources, connectors) and projects, plus an
operation to update tooling versions — see §5.1. So the "no structural change" rule is
scoped to pipelines/deliveries/tasks, not to Project-level registries/operations.)_

## 5. Functional Requirements

Organized by the entity hierarchy (top-down). Each interaction notes the write
path/mechanism it needs, because they differ sharply by level.

### 5.1 Project level

**UI placement (two surfaces):**

- **Main interface — `index.html`** (the all-projects "Projects" grid, `#repo-grid`):
  Add Project and Remove Project live here.
- **Project page — `home.html`** (a single project's view): the header panel
  (name/description/grading + KB button) and the external-sources and connectors lists
  live here.

**Main interface (`index.html`):**

- **FR-P1 — Add Project.** Opens a **folder-selection dialog**; passes the chosen folder
  to the CLI: `aid projects add [<path>]` (path defaults to cwd). _Confirmed against master
  (post-work-018):_ `add` **registers an existing folder for tracking only** — it does NOT
  scaffold `.aid/` or install tools. The folder is expected to already be an AID project.
- **FR-P2 — Remove Project.** Passes the project's folder to the CLI:
  `aid projects remove [<path>|<N>]`. _Confirmed against master (post-work-018):_ `remove`
  now accepts a **path OR a 1-based list index** (`<N>` from `aid projects list`) and is
  **untrack-only — "no files removed."** The dashboard uses the `<path>` form (unambiguous
  per card). **NB:** this is a *different* operation from FR-PL3 "Delete pipeline" — Remove
  Project only unregisters a whole project (files stay); Delete pipeline destroys one
  pipeline's work folder + worktree.

**Project page (`home.html`):**

- **FR-P3 — Header panel redesign.** The header is **currently only a clickable card
  linking to the KB**. It must be **completely redesigned** to (a) show and edit the
  project's **name** (`project.name`), **description** (`project.description`), and
  **grading** (`review.minimum_grade`, the global value only), and (b) keep a **button to
  open the KB**. _Mechanism (edits):_ non-interactive `settings.yml` writer (see OQ-P5),
  NOT `writeback-state.sh`. _Excluded (stay in `/aid-config`):_ `max_parallel_tasks`,
  `heartbeat_interval`, per-skill grade overrides, `project.type`._
- **FR-P4 — External sources list.** A separate list on the project page: view + add /
  remove entries (external-sources registry, `.aid/knowledge/external-sources.md`).
  _Mechanism:_ TBD (KB-doc edit path).
- **FR-P5 — Connectors list.** A separate list on the project page: view + add / remove
  connectors (`.aid/connectors/`). _Mechanism:_ existing `aid-set-connector` /
  `aid-unset-connector` skills. ⚠️ The **Add** path needs interactive elicitation the
  LLM-free dashboard server can't invoke (SEC-4) — see **Q2**; Remove is unaffected.

**Placement TBD:**

- **FR-P6 — Update Tools.** Update the installed host-tools' tooling versions.
  _Reality check (corrected by cross-reference):_ the real CLI is **`aid update`** (updates
  **all** installed tools; no per-tool selection) and **`aid update self`** (the CLI
  itself). ⚠️ There is **no `aid update <tool>` per-tool form** — `bin/aid` rejects a tool
  positional on `update`. So "Update Tools" is either (a) trigger `aid update` as-is (all
  tools, zero new CLI), or (b) build net-new per-tool selection. **See Q4 / OQ-P3.** UI home
  also undecided (per-project card on `index.html`, or `home.html`).

_Note: FR-P1/P2/P4/P5/P6 are **operation-triggering actions** (invoke a CLI/skill), a
broader capability than the state/field-edit tier established in §4._

**Consistency-review findings (2026-07-16):** Add/Remove Project, Update Tools, and
connectors all map to **existing** CLI/skills — the dashboard becomes a UI over working
commands (low-risk, consistent). Genuinely new plumbing is limited to external-sources
add/remove (FR-P4) and a non-interactive settings writer for FR-P3.

**Open questions for /aid-specify:**

- **OQ-P1 — Folder dialog from a browser.** A loopback web page cannot open a native OS
  folder picker directly (browser sandbox). Resolve mechanism: File System Access API,
  server-side dialog, or typed-path input.
- **OQ-P2 — CLI reconciliation.** `aid projects` shape **confirmed & incorporated**
  (work-018 merged, PR #147): `list` (numbered from 1), `add [<path>]`,
  `remove [<path>|<N>]`. Remaining: reconcile the legacy `aid add <tool>` /
  `aid remove --target <path>` naming with `aid projects` (CLI cleanup theme).
- **OQ-P3 / Q4 — Update Tools scope + placement.** Real CLI is `aid update` (all installed
  tools) / `aid update self` (the CLI) — there is **no `aid update <tool>` form**. Decide:
  (a) trigger `aid update` as-is vs. (b) build net-new per-tool selection; whether to expose
  `aid update self`; per-project vs. global; and the UI home.
- **OQ-P4 — External-sources writer (new).** `external-sources.md` has no dedicated
  add/remove path today (discovery/Q&A only). Needs new plumbing.
- **OQ-P5 — Non-interactive settings writer.** `/aid-config` is interactive; editing
  name/description/grade from the dashboard needs a scriptable settings-write path.

### 5.2 Pipeline level

The Pipeline level is deliberately **rigid** — only three operations, no general lifecycle
editing. (Explicitly **out for now:** pause/resume, block/unblock, `phase` edits,
`active_skill` edits, `user_approved`, per-work `minimum_grade`, `ticket_ref`.)

- **FR-PL1 — Rename pipeline.** Change the pipeline's **display title** so it's easier to
  identify — edits `REQUIREMENTS.md **Name:**`; the dashboard shows that title. The work
  folder (`work-NNN-{name}`), its branch, and its worktree are **untouched**
  (non-destructive). _Note:_ the dashboard currently derives a pipeline's label from the
  folder slug (`WorkModel.name`); it must render the `**Name:**` title instead (falling
  back to the slug when the title is empty).
- **FR-PL2 — Finish pipeline.** Two effects: (a) **stop any executing task or skill**, and
  (b) **mark the pipeline concluded** (`lifecycle = Completed`). _OQ-PL2:_ tasks/skills run
  inside a separate agent session the server can't kill directly — the "stop" needs a
  mechanism (cooperative stop-signal the running agent polls — possibly via the existing
  heartbeat channel — vs. state-only marking). To resolve in `/aid-specify`.
- **FR-PL3 — Delete pipeline (destructive).** Completely removes: the work folder
  (`.aid/works/work-NNN-*`), **and** any associated worktree (`.claude/worktrees/work-NNN-*`
  via `git worktree remove`), and (confirm scope, OQ-PL3) its git branch. **Any pipeline
  information not pushed to git is permanently lost.** Requires a strong confirmation gate.

**Open questions for /aid-specify:**

- **OQ-PL2 — Finish "stop" mechanism:** how to actually halt an executing task/skill in a
  separate agent session (cooperative stop-signal vs. state-only).
- **OQ-PL3 — Delete scope + guard:** folder + worktree + branch? Confirmation UX for an
  irreversible, loses-unpushed-work operation.

### 5.3 Delivery level

**No editable interactions — Deliveries stay read-only.** `delivery_state`, the gate
(`gate_tier`/`gate_grade`), and Cross-phase Q&A are agent-owned bookkeeping; the dashboard
does not override them. (Consistent with the deliberately rigid Pipeline level.) Deliveries
appear only in full-path pipelines that have them; flattened/Lite pipelines have none.

### 5.4 Task level

- **FR-T1 — Rename task (display reference).** Change the task's shown label — like FR-PL1,
  **display-only and non-destructive**. _Target TBD (OQ-T1):_ the task title lives in the
  task file's `# task-NNN: <title>` line (source of `short_name`), but the task `DETAIL.md`
  is nominally immutable — so this may need a new **mutable display-name cell** (task STATE
  frontmatter / flattened `Tasks lifecycle` row) rather than editing `DETAIL.md`.
- **FR-T2 — Edit notes.** Edit the task's `notes` field via `writeback-state.sh`.
- **FR-T3 — Stop / Resume the running task.** Pause and resume execution of the **currently
  running** task **only**. Explicitly **cannot**: rerun a completed task (Done/Failed/
  Canceled), or start a not-yet-executed task (Pending). The Stop/Resume control is offered
  only while the task is actively executing. _OQ-T2 (shared with OQ-PL2):_ the server can't
  halt a separate agent session directly — needs a cooperative stop/resume signal; and a
  "stopped" task has no `Paused` enum value (stays `In Progress`-paused, or `Blocked`?) —
  to resolve in `/aid-specify`.

**Out for now:** free `state` override (beyond stop/resume), `review`, `elapsed`,
`ticket_ref`.

**Open questions for /aid-specify:**

- **OQ-T1 — Task rename target:** mutable display-name cell vs. editing the (immutable)
  `DETAIL.md` title line.
- **OQ-T2 — Stop/Resume mechanism + "stopped" state representation** (shared with OQ-PL2).

## 6. Non-Functional Requirements

- **NFR1 — Replace the read-only design (intended).** The dashboard was read-only *by
  design* (`index.html`: "no write button, NFR2"; release ledger: "a local, read-only
  dashboard"). **Making it interactive is the objective of this work** — the old
  "show manual CLI steps instead of a button" UX patterns are deliberately replaced with
  real action controls. Recorded so the intent change is explicit.
- **NFR2 — Trust model: loopback single-user; `--remote` writes are opt-in (resolved, Q1).**
  On **loopback** (default) the dashboard is fully interactive under the single-trusted-local-user
  model (no auth). `aid dashboard --remote` is a **live** capability (tailscale `serve`) that
  by default exposes the dashboard to **every device on the user's tailnet** with no auth —
  so under `--remote` the dashboard is **read-only by default**. Writable interactions over
  `--remote` require an **explicit opt-in** (e.g. `--remote --allow-writes`) **and** a
  documented, user-scoped tailnet ACL; no built-in auth is added — the opt-in flag + ACL is
  the gate. (This corrects the earlier "single user under `--remote`" assumption, which the
  code contradicts.)
- **NFR3 — Truthful re-render.** After any write/operation, the dashboard reflects the new
  on-disk state so the view never drifts from disk.

## 7. Constraints

- **C1 — Single-writer invariant preserved (STATE writes).** All dashboard-initiated
  **Pipeline/Task STATE** writes MUST go through the existing single writer
  (`writeback-state.sh`); the dashboard/server never hand-edits `STATE.md` directly, and a
  dashboard STATE edit must be indistinguishable from an agent edit. _(Scope: this governs
  STATE.md only. Project-level edits use their own writers — the settings writer, the `aid`
  CLI, connector skills — and the FR-PL1 rename needs a separate REQUIREMENTS.md writer;
  none of those are `writeback-state.sh`. See §5.1 and §8.)_
- **C2 — DERIVED sections stay read-only.** The DERIVED union views (Tasks State,
  Plan/Deliveries, Delivery Gates, Cross-phase Q&A, Calibration Log, Dispatches) are
  assembled at read time and are never written directly — dashboard edits target the
  AUTHORED source cell / frontmatter of the owning unit, not the derived view.
- **C3 — No new network surface; writes gated on `--remote`.** Adding write capability
  introduces **no new network surface** beyond what exists today: loopback by default, plus
  the existing `aid dashboard --remote` (tailscale `serve` — exposes to the tailnet). Under
  `--remote`, writes are OFF unless explicitly opted in (flag + tailnet ACL); see NFR2.

## 8. Assumptions & Dependencies

**Dependencies (existing surfaces this work builds on):**

- `aid projects` CLI — for FR-P1/P2. **work-018 merged (PR #147):** final shape is `list`
  (numbered), `add [<path>]`, `remove [<path>|<N>]` (untrack-only, no files removed).
- `aid update` (all installed tools) / `aid update self` CLI — for FR-P6 (no per-tool form).
- `aid-set-connector` / `aid-unset-connector` skills + connector index regeneration — FR-P5.
- `writeback-state.sh` (single writer) — for all Pipeline/Delivery/Task state writes (C1).
- The dashboard server (`dashboard/server/`) and reader twins (Python + `reader.mjs`) —
  which must stay in lockstep (byte-parity discipline).

**New plumbing this work must introduce:**

- A non-interactive **settings writer** for `project.name` / `description` /
  `review.minimum_grade` (FR-P3) — `/aid-config` is interactive today.
- A non-interactive **REQUIREMENTS.md field writer** for the pipeline display title
  (`**Name:**`, FR-PL1) — none exists; `writeback-state.sh` is STATE.md-only (see Q3).
- An **external-sources add/remove** path (FR-P4) — none exists today.
- A **`--remote` write opt-in gate** — the `--remote --allow-writes` flag (does NOT exist
  today) plus the read-only-by-default-under-`--remote` enforcement (NFR2 / C3 / AC8).
- Server-side **write/operation endpoints** invoking the above (the server is read-only today).

**Assumptions:**

- The Home multi-project **registry already exists** (`index.html` `#repo-grid` via
  `/api/home`); Add/Remove Project operate on it via the CLI.

## 9. Acceptance Criteria

1. **AC1 — P1 works end-to-end.** Each P1 interaction (header name/description/grading
   edit; Add/Remove Project; Update Tools; Task Notes; Pipeline & Task Rename) performs its
   change from the dashboard and it persists to disk.
2. **AC2 — Truthful re-render.** After any write/operation, the dashboard reflects the new
   on-disk state (no drift).
3. **AC3 — Single-writer intact.** All Pipeline/Task state writes go through
   `writeback-state.sh`; no DERIVED section is ever hand-written.
4. **AC4 — Reader twins in parity.** The Python reader and `reader.mjs` stay byte-consistent
   after changes.
5. **AC5 — Rename is display-only.** Pipeline/task rename changes only the shown label;
   folder, branch, worktree (pipeline) and `DETAIL`/structure (task) are untouched.
6. **AC6 — Stop/Resume gating.** The control appears only for the *currently running* task;
   completed/pending tasks offer no rerun/start.
7. **AC7 — Delete is guarded.** Pipeline Delete requires explicit confirmation and removes
   the work folder + associated worktree.
8. **AC8 — Trust model enforced.** On loopback, writes/operations work fully. Under
   `--remote`, the dashboard is read-only **unless** the explicit write opt-in is set; when
   opted in (flag + tailnet ACL), writes work. No built-in auth is introduced; the loopback
   default and the `--remote` opt-in gate are the enforcement points.

## 10. Priority

MoSCoW tiering (accepted by stakeholder 2026-07-16):

**P1 — Must (foundation + high-value, low-risk):**
- Write infrastructure — server write endpoints + `writeback-state.sh` wiring +
  non-interactive settings writer (enables everything else).
- Project header redesign — edit name/description/grading + KB button (FR-P3).
- Add/Remove Project (FR-P1/P2) & Update Tools (FR-P6) — wire to existing `aid projects` /
  `aid update`.
- Task Notes (FR-T2); Pipeline & Task Rename, display-only (FR-PL1, FR-T1).

**P2 — Should:**
- Connectors list (FR-P5).
- Pipeline Finish (FR-PL2) + Task Stop/Resume (FR-T3) — depend on the cooperative stop
  mechanism (OQ-PL2/OQ-T2).
- Pipeline Delete (FR-PL3) — destructive; confirmation guard.
- External-sources list (FR-P4) — **promoted from Could → Should (2026-07-17, user)**; shares
  the list-CRUD UI + discover-authoritative/dashboard-atomic ownership model with connectors
  (FR-P5), so it ships alongside them in the List-Management delivery.

**P3 — Could (later):**
- _(none — external-sources promoted to Should.)_
