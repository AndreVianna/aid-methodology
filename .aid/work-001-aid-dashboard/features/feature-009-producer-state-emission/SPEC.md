# Producer State Emission (Close the Producer Loop — Dashboard Renders REAL Data)

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-11 | Feature created from REQUIREMENTS.md §5 FR19–FR26 + §7 C5; closes the consumer-first producer gap surfaced in delivery-002 re-gate | /aid-interview |
| 2026-06-11 | Technical Specification authored: canonical producer formats (Name/Description header, task short-name, lane-from-PLAN), reader+front-end reconciliation, fixture-from-real + contract test, work-001 migration, dogfood render | /aid-specify |

## Source

- REQUIREMENTS.md §5 FR19 (producer emission: work Name + Description)
- REQUIREMENTS.md §5 FR20 (producer emission: task short-name)
- REQUIREMENTS.md §5 FR21 (single phase source = `## Pipeline Status`; bootstrap handling)
- REQUIREMENTS.md §5 FR22 (lane source = PLAN.md `## Execution Graph` — decision B)
- REQUIREMENTS.md §5 FR23 (consumer reconciliation: reader + front-end to real canonical formats; fixture-from-real + contract test)
- REQUIREMENTS.md §5 FR24 (dogfood render of producers via FULL `run_generator.py`)
- REQUIREMENTS.md §5 FR25 (graceful degradation for partial / legacy works)
- REQUIREMENTS.md §5 FR26 (migrate work-001 to the canonical schema — the bootstrap)
- REQUIREMENTS.md §7 C5 (producer changes dogfood-rendered; behavior-preserving; reader stays no-LLM/read-only), C4 (behavior preservation), §6 NFR2/NFR7
- Consumes feature-001 (`## Pipeline Status` typed block), feature-002 (reader), feature-003 (front-end)

## Description

Features 001–008 built the dashboard **consumer-first** — the reader (feature-002) and front-end
(feature-003) were written against an **invented PT-1 fixture** whose formats (a
`delivery-NNN-wave-M` lane column, a clean Name/Description, a markup-free Objective) do **not exist**
in real AID producer output. Pointed at the real work-001 repo the dashboard breaks: the work title
falls back to the raw `work_id`, the description leaks a `> _Status: Complete — approved._`
blockquote, every task lands in **"Delivery #0"**, and the phase rail can show **"phase unknown"**.

This feature closes the loop. The pipeline **skills become the canonical producers** of every field
the dashboard consumes: `/aid-interview` writes a typed work **Name/Description** header into
`REQUIREMENTS.md`; `/aid-detail` guarantees a descriptive `# task-NNN: <title>` short-name and emits
a **machine-parseable wave block** in `PLAN.md`'s Execution Graph so the reader can derive each task's
(delivery, lane); the `## Pipeline Status` block (feature-001) is confirmed as the single phase
source. The reader (Python + Node, byte-parity) and front-end are **reconciled to these real
formats**, the PT-1 fixture is **regenerated from real producer output** and guarded by a
producer↔consumer contract test, work-001's pre-feature state is **migrated**, and the canonical
producer edits are **dogfood-rendered** into `.claude/skills/` so `/aid-*` on this repo uses them
immediately. The reader stays **read-only and no-LLM** throughout; the producer edits only **add**
display fields, preserving all pipeline behavior (C4/C5).

## User Stories

- As an **operator**, when I point the dashboard at my real repo, I want every work to show its
  human Name, a clean one-sentence Description, its real phase, and tasks grouped under the right
  Delivery and lanes — never `work_id`, `Delivery #0`, `phase unknown`, or a leaked blockquote.
- As a **pipeline maintainer**, I want the dashboard's display fields **produced by the skills that
  own those artifacts**, so the dashboard reflects reality instead of an invented fixture.
- As a **dashboard developer**, I want a contract test that fails fast when a producer format and the
  reader's parse drift apart, so the consumer can never silently desync from the producer again.
- As an **operator of a legacy / partially-migrated work**, I want missing fields to degrade to a
  clean `—` / "not yet recorded", never to garbage.

## Priority

Must (closes the MVP's real-data gap; without it the shipped dashboard mis-renders the only real
work in this repo).

## Acceptance Criteria

- [ ] Given a work whose `REQUIREMENTS.md` carries the typed identity header, when the reader runs,
      then the work-overview header shows the human **Name** and the one-sentence **Description**, and
      **never** the raw `work_id` **styled as the authored Name** (a labelled de-slugged fallback is
      permitted per PF-7) nor any leaked `> _..._` blockquote in the description.
- [ ] Given a `## 1. Objective` whose first body line is a `> _Status: ..._` blockquote, when the
      reader parses the Objective, then the leading status blockquote(s) are **skipped** and never
      appear in the displayed objective.
- [ ] Given each `tasks/task-NNN.md` whose first line is `# task-NNN: <descriptive title>`, when the
      reader runs, then each task card shows the **real short-name**, not only its `task-NNN` id.
- [ ] Given a work with a `## Pipeline Status` block, when the reader derives phase/lifecycle, then
      both come **solely** from that block (no secondary/inferred phase source); given the block is
      absent (bootstrap), the phase degrades to a clean `—` (never `phase unknown` garbage).
- [ ] Given the real `## Tasks Status` Wave column = `delivery-NNN` and `PLAN.md`'s `## Execution
      Graph`, when the reader builds the task hierarchy, then each task resolves to its correct
      **(delivery, lane#)** — deliveries grouped by the real `delivery-NNN`, lanes derived from that
      delivery's wave structure — and **no** task falls into `Delivery #0`.
- [ ] Given `settings.yml` `project.name: AID  # set during /aid-config INIT`, when the reader parses
      the project name, then the inline `# ...` comment is **stripped** and the name renders as `AID`.
- [ ] Given the migrated work-001 repo, when the dashboard renders end-to-end (both runtimes), then
      there are **no degraded/garbage fields** (no `work_id` title, no leaked blockquote, no
      `Delivery #0`, no `phase unknown`).
- [ ] Given a work still missing a producer field, when the dashboard renders, then that field shows
      `—` / "not yet recorded" uniformly across header, delivery/lane grouping, and task cards —
      never garbage.
- [ ] Given the producer-emitted artifacts and the reader, when the **producer↔consumer contract
      test** runs, then it asserts producer-emitted format ⇄ reader-consumed model equivalence and
      fails if a future producer-format change drifts.
- [ ] Given the canonical producer edits, when the **FULL `run_generator.py`** runs, then all five
      install trees stay byte-identical and the **render-drift + deterministic-emission gates** stay
      green; the reader (Python + Node) stays **byte-parity** (PT-1) and **read-only / no-LLM**.

---

## Technical Specification

> Activated sections (per `canonical/templates/specs/spec-template.md`): **Data Model** (the
> canonical on-disk producer formats this feature defines/confirms), **Feature Flow**
> (producer-writes → reader-derives), **Layers & Components** (which skills + reader/front-end files
> change, with the Python↔Node parity contract), **Migration Plan** (work-001 bootstrap), and the
> **BDD Scenarios** (the embedded test scenarios). Other template sections are not applicable (no API/DB/UI-mockup/CQRS/
> event/security surface beyond what features 001–005 already specify).

### Data Model

This feature is fundamentally a **schema-of-record** feature: it pins the exact on-disk producer
formats the reader consumes. Five canonical formats are **defined or confirmed**. Three are
**reader-only sentinels** (em-dash placeholders) for graceful degradation.

#### PF-1 — `REQUIREMENTS.md` typed identity header (FR19) — NEW producer format

Placed **immediately after the `# Requirements` H1, before `## Change Log`** (so it is the first
content block and unambiguous to parse). Written by `/aid-interview`.

```markdown
# Requirements

- **Name:** AID Live Dashboard
- **Description:** A local-only, read-only HTML dashboard that visualizes AID pipeline state and live run progress per repo.

## Change Log
...
```

- **`- **Name:**`** — a short human-readable work name (Title Case, no trailing period). The
  dashboard work-overview title.
- **`- **Description:**`** — exactly **one sentence**, **derived from the Objective at author time**
  (the interviewing agent composes a one-sentence summary of `## 1. Objective` and the user confirms
  it during the COMPLETION checkpoint). It is **not** the Objective body verbatim and **not** free-form
  authored separately.
- **Parse rule (reader):** anchored line-scan `^\s*-\s*\*\*Name:\*\*\s*(.+)` and
  `^\s*-\s*\*\*Description:\*\*\s*(.+)` (case-insensitive), first match wins. Already present in
  `parse_requirements_md` (Python) / `parseRequirementsMd` (Node) — **the parse exists; the producer
  did not.** This FR makes `/aid-interview` the producer.

#### PF-2 — `## 1. Objective` body parse must skip status blockquotes (FR19/FR25) — reader fix

The reader already captures the body under `## 1. Objective` (or `## Objective`) until the next `##`.
The real Objective body is followed by a `> _Status: Complete — approved._` blockquote (an
interview-status footer the existing pipeline writes throughout REQUIREMENTS.md sections).

- **Parse rule (reader, NEW):** while accumulating Objective body lines, **drop any line that, after
  `strip()`, matches `^>\s*_.*_\s*$`** (a markdown blockquote whose content is wholly italic — the
  status-footer shape). Leading/trailing blank lines are already trimmed. This is a **producer-neutral**
  fix: the status footer is an existing pipeline convention and is NOT removed from REQUIREMENTS.md
  (it is content history); the reader simply does not display it.
- Both runtimes apply the identical regex; PT-1 byte-parity covers a fixture with a status blockquote
  in the Objective body.

#### PF-3 — Task short-name = `# task-NNN: <title>` first line (FR20) — CONFIRM + reader read

The canonical task-file format (`aid-detail/references/task-decomposition.md § Task File Format`)
**already mandates** `# task-NNN: {Title}` as line 1. No new producer field is introduced; the
short-name **already exists** at the source. This FR:

1. **Reader (NEW):** for each `tasks/task-NNN.md`, read the first non-blank line and parse
   `^#\s+task-0*\d+\s*:\s*(.+)$` (case-insensitive); the capture group is the task short-name. Strip a
   trailing period. Absent/unparseable → short-name is `None` (degrades per PF-7).
2. **Producer guardrail (`/aid-detail`):** `task-decomposition.md` is amended with an explicit rule
   that the `{Title}` must be a **descriptive short-name** (a noun phrase naming the deliverable of
   the task), not a restatement of the type or a bare id, and that `/aid-execute` **preserves** the
   title on any task-file update. This is a documentation/guardrail change, not a format change.
- **Reader cost note:** this adds **one small extra file read per task** (the task file's first line
  only — read bounded, first line is sufficient). `ReadMeta.bytes_read` accounts for it; NFR4 holds
  (task files are small and the read is first-line-bounded where the runtime allows).

#### PF-4 — Phase = `## Pipeline Status` `- **Phase:**` (FR21) — CONFIRM single source

The typed `## Pipeline Status` block (feature-001, `work-state-template.md`) is the **single source of
truth** for phase and FR16 lifecycle. This FR introduces **no new producer**; it requires:

- **Reader audit:** confirm phase/lifecycle are derived **solely** from `## Pipeline Status` and that
  no secondary/inferred phase source exists in the normalized path. (The legacy `> **Phase:** Execute`
  blockquote header at the top of work-001's STATE.md — see Migration — is **not** a phase source for
  the normalized reader; it is bootstrap cruft the migration replaces with the typed block.)
- **Bootstrap/absent handling:** when `## Pipeline Status` is absent, the reader's existing fallback
  adapter (feature-002) runs and phase is `None`; the front-end renders the phase rail in a neutral
  "phase not yet recorded" state (PF-7), **never** the literal `phase unknown` badge as a garbage
  value. Work-001's absent block is filled by Migration (FR26).

#### PF-5 — Lane source = `PLAN.md` `## Execution Graph` (FR22, decision B) — NEW normalized producer format + best-effort legacy parse

**Problem.** The real `## Tasks Status` Wave column is the bare **`delivery-NNN`** (the delivery). The
front-end's `parseWave()` expects the **invented** `delivery-NNN-wave-M` and so derives
`lane`/`delivery` = 0 on real data → every task in **"Delivery #0"**. Lanes must come from `PLAN.md`'s
`## Execution Graph`, which defines the waves **per delivery**.

The real PLAN.md Execution Graph is **prose** (`### delivery-NNN execution graph` → `- Wave N: task-X ∥
task-Y`, `→` sequential), and the canonical `execution-graph-generation.md` currently emits a *different*
shape again (a `Task | Depends On` table). Neither is reliably machine-parseable for (delivery, lane).

**Decision (justified): emit a normalized machine-readable wave block in `/aid-detail` going forward,
AND ship a best-effort reader for legacy/prose PLANs.** Rationale: a normalized block is a small,
behavior-preserving addition that makes the reader's job a deterministic table lookup (no inference,
NFR7); the best-effort legacy parser keeps already-written PLANs (work-001) renderable until/without
re-running `/aid-detail`. We do **not** add an invented wave column to STATE (FR22 forbids it).

**PF-5a — Normalized Wave Map (NEW producer format, `/aid-detail` Execution Graph).** Under each
`### delivery-NNN execution graph`, `/aid-detail` additionally emits a fenced, typed **Wave Map** that
lists, per wave, the task ids in that wave:

````markdown
### delivery-001 execution graph

<!-- ... existing prose / dependency tables stay (human-facing) ... -->

```wave-map
delivery: 001
wave 1: task-001
wave 2: task-002, task-003, task-004, task-005, task-006, task-007, task-008, task-009, task-010, task-011, task-012
wave 3: task-013
```
````

- A `wave-map` fenced block per delivery. Each `wave N: <comma-separated task ids>` line maps a lane
  number `N` to its tasks. The `delivery: NNN` line is the delivery key.
- **Reader parse rule (normalized):** scan `PLAN.md` for ```` ```wave-map ```` blocks; for each, read
  `delivery: NNN` and each `wave N: ...` line; build a map `task_id → {delivery: NNN, lane: N}`.
  Deterministic, total, no inference.

**PF-5b — Best-effort legacy parse (prose Execution Graph).** When no `wave-map` block exists for a
delivery, the reader falls back to parsing the prose under `### delivery-NNN execution graph`:
- A line matching `^\s*-\s*Wave\s+(\d+)\b` opens lane `N`. The task ids for that wave are read from
  the `- Wave N` heading line **and its sub-bullets** — the real PLAN puts the ids on indented
  sub-bullets (e.g. `- Wave 2 (two parallel lanes after task-001):` followed by
  `- feature-001 lane: task-002 → ...` / `- feature-002 lane: task-010 → ...`), so the parser must
  descend into lines more-indented than the `- Wave N:` bullet (until the next `- Wave` or
  blank-then-dedent) and collect every `task-\d+` token found there. `∥`, `→`, `(a ∥ b)` decorations
  are ignored for grouping (every task id mentioned in the wave is in that lane).
- **Acknowledged fidelity loss:** where the prose expresses **multiple parallel sub-lanes within one
  wave** (the two `- feature-NNN lane:` sub-bullets above), the legacy parser **MAY flatten** them to
  a **single lane `N`** for that wave — it reads the ids correctly from the sub-bullets but does not
  reconstruct the distinct sub-lanes from prose. This is a **bounded** fidelity loss (tasks still land
  in the right delivery and right wave, just one merged lane instead of two). It is **fully resolved**
  once `/aid-detail` emits the normalized `wave-map` (PF-5a), which can carry one `wave N:` line per
  sub-lane; this is the migration path for work-001 (FR26 transcribes the sub-lanes into the wave-map).
- This is **best-effort and explicitly lossy-tolerant**: any task id never mentioned in the graph
  keeps its STATE Wave `delivery-NNN` for the delivery and gets **lane `None`** (rendered in a single
  "unsequenced" lane within the delivery — never `Delivery #0`).

**PF-5c — Delivery key.** In **all** paths the delivery a task belongs to is the **real** STATE
`## Tasks Status` Wave column `delivery-NNN` (FR22: deliveries group by the real value). The Execution
Graph supplies only the **lane within** that delivery. If the wave-map / prose assigns a task to a
delivery that disagrees with its STATE Wave, **STATE wins** for the delivery key (the wave-map only
contributes the lane number).

**New reader output fields (per task):** `delivery: Optional[int]` (parsed from the STATE Wave
`delivery-NNN`) and `lane: Optional[int]` (from PF-5a/PF-5b). These replace the front-end's reliance on
the invented `delivery-NNN-wave-M` string.

#### PF-6 — `settings.yml` `project.name` inline-comment strip (FR23/FR26) — reader fix

`settings.yml` carries `name: AID  # set during /aid-config INIT`. The reader currently returns the
whole scalar including the comment.

- **Parse rule (reader, NEW):** after extracting the `name:` scalar, strip an inline YAML comment:
  drop everything from the first unquoted `#` to end-of-line, then `strip()` and strip surrounding
  quotes. Result: `AID`. (`/aid-config` already writes a clean value; this is purely a
  reconciliation/robustness fix per FR26's note — not a missing producer field.) Applied identically
  in Python and Node.

#### PF-7 — Degradation sentinels (FR25) — reader/front-end contract

Uniform missing-field handling. The reader emits `null` for any absent field; the **front-end** maps
`null` to a legible placeholder and **never** to garbage:

| Field | Absent → render | Forbidden garbage |
|-------|-----------------|-------------------|
| work title (`title`) | the work's human slug from `work_id` *as a labelled fallback only if Name truly absent*, else `—` | raw `work_id` rendered as if it were the title |
| description | `—` / "not yet recorded" | a leaked `> _Status:_` blockquote |
| objective | section hidden | the status-footer blockquote |
| phase | "phase not yet recorded" (neutral rail) | a `phase unknown` error badge as a value |
| task short-name | the `task-NNN` id | — |
| delivery / lane | delivery from STATE Wave; lane → single "unsequenced" lane | `Delivery #0` |

> Note on the title fallback: FR25 forbids rendering the **raw `work_id`** as the title. When `Name` is
> truly absent the front-end may show the de-slugged work name (e.g. `aid-dashboard`) **explicitly
> labelled as a fallback** (dimmed / kicker), not styled as the authored Name. After Migration (FR26)
> work-001 has a real Name, so this path is exercised only by legacy works.

#### Schema version bump

The `/api/model` envelope `schema_version` is bumped **2 → 3** (the per-task `delivery`/`lane` integer
fields + the task `short_name` field change the serialized model shape). The front-end's `EXPECTED`
schema constant, both servers' envelope, the DM-3 serializer key order, and the PT-1 fixture all move
to 3 in lockstep.

**Resolution of the delivery-005 / task-034 conflict (concrete, not deferred).** Both servers
currently emit `schema_version 2` and the front-end `EXPECTED` is `2`. delivery-005's task-034 still
**stalely** says it bumps "1→3"; that string is **superseded**. feature-009 **owns the move to 3**:
it lands `schema_version 3` first. From there exactly one of two outcomes holds, to be finalized in
`/aid-plan`:
- If delivery-005's features 007/008 (envelope growth) land **after** feature-009 and further change
  the wire shape, task-034 is **re-baselined to a 3→4 cut** (it becomes a 3→4 bump, not 1→3), and the
  envelope re-baselines to 4.
- If 007/008 land after feature-009 with **no further wire-shape change**, they **stay at 3** and
  task-034 carries no schema bump.

Either way, **feature-009 is the sole owner of the move to `schema_version 3`**, and task-034's
"1→3" wording is obsolete. The exact 3-vs-3→4 choice depends on land order and is finalized in
`/aid-plan`, but the schema floor this feature establishes (3) is fixed.

### Feature Flow

The end-to-end loop is **producer writes → reader derives → front-end renders**, per field:

```
PRODUCER (canonical/skills, dogfood-rendered to .claude/skills via run_generator.py)
  /aid-interview  ──writes──▶  REQUIREMENTS.md  # Requirements / - **Name:** / - **Description:**   (PF-1)
  /aid-detail     ──writes──▶  tasks/task-NNN.md  "# task-NNN: <title>"                              (PF-3)
  /aid-detail     ──writes──▶  PLAN.md  ## Execution Graph  ```wave-map``` per delivery              (PF-5a)
  phase skills    ──writes──▶  STATE.md  ## Pipeline Status  - **Phase:** (already; feature-001)     (PF-4)
  /aid-config     ──writes──▶  settings.yml  project.name (already; clean value)                     (PF-6)
        │
        ▼
READER  read_repo(aid_root)  [Python reader/*.py  ∥  Node server/reader.mjs — byte-parity]
  REQUIREMENTS.md ─▶ parse_requirements_md: title, description, objective (skip > _..._ )            (PF-1, PF-2)
  tasks/*.md      ─▶ parse_task_short_name: first-line title                                          (PF-3)
  PLAN.md         ─▶ parse_execution_graph: task_id → (delivery, lane)  [wave-map → legacy prose]     (PF-5)
  STATE.md        ─▶ parse_state_md: ## Pipeline Status phase/lifecycle (single source)               (PF-4)
  settings.yml    ─▶ parse_project_name: strip inline # comment                                       (PF-6)
        │  assembles WorkModel{ title, description, objective, tasks[{short_name, delivery, lane}], phase } + null sentinels
        ▼
ENVELOPE  { schema_version: 3, generated_by: "python"|"node", model }   (DM-1; serialized identically both runtimes)
        ▼
FRONT-END  index.html  (no-LLM, polls /api/model)
  work-overview header  ◀─ title / description / objective (PF-1/2/7)
  phase rail            ◀─ phase  (PF-4/7 — neutral when absent)
  Delivery > Lane > Task ◀─ group by task.delivery, order lanes by task.lane (PF-5; parseWave() removed)
  task chip             ◀─ short_name (PF-3/7)
```

Read-only / no-LLM is preserved end-to-end (NFR2/NFR7/C5): the reader gains only **parse** rules and
**one extra read per task file**; it still performs no write, lock, subprocess, or agent/LLM call.

### Layers & Components

#### Producer layer — `canonical/skills/` (behavior-preserving additions; C4/C5)

| Component | Change | FR |
|-----------|--------|----|
| `aid-interview/references/state-first-run.md` (REQUIREMENTS scaffold) | Scaffold the `- **Name:** / - **Description:**` block between `# Requirements` and `## Change Log` (seeded `*(pending)*` at first run). | FR19 |
| `aid-interview/references/state-completion.md` (or the COMPLETION checkpoint) | Compose the one-sentence Description **from `## 1. Objective`**, present it for user confirmation, and write Name + confirmed Description into the header block. | FR19 |
| `canonical/templates/requirements/requirements-template.md` + `canonical/templates/requirements.md` | Add the identity header block to the canonical REQUIREMENTS template so new works are born with it. | FR19 |
| `aid-detail/references/task-decomposition.md` | Add the explicit "descriptive short-name" rule for the `# task-NNN: {Title}` line (no format change) + an `/aid-execute`-preserves-title note. | FR20 |
| `aid-detail/references/execution-graph-generation.md` | Emit the ` ```wave-map``` ` block per `### delivery-NNN execution graph` (PF-5a) alongside the existing human-facing graph. | FR22 |

> No phase producer change (FR21 confirms feature-001). No `/aid-config` change (settings.yml value is
> already clean; PF-6 is reader-side). These are the **only** producer edits, and each only **adds**
> emitted content — phases, gates, outputs, decisions are unchanged (C4/C5).

#### Consumer layer — reader (Python `dashboard/reader/*` ∥ Node `dashboard/server/reader.mjs`)

Both runtimes change in lockstep; PT-1 cross-runtime **byte-parity** is the contract (the Node twin is
a literal port of each new parse rule — same regexes, same edge cases, same null handling).

| Component | Change | PF |
|-----------|--------|-----|
| `reader/models.py` (+ Node shape) | `TaskModel`: add `short_name: Optional[str]`, `delivery: Optional[int]`, `lane: Optional[int]`. | PF-3, PF-5 |
| `reader/parsers.py` / `reader.mjs` — `parse_requirements_md` / `parseRequirementsMd` | Objective body parse **skips** `^>\s*_.*_\s*$` status blockquote lines. | PF-2 |
| `reader/parsers.py` / `reader.mjs` — NEW `parse_task_short_name` | Read each `tasks/task-NNN.md` first line; parse `# task-NNN: <title>`. | PF-3 |
| `reader/parsers.py` / `reader.mjs` — NEW `parse_execution_graph` | Parse `PLAN.md`: `wave-map` blocks (normalized) → fallback prose parse; emit `task_id → (delivery, lane)`. | PF-5 |
| `reader/parsers.py` / `reader.mjs` — `parse_project_name` / `parseProjectName` | Strip inline `# ...` comment from the `name:` scalar. | PF-6 |
| `reader/reader.py` / `reader.mjs` — `_read_work` | Read `PLAN.md` once per work; read task-file first lines; join `(delivery, lane, short_name)` into each `TaskModel`; keep STATE Wave as the delivery key (PF-5c). | PF-3, PF-5 |
| both servers (`server.py`, `server.mjs`) | Envelope `schema_version` 2 → 3; DM-3 serializer key order updated for the new task fields (deterministic, U+2028/U+2029 escape preserved). | schema bump |

New files read by the reader: **`PLAN.md`** (per work) and **`tasks/task-NNN.md`** (first line per
task) — both read-only; `ReadMeta.bytes_read` accounts for them (NFR4).

#### Front-end layer — `dashboard/index.html` (no-LLM)

| Change | PF |
|--------|-----|
| **Remove `parseWave()`**; group tasks by `task.delivery` (integer) and order lanes by `task.lane`; tasks with `lane == null` go to one "unsequenced" lane within the delivery. The delivery label uses the integer `delivery`. | PF-5 |
| **`uiState.lanes` persistence key (NEW):** removing `parseWave()` drops the old raw-wave-string key (`"delivery-002-wave-2"`), so the open/collapse key must be re-derived. The replacement key is **delivery-scoped**: `"d" + delivery + "-lane" + lane` (e.g. `"d2-lane2"`), and the "unsequenced" lane uses `"d" + delivery + "-unseq"`. Delivery-scoping is required so lane open/collapse state cannot collide across deliveries (e.g. lane 1 of delivery-001 vs lane 1 of delivery-002 must persist independently). | PF-5 |
| Task chip shows `task.short_name` (fallback to `task-NNN` id). | PF-3/7 |
| Work-overview title uses `title`; on absent `title` render the labelled de-slug fallback, never the raw `work_id` styled as the Name. Description/objective already wired; verify blockquote can't leak (PF-2 guarantees it upstream). | PF-1/2/7 |
| Phase rail: when `phase` is null/Unknown, render a **neutral** "phase not yet recorded" state, not a `phase unknown` error value. | PF-4/7 |
| `EXPECTED` schema constant 2 → 3. | schema bump |

> Per the global web-review gate, the front-end change is validated with **Playwright** over both the
> regenerated PT-1 fixture and the **migrated real work-001 repo** (screenshot + DOM assertions: real
> Name, no blockquote, real delivery numbers, no `Delivery #0`, real phase).

#### Dogfood render (FR24/C5)

After the canonical-skill edits, run the **FULL** `.claude/skills/aid-generate/scripts/run_generator.py`
(not a per-script renderer) so `canonical/skills/*` re-emit into all install trees including this repo's
`.claude/skills/`. The **render-drift** and **deterministic-emission** CI gates must stay green (all
five install trees byte-identical; emission manifests current).

### Migration Plan (FR26 — work-001 bootstrap)

work-001 predates these producers; its artifacts are migrated **in place** to the canonical schema. The
migration is a one-time content edit (a MIGRATE-typed task), not a behavior change.

| Artifact | Current (real) state | Migrated to |
|----------|----------------------|-------------|
| `REQUIREMENTS.md` | `# Requirements` → `## Change Log` (no identity header); `## 1. Objective` followed by `> _Status: Complete — approved._` | Insert the PF-1 header (`- **Name:** AID Live Dashboard` + a confirmed one-sentence Description derived from the Objective) between `# Requirements` and `## Change Log`. The status blockquote **stays** (reader skips it per PF-2). |
| `STATE.md` | Old blockquote header `> **Status:** Executing` / `> **Phase:** Execute`; **no** typed `## Pipeline Status` block | Add the typed `## Pipeline Status` block (feature-001 shape) with `Lifecycle: Running`, `Phase: Execute`, `Active Skill: none`, `Updated:`; keep the legacy blockquote header (harmless content history — reader ignores it). |
| `tasks/task-NNN.md` | First lines are already `# task-NNN: <descriptive title>` (verified on task-016) | **No change needed** — titles already descriptive; migration verifies each task file's title line parses (PF-3) and fixes any bare/non-descriptive ones. |
| `PLAN.md` `## Execution Graph` | Prose `### delivery-NNN execution graph` with `- Wave N: ...` | Add a ` ```wave-map``` ` block per delivery (PF-5a) transcribed from the existing prose, so work-001 uses the normalized path (the legacy parser PF-5b remains the safety net for any un-migrated PLAN). |
| `settings.yml` | `name: AID  # set during /aid-config INIT` | No change — value already `AID`; PF-6 strips the comment reader-side. |

**Acceptance of migration:** after migration, the reader over the real work-001 repo yields a model
with real Name/Description/Objective (no blockquote), `Phase: Execute`, real delivery grouping
(deliveries 001–005, correct lanes), real task short-names, and **zero** PF-7 garbage sentinels; both
runtimes byte-identical.

### BDD Scenarios

> This is the spec-template's canonical conditional **BDD Scenarios** slot
> (`canonical/templates/specs/spec-template.md`); the scenarios below are this feature's test
> scenarios populating that slot.
>
> Reader tests run on both runtimes; every parse/serialization assertion is mirrored Python↔Node and
> guarded by PT-1 byte-parity. The reader stays read-only/no-LLM (structural self-checks unchanged).

- **T-1 (PF-1 identity header):** REQUIREMENTS.md with the typed header → reader yields the human Name
  + one-sentence Description; absent header → `title=null`, `description=null` (not `work_id`).
- **T-2 (PF-2 blockquote skip):** Objective body followed by `> _Status: Complete — approved._` →
  `objective` excludes the blockquote; a fixture with multiple trailing status blockquotes all skipped.
- **T-3 (PF-3 task short-name):** `tasks/task-016.md` first line `# task-016: Python thin server ...`
  → `short_name` parsed; a task file with a bare `# task-007` (no title) → `short_name=null` → chip
  shows `task-007`.
- **T-4 (PF-4 single phase source):** STATE with `## Pipeline Status … - **Phase:** Execute` → phase
  Execute from that block only; STATE **without** the block (bootstrap) → `phase=null`, fallback
  lifecycle still derived, front-end renders neutral "phase not yet recorded" (not `phase unknown`).
- **T-5 (PF-5a normalized lanes):** PLAN.md with `wave-map` blocks + STATE Wave `delivery-NNN` →
  every task resolves to `(delivery, lane)`; no task has `delivery=0`; deliveries group by the real
  `delivery-NNN`.
- **T-6 (PF-5b legacy prose lanes):** PLAN.md with **no** wave-map (real work-001 prose) → best-effort
  parse assigns lanes from `- Wave N:` lines; a task absent from the graph → `lane=null` → single
  "unsequenced" lane, still under its STATE delivery (never `Delivery #0`).
- **T-7 (PF-6 comment strip):** `name: AID  # ...` → `AID`; `name: "Foo Bar" # x` → `Foo Bar`;
  quoted/inline-`#`-in-quotes handled.
- **T-8 (PF-7 degradation):** a synthetic legacy work missing every producer field → header `—`,
  neutral phase, "unsequenced" lane, id-as-name chips — **no** `Delivery #0` / `phase unknown` /
  leaked blockquote / raw-`work_id` title anywhere.
- **T-9 (fixture-from-real, FR23):** the PT-1 fixture is **regenerated by capturing the migrated
  work-001 artifacts** (REQUIREMENTS/STATE/PLAN/tasks snapshot of a conforming work) rather than
  hand-invented; a guard test asserts the fixture files are byte-for-byte a snapshot of conforming
  producer output (i.e. they parse under the **normalized** path with no PF-7 sentinels).
- **T-10 (producer↔consumer contract test, FR23):** write artifacts via the **real producer
  surface** (the canonical skill emission templates / a thin harness that emits PF-1/PF-3/PF-5a using
  the same strings the skills write), read them back via `read_repo`, and assert the produced format ⇄
  the consumed model agree field-by-field. A deliberately mutated producer string (e.g. `**Name**`
  without colon, or a `wave-map` typo) **fails** the test — proving drift is caught.
- **T-11 (cross-runtime parity, PT-1):** `/api/model` from `server.py` and `server.mjs` over the
  regenerated fixture **and** the real migrated work-001 repo are **byte-identical** at
  `schema_version: 3` (incl. U+2028/U+2029 and the new task fields).
- **T-12 (Playwright visual, real data):** render the migrated work-001 repo in both runtimes:
  assert real Name in the header, no blockquote in the description, real delivery numbers (no
  `Delivery #0`), real phase rail, real task short-names; zero JS errors; light + dark + responsive.
- **T-13 (dogfood render, FR24):** FULL `run_generator.py` re-emits the edited skills; render-drift +
  deterministic-emission gates green; ASCII-only gate green for any shipped script touched.

#### Known issue to register

- **KI (new): legacy PLANs without a `wave-map` block** render lanes via the best-effort prose parser
  (PF-5b), which is lossy-tolerant (un-graphed tasks → "unsequenced" lane). This is **annotated, not
  hidden** — the work degrades legibly (FR25) and is fully resolved by re-running `/aid-detail` (emits
  the normalized `wave-map`) or by the FR26 migration for work-001. Register in
  `.aid/work-001-aid-dashboard/known-issues.md`.

---

## Hardening delta (delivery-007) — enforce the producer contract

> Added after delivery-006 shipped. A post-delivery confidence analysis found the PF-1/PF-3/PF-5a
> emissions were worded as MUST but enforced only by reader graceful-degradation (no mechanical
> gate on produced output), and that the **Lite completion path emitted no identity header at all**
> (Lite works use a work-root `SPEC.md`, never a `REQUIREMENTS.md`, so the reader's Name/Description
> source did not exist for them). These three clauses close those gaps.

### PF-8 — Lite-path identity header (closes the Lite gap, highest priority)

- **Producer (template):** `canonical/templates/specs/lite-spec-template.md` seeds an identity block
  in the work-root SPEC header, immediately under the `# {title}` H1 and above `- **Work:**`:
  ```
  - **Name:** *(pending)*
  - **Description:** *(pending)*
  ```
- **Producer (CONDENSED-INTAKE):** when `state-condensed-intake.md` scaffolds the Lite SPEC it
  composes real values — **Name** from the work title (Title Case, no trailing period, not the
  `work_id` slug), **Description** one sentence distilled from the captured problem/objective — and
  writes them in place of the seeds.
- **Producer (LITE-DONE, the mandatory gate):** `state-lite-done.md` gains a **mandatory** step,
  run before `SPEC.md` Status→Ready: if Name/Description are absent or still `*(pending)*`, compose
  them now from the SPEC title/body. Worded "mandatory … not optional, not skippable," mirroring the
  full path's COMPLETION Step 3. (No new user round-trip on the fast path; the value is guaranteed
  non-pending by the terminal state.)
- **Consumer (reader, Python + Node byte-parity):** the work identity resolution gains a **SPEC.md
  fallback source**. Resolution order for `title`: REQUIREMENTS.md `- **Name:**` → work-root
  `SPEC.md` `- **Name:**` → SPEC.md `# {H1}` title → de-slug(`work_id`). For `description`:
  REQUIREMENTS.md `- **Description:**` → SPEC.md `- **Description:**` → null. `*(pending)*` remains a
  null sentinel at every source. A new `parse_spec_md()` / `parseSpecMd()` reads only these two
  fields + the H1; it must keep `/api/model` **byte-identical** across runtimes (PT-1).

### PF-9 — Producer-completeness gate (the keystone — converts MUST-by-prose → MUST-by-CI)

- New canonical suite `tests/canonical/test-producer-completeness.sh` (auto-discovered by
  `tests/run-all.sh`, which globs `tests/canonical/test-*.sh`). It runs **both** runtimes' `/api/model` over the conforming PT-1
  fixture (which FR23 keeps regenerated-from-real-producer-output) and **fails** if any field fell
  back to a degraded sentinel:
  - work `title` is null or equals `de-slug(work_id)` (identity never emitted),
  - work `description` is null,
  - any task has `delivery == null` or `lane == null` (wave-map not total),
  - any task `short_name` is null or equals its bare `task-NNN` id (PF-3 not honoured).
  Because the fixture is a byte snapshot of real producer output, a producer-format regression that
  reaches the fixture trips this gate. Complements T-11 (the canonical-instruction pin) by checking
  **produced output**, not instruction text.

### PF-5a+ — Mechanical wave-map derivation (hardens the most-omittable emission)

- `canonical/skills/aid-detail/references/execution-graph-generation.md` is strengthened so the
  agent **derives** the `wave-map` directly from the `Depends On` table it just authored, rather than
  hand-composing it independently: wave 1 = tasks with no dependencies; wave N = tasks whose
  dependencies are all in waves `< N`; parallel sub-lanes within a wave get one `wave N:` line each.
  A **self-check** is mandated: every task id appearing in the delivery's dependency table MUST
  appear in exactly one `wave N:` line (the PF-9 gate enforces totality mechanically on the fixture).

### Acceptance (delivery-007)

- **HT-1:** Lite SPEC template carries the two seeded identity lines; a Lite work taken through
  CONDENSED-INTAKE → LITE-DONE has non-`*(pending)*` Name/Description in its work-root SPEC.md.
- **HT-2:** reader renders a real header for a Lite-style fixture (SPEC.md, no REQUIREMENTS.md):
  title from SPEC Name (or H1), description from SPEC Description; Python==Node byte-identical.
- **HT-3:** `test-producer-completeness.sh` passes on the conforming fixture and **fails** under a
  deliberately degraded fixture (stubbed null title / lane-less task) — proving the gate bites.
- **HT-4:** FULL `run_generator.py` re-emits cleanly (render-drift + deterministic gates green);
  ASCII-only green; all prior suites + PT-1 byte-parity still green at `schema_version: 3`.
