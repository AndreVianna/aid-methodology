# Thin-Router Skill Footprint Refactor

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-05-22 | Feature identified from REQUIREMENTS.md §5 (FR3 — M1 + M3) | /aid-interview |
| 2026-05-22 | M3 redefined as hook-driven auto-advance per cross-reference IQ1 | /aid-interview |
| 2026-05-22 | Technical Specification — Data Model section written (thin-router SKILL.md anatomy + `references/state-*.md` schema + dispatch-table contract) | /aid-specify |
| 2026-05-22 | Technical Specification — Feature Flow section written (one-step-per-invocation router loop; M3 hook-driven auto-advance with the 3-mode degradation ladder) | /aid-specify |
| 2026-05-22 | Technical Specification — Layers & Components section written (router / state-detail / advance layers; canonical-source-only edits; feature-001 / feature-003 interlock) | /aid-specify |
| 2026-05-22 | Technical Specification — Migration Plan section written (10-skill incremental cutover on `canonical/`; per-skill state-extraction recipe; NFR2 in-flight-workspace safety) | /aid-specify |
| 2026-05-22 | Technical Specification revised (E1, E2, A, F): M3 re-specified to the Stop-hook / skill-body-prompt / re-invocation ladder; footprint win made universal (OQ-2.1 dropped); `references` decomposition for all three trees; `task-NNN-STATE.md` merge reflected | /aid-specify |
| 2026-05-22 | Reviewer fixes (2 LOW, 1 MINOR): `aid-summarize` corrected 9 → 10 states with a composite-state (`DONE-IDEMPOTENT` → `DONE`) dispatch-mapping note; router / inline-body line counts labelled as estimates; `aid-discover` inline-Mode span corrected to 82–453 (verified against on-disk SKILL.md) | /aid-specify |
| 2026-05-22 | Cross-cutting fixes (CR6, CR7) + LOW finding fixes: (CR6) Data Model paragraph stating the dispatch table's `State` column owns the canonical UPPERCASE-with-hyphens state-id format for the methodology; (CR7) Layers & Components and a new Migration Plan "Template surgery" subsection now state that feature-002 delivers the extended two-zone `templates/delivery-plans/task-template.md` (Definition + empty Execution Record scaffold), updates `aid-detail` to write both zones, and deletes `templates/implementation-state.md`; vocabulary-bridge note (now removed by the M3 strip) and inline-Mode line-count narrative reworded — ~370 lines = 453 − 82 (full inline-Mode span); the 381→453 framing is the *last* Mode block only (~72 lines). | reviewer |
| 2026-05-22 | **Fresh-eyes scope reshape — M3 stripped; M1-only design.** Independent reviewer flagged M3 as fighting the platform (no host-tool hook can solicit a keystroke, the 3-mode degradation ladder is over-engineered, and `/aid-{skill}` re-invocation between states is acceptable to the user). M3 removed in its entirety: the 3-mode ladder (auto-advance / confirm-advance / manual), the Stop-hook integration, the capability-input table (`stop_hook_autocontinue` etc.), the vocabulary bridge, and all references to feature-003's M2 hook infrastructure / `emit-advance.sh` / advance signal. The dispatch table's `Advance` column is simplified to either the literal next-state name or `→ halt`. **M4 (sub-agent offload) survives as a per-skill authoring discipline inside M1** — each state's heavy work *may* dispatch a sub-agent if the per-skill design calls for it (as `aid-discover` already does), but it is not a separate mechanism. Feature-003 (which used to own M4 as a separate feature) and feature-006 have been dropped from work-001. Feature-001 reference repointed from work-001 to **work-002's feature-001-profile-driven-generator**. M1 thin-router design, CR6 (canonical state-id format = UPPERCASE-with-hyphens), CR7 (two-zone `task-template.md` + `implementation-state.md` deletion), and the line-count narrative (453/82/370) are unchanged. | /aid-specify |
| 2026-05-22 | Reviewer fixes (1 LOW, 1 MINOR) + feature-007 cross-feature resolution: (MINOR) AC2 run-on sentence split — terminal/human-gated halt-message clause is now its own sentence. (cross-feature) Resolved feature-007's deferred open questions OQ-A and OQ-C in a new Data Model subsection "State descriptors and single source of truth": OQ-A — the dispatch-table `State` column is the canonical state-id source, the human-readable descriptor lives in `references/state-{name}.md` (the file's first-line opening sentence is the descriptor); feature-002 owns the convention, feature-007 reads it. OQ-C — the `## Dispatch` table is the single source of truth for each skill's state set; feature-007's state-map descriptor must derive from it, never duplicate. No architecture change. | reviewer |
| 2026-05-24 | **Alignment Update** added (between Acceptance Criteria and Technical Specification). Explicitly retires CR7's two-zone `task-NNN.md` proposal — per work-003's deployed FR2 per-area STATE rule (now canonical per the 2026-05-24 REQUIREMENTS refresh), `task-NNN.md` stays 6-section flat and per-task state lives in the per-work `STATE.md ## Tasks Status` row. Body sections describing the two-zone shape become historical reference; the alignment update is the operative contract for /aid-plan and implementation. `implementation-state.md` deletion still applies (different reason — absorbed into per-area STATE consolidation rather than into a two-zone task-NNN.md). | /aid-specify |

## Source

- REQUIREMENTS.md §5 FR3 (mechanism M1), §7, §8, §9, §10

## Description

Every AID skill today carries a full state machine inline, so each invocation loads
far more content than the running state actually needs — a large footprint that is
itself suspected of contributing to slowness. This feature applies the structural
diet to the canonical source: each skill is refactored into a thin state router
(M1) whose SKILL.md shrinks to frontmatter, pre-flight, state detection, and a
dispatch table, with each state's detail moved to an on-demand
`references/state-{name}.md` loaded only when that state runs. State-to-state
progression remains user-driven: when a state completes, the router prints a
`Next: [State: {NEXT}] — run /aid-{name} again` line and exits, exactly as the
existing skills do today. The refactor changes only how skills are packaged and
loaded — the methodology's phases, artifacts, gates, and lite path behave
identically before and after.

## User Stories

- As an AID end user, I want each skill invocation to load only what the current
  state needs so that the methodology runs faster and feels less heavy.
- As an AID methodology maintainer, I want every skill structured as a thin router
  with per-state reference files so that skills are smaller, more uniform, and
  easier to maintain.

## Priority

Must

## Acceptance Criteria

- [ ] Given any AID skill, when its SKILL.md is inspected, then it is a thin router
  (frontmatter, pre-flight, state detection, dispatch table) and each state's detail
  lives in a `references/state-*.md` file loaded on demand.
- [ ] Given a skill state completes, when the router exits, then it prints the
  next-state hint (`Next: [State: {NEXT}] — run /aid-{name} again`); for terminal
  or human-gated states, it prints the appropriate halt message and the user
  re-invokes the skill to advance.
- [ ] Given the refactor is applied, when the AID pipeline is run, then its phases,
  artifacts, feedback loops, and quality gates — including the lite path — behave
  identically before and after the refactor.

---

## Alignment Update — 2026-05-24

> **REQUIREMENTS.md was refreshed on 2026-05-24** to align with work-003's
> deployed FR2 per-area STATE rule. Per the updated §5 scope-addition:
>
> - **`task-NNN.md` stays 6-section flat** (Definition only: Title, Type,
>   Source, Depends on, Scope, Acceptance Criteria). The on-disk
>   `canonical/templates/delivery-plans/task-template.md` already matches this
>   shape — **no template change is needed**.
> - **Per-task status, review records, and dispatch history live in the
>   per-work `.aid/work-NNN/STATE.md ## Tasks Status` row** (the FR2 area-STATE
>   rule shipped by work-003).
>
> **CR7 (two-zone `task-NNN.md` shape) is retired.** The original intent of CR7
> — retire `task-NNN-STATE.md` and consolidate per-task state — is achieved by
> work-003's per-area STATE consolidation rather than by the two-zone
> `task-NNN.md` shape this SPEC's body originally proposed.
>
> **What changes for this feature's body:**
>
> - The §Layers & Components "Template authorship" subsection's claim that
>   feature-002 *delivers* a two-zone `task-template.md` is superseded —
>   `task-template.md` is unchanged; feature-002 only **confirms** the shape.
> - The §Migration Plan "Template surgery" subsection (two-zone scaffold
>   addition + `aid-detail` update to write Execution Record + retain
>   `implementation-state.md` deletion) collapses to **just**
>   `implementation-state.md` deletion (still needed; its retirement reason is
>   now "absorbed into per-area STATE" instead of "absorbed into two-zone
>   task-NNN.md").
> - The §Data Model "now a single file with the Definition and Execution Record
>   zones" framing is superseded — task-NNN.md remains the same file, with the
>   same 6 sections it always had.
>
> **What stays the same:**
>
> - The thin-router refactor itself (M1) — SKILL.md shrinks to frontmatter +
>   pre-flight + state detection + dispatch table; per-state detail in
>   `references/state-*.md`.
> - CR6 — canonical state-id format (UPPERCASE-with-hyphens), owned by the
>   dispatch table's `State` column.
> - `templates/implementation-state.md` deletion — still happens (no consumer).
> - The state descriptors / single-source resolution for feature-007 (now
>   work-003/feature-001) OQ-A and OQ-C.
>
> Body sections below describe the original two-zone design as historical
> reference; treat their "two-zone task-template.md" / "Execution Record zone"
> references through this alignment update during /aid-plan and
> implementation. A focused body-text rewrite is a candidate /aid-detail task
> and is not scoped into this feature.

---

## Alignment Update — 2026-05-24 (post-/aid-detail)

> **A second precision issue surfaced at /aid-detail time:** the §Data Model
> "Refactored skill — canonical structure" subsection assumes every skill
> uses `## Mode: NAME` H2 blocks as its per-state body convention. **Only 1
> of 10 skills (`aid-summarize`) actually uses this convention.** The reality:
>
> | Convention | Skills using it |
> |---|---|
> | `## Mode: NAME` | aid-summarize, aid-discover (mode-keyed with `## Step:` substructure) |
> | `## State N: NAME` | aid-interview, aid-specify |
> | `## Step N: TITLE` | aid-init, aid-deploy, aid-monitor, aid-execute |
> | Section-keyed (no per-state blocks) | aid-plan, aid-detail |
>
> The thin-router refactor (M1) **still applies** — every skill's body lifts
> into `references/*.md` files loaded on demand — but the **per-state block
> convention is per-skill, not uniform**. The body's `## Mode:` framing is a
> *Mode-keyed example*; the refactor recipe **generalizes** to whatever
> convention the source skill uses:
>
> - **Mode-keyed skills:** extract per-`## Mode:` body → `references/state-{mode-lower}.md`
> - **State-keyed skills:** extract per-`## State N:` body → `references/state-{state-name-slug}.md`
> - **Step-keyed skills:** extract per-`## Step N:` body → `references/step-{N}-{slug}.md` (or fold into a single procedural reference if the steps are tightly linear)
> - **Section-keyed skills (aid-plan, aid-detail):** no per-state blocks exist; refactor splits the body *thematically* into `references/{theme}.md` files (e.g., `references/dependency-mapping.md`, `references/parallel-grouping.md`); the dispatch table's rows become section anchors rather than state names
>
> **The thin-router invariant holds across all 4 patterns:** SKILL.md =
> frontmatter + pre-flight + state detection + dispatch table; per-state /
> per-section heavy detail lives in `references/`.
>
> **Dispatch table — `Detail` column** (was `Reference` in some downstream
> task drafts): per the §Data Model "Dispatch table" anatomy, the column
> name is **`Detail`** — the path to the per-state `references/*.md` file
> to load. /aid-detail tasks should use `Detail`.
>
> /aid-detail tasks 001-010 carry per-skill convention notes in their Scope
> bullets per this alignment update.

---

## Technical Specification

> **Read the Alignment Update above first** — it supersedes parts of the body sections below.
>
> This feature delivers FR3 mechanism **M1** (thin state router), with **M4**
> (sub-agent dispatch) folded in as a **per-skill authoring discipline** rather
> than as a separate mechanism: a state's `Worker` column in the dispatch table
> may point at a sub-agent if the per-skill design calls for it (the way
> `aid-discover` already dispatches discovery sub-agents), or at `inline` for
> trivial states. It is a **packaging and loading change applied to AID's own
> skills** — not a methodology redesign (§7): every phase, artifact, feedback
> loop, and quality gate behaves identically before and after. The work is
> performed on the FR5 `canonical/` source defined by **work-002's
> feature-001-profile-driven-generator**; the three install trees are then
> re-rendered by that generator.
>
> **What we are not doing.** The earlier M3 (host-tool-hook-driven auto-advance)
> is **dropped in its entirety** — no Stop-hook integration, no 3-mode degradation
> ladder, no `stop_hook_autocontinue` capability flag, no vocabulary bridge. The
> user re-invokes `/aid-{name}` between states (this is acceptable and matches
> today's behavior). Feature-003 (hooks and mechanical offload) and feature-006
> have been dropped from work-001 and are not consumed by this feature.

### Data Model

This feature has no database. Its "data model" is the **on-disk shape of a
refactored skill** — the structural contract the generator renders and the host
tool loads. Today a skill is a single monolithic `SKILL.md` carrying its whole
state machine inline (`aid-discover/SKILL.md` is 596 lines, byte-identical across all 3 install trees + the canonical source after work-002). M1 replaces that with a fixed thin-router anatomy.

#### Refactored skill — canonical structure

The unit of work is one `canonical/skills/aid-{name}/` folder. After M1 it has
this fixed shape (uses the same `canonical/` source-of-truth invariant work-002's feature-001-profile-driven-generator established; this feature adds the thin-router decomposition on top):

```
canonical/skills/aid-{name}/
  SKILL.md                       # the thin router — see anatomy below
  references/
    state-{name}.md              # one per state; the heavy per-state detail
    ...
  scripts/
    *.sh                         # mechanical helpers (existing skills already ship these)
```

#### SKILL.md — the thin-router anatomy

The router `SKILL.md` is reduced to exactly five parts, in this order. Each part
has a bounded role; nothing state-specific lives here.

| # | Part | Content | Source convention |
|---|------|---------|-------------------|
| 1 | **Frontmatter** | `name`, `description` (folded `>`, with the `State machine: A → B → …` line), `allowed-tools`, optional `argument-hint`; Claude Code may add `context:` / `agent:` | `coding-standards.md` §1.1 — unchanged; rendered per-tool by the FR5 profile's `skill.frontmatter` |
| 2 | **Title + opening paragraph** | `# {Sentence-case title}` + one paragraph stating what the skill does | `coding-standards.md` §1.2 |
| 3 | **Pre-flight checks** | `## ⚠️ Pre-flight Checks` — environment / state preconditions. Each mechanical check is delegated to a `scripts/*.sh` helper that the skill already ships; the router only reads exit codes and branches | `coding-standards.md` §1.2 item 3 |
| 4 | **State detection** | `## State Detection` — the `⚠️ FILESYSTEM IS THE ONLY SOURCE OF TRUTH` rule, the disk-read logic that maps current files to a state name, and `Print: [State: {NAME}]` | Pattern 1, `architecture.md` §4; verbatim from `aid-discover/SKILL.md:42–78` |
| 5 | **Dispatch table** | `## Dispatch` — a markdown table: one row per state → the `references/state-{name}.md` to load, the executor/sub-agent to invoke (or `inline`), and the next state | New — replaces the inline `## Mode: {NAME}` H2 blocks |

The router carries **no state body**. The current `## Mode: GENERATE`,
`## Mode: REVIEW`, etc. H2 blocks move out wholesale into `references/state-*.md`.
For `aid-discover/SKILL.md` the inline state-body block is the bulk of the
file (currently spans ~lines 131-596 in the post-subagent-visibility-patch
version, ~465 lines). Lifting this body into per-state `references/state-*.md`
files leaves a thin router that is a small fraction of the original. Numbers
are illustrative and drift with each skill-body edit — the structural claim
(most of the file lifts out) survives any specific line-count refresh.

#### `references/state-{name}.md` — per-state detail file

One file per state in the skill's state machine. It carries everything the router
used to inline for that state, and **only** that state:

| Element | Content |
|---------|---------|
| `# State: {NAME}` | H1 naming the state (matches the dispatch-table key and the `[State: {NAME}]` print) |
| Opening line | One sentence: what this state does and the precondition that selects it |
| Step list | The numbered steps (today's `### Step 1`, `### Step 2`, …) |
| Sub-agent prompt reference | If the state's heavy work runs in a sub-agent (per-skill authoring discipline — see M4 note below), the prompt or a pointer to a prompt reference file |
| Exit line | `Print: [State: {NAME}] complete.` and the next-step statement (`Next: [State: {NEXT}] — run /aid-{name} again` or the halt message for terminal / human-gated states) |

State files contain no frontmatter (they are not independently invocable) and no
cross-state logic (state selection stays in the router).

#### Dispatch-table contract

The `## Dispatch` table is the router's single routing surface. Schema:

| Column | Meaning |
|--------|---------|
| `State` | **UPPERCASE** state name (hyphens for multi-word — see "Canonical state-id format" below); matches a `references/state-{name}.md` and the detection logic |
| `Detail` | Relative path `references/state-{name}.md` loaded **only** when this state is entered |
| `Worker` | Executor / sub-agent for the state's heavy work (per-skill authoring discipline), or `inline` if trivial |
| `Advance` | **One of three forms.** (1) **Unconditional:** `→ {NEXT-STATE-NAME}` — the literal name of the next state in the machine. (2) **Halt:** `→ halt` — terminal / human-gated (the user re-invokes the skill to proceed). (3) **Conditional:** `→ {STATE-A} ({condition}) / → {STATE-B} ({otherwise})` — allowed *only* when the branch depends on a **computed criterion** (a grade, a count, a status field) that is deterministic and inspectable from STATE.md without further dialog. Exactly one conditional split per row, with a clear else. No multi-step ladders, no mode logic, no user-input branches (those are state-detection logic). **Canonical example:** `aid-execute` REVIEW row — `→ FIX (grade < min) / → DONE (grade ≥ min)`. **Retro-apply candidates:** `aid-summarize` VALIDATE row, `aid-interview` LITE-REVIEW row (each has grade-driven routing previously hidden in state-body prose). |

> **Canonical state-id format (owned here, CR6).** The dispatch table's `State`
> column is the **canonical source of truth for state ids across the
> methodology**: every id is **UPPERCASE**, with **hyphens** for multi-word
> names — `RENDER`, `REVIEW`, `LOAD-TASKS`, `EXECUTE-WAVE`, `DONE`, `APPROVAL`,
> `QUICK-CHECK`, `DELIVERY-GATE`, `STALE-CHECK`, `MANUAL-CHECKLIST`,
> `DONE-IDEMPOTENT`, `Q&A`. This **aligns with the existing on-disk corpus**
> (`aid-summarize` uses `STALE-CHECK` / `MANUAL-CHECKLIST` / `DONE-IDEMPOTENT`;
> feature-004 uses `QUICK-CHECK` / `DELIVERY-GATE`) — no rename migration is
> needed. Other features that name AID states (notably feature-007) inherit this
> format verbatim. The same id appears as the H1 of the matching
> `references/state-{name}.md` (`# State: {NAME}`) and in the router's
> `Print: [State: {NAME}]` line — one spelling, one shape, repo-wide.

`DONE` and human-gated states (`APPROVAL`, `Q&A`) carry `Advance: → halt` — the
router prints the appropriate halt message and exits; the methodology's human
checkpoints are preserved verbatim (the §7 guarantee).

#### State descriptors and single source of truth (resolves feature-007 OQ-A and OQ-C)

The dispatch table above is the **canonical surface for the state list of each
skill** — there is no parallel registry. Two cross-feature contracts follow
directly, and resolve feature-007's deferred open questions OQ-A and OQ-C:

- **Descriptor carrier (OQ-A).** The `State` column of the dispatch table is the
  canonical **state-id** source. The **human-readable descriptor** for a state
  (the short label feature-007's "you are here" map prints, and the label the
  router's state-entry message can read) lives in
  `references/state-{name}.md`: the file's **first line / one-line opening
  sentence** (the "what this state does and the precondition that selects it"
  line in the per-state schema above) serves as that descriptor. Feature-002
  **owns** this convention (the file shape, the first-line role); feature-007
  **reads** it. No separate descriptor file, no frontmatter field, no second
  registry.
- **Single source of truth for the state list (OQ-C).** The `## Dispatch` table
  in each skill's `SKILL.md` is the **single source of truth** for that skill's
  state set, ordering, and advance edges. Any feature that needs the list of
  states for a skill (notably feature-007's state-map descriptor) **derives** it
  from the dispatch table — it must not duplicate the list elsewhere. If a state
  is added, removed, or renamed, the dispatch table is the single edit; all
  consumers re-derive.

#### M4 as a per-skill authoring discipline (not a separate mechanism)

The dispatch table's `Worker` column may name a sub-agent for a state whose
heavy work warrants offload (the way `aid-discover` already dispatches its
discovery sub-agents), or it may say `inline` for a trivial state. This is a
**per-skill authoring discipline**, not a separate mechanism: each skill author
decides per-state, at refactor time, whether the work merits a sub-agent. There
is no new infrastructure, no new contract, and no separate feature delivering
this — it is simply how the `Worker` column is filled out, one row at a time,
during the per-skill router cutover. (Feature-003, which previously owned M4 as
a standalone feature, has been dropped from work-001.)

#### Backward-compatibility note (NFR2)

The refactor changes skill *packaging* only. It does not touch any `.aid/`
workspace artifact — `REQUIREMENTS.md`, `SPEC.md`, `PLAN.md`, `task-NNN.md`
(unchanged 6-section flat shape; per-task state now lives in the per-work
`STATE.md ## Tasks Status` row per work-003's FR2 area-STATE rule — see
Alignment Update above), and the work `STATE.md` is unchanged in shape. An in-flight workspace created before the refactor is read identically
by a refactored skill, because state detection still reads the same files
(Pattern 1's "filesystem is the only source of truth" invariant is preserved
verbatim).

### Feature Flow

There is one flow: the **per-invocation router flow** (M1). There is no
request/response cycle — the "flow" is a skill invocation inside the host tool.
There is no auto-advance flow: state-to-state progression is user-driven via
`/aid-{name}` re-invocation, exactly as today.

#### M1 — router flow (one invocation = one state)

```
/aid-{name} invoked
   │
   ▼
[1] Frontmatter loaded by host harness (per-tool, FR5-rendered)
   │
   ▼
[2] Pre-flight checks — router calls scripts/*.sh; reads exit codes
   │   fail → print remediation, exit
   ▼
[3] State detection — router reads .aid/ disk state, computes [State: NAME]
   │
   ▼
[4] Dispatch — router looks up NAME in the ## Dispatch table:
   │     • loads ONLY references/state-{name}.md  ← the footprint win
   │     • dispatches the row's Worker sub-agent if the per-skill
   │       design calls for it; otherwise runs inline
   │     • the state runs its steps
   ▼
[5] State exits — print [State: NAME] complete + next-step line
   │     ("Next: [State: {NEXT}] — run /aid-{name} again", or the
   │     halt message for Advance: → halt rows)
   │
   ▼
[6] Router exits — the user re-invokes /aid-{name} to advance
```

The footprint reduction is at step 4: a run loads the router (~80–120 lines —
*estimate*) plus exactly one `references/state-{name}.md`, instead of the whole
multi-state body. For `aid-discover` a REVIEW run loads the router +
`state-review.md` instead of all six `## Mode:` blocks — the bulk of the inline
state bodies (~370 lines — *estimate*) never enters context. Because all three
host tools support `references/` progressive disclosure, this saving is realized
identically on Claude Code, Codex, and Cursor (see Layers & Components).

#### Halt semantics

`Advance: → halt` rows (`DONE`, `APPROVAL`, `Q&A`) print the appropriate halt
message and exit without a next-state hint. The router never crosses a
methodology gate or a human-decision point — these are the concrete §7
preservation: the pipeline's gates and feedback loops keep their human
checkpoints, unchanged.

#### Lite-path interaction (FR1)

The lite path's condensed flow (feature-005 / FR1) runs the same router on the
same skills; a lite→full escalation is simply a state transition whose `Advance`
points into the full path. feature-002 does not implement the lite path; it only
guarantees the thin-router structure does not obstruct it.

### Layers & Components

This feature has no runtime service tiers. Its "layers" are the **structural
roles inside a refactored skill** plus the **build-time seam** to work-002's
generator.

| Layer | Component | Role |
|-------|-----------|------|
| Router | `canonical/skills/aid-{name}/SKILL.md` | The thin state router (M1): frontmatter + pre-flight + state detection + dispatch table. Loads exactly one state-detail file per run. Carries no state body. |
| State detail | `canonical/skills/aid-{name}/references/state-*.md` | One file per state (M1): the heavy per-state steps and prompts, loaded on demand by the router. |
| Source | `canonical/` (work-002's feature-001-profile-driven-generator) | Edits are made here once; the generator re-renders all three trees. M1's thin-router structure **is** that feature's canonical format. |
| Task template *(superseded — see Alignment Update above; row retained as historical reference)* | `templates/delivery-plans/task-template.md` (extended) + `aid-detail` skill update | This feature **delivers** the extended two-zone `task-NNN.md` template: a **Definition zone** (`Type` / `Source` / `Depends on` / `Scope` / `Acceptance Criteria`) and an **empty Execution Record zone scaffold** (section headers only, no content). `aid-detail` is updated to write **both** zones — Definition filled, Execution Record scaffold empty — so downstream skills (`aid-execute`, and feature-004's quick-check / delivery-gate blocks) write into a pre-existing scaffold rather than creating one. The retired `templates/implementation-state.md` template is **deleted by this feature**. |

#### Placement and the per-tool render

The refactor is authored **once in `canonical/`**. The FR5 generator (work-002's
feature-001-profile-driven-generator) then renders each install tree. Per the
host-tool research, **on-demand `references/` loading works on all three
tools** — Claude Code, Codex, and Cursor all implement Agent-Skills progressive
disclosure. Every profile's `skill.decomposition` is therefore `references`:

- `skill.decomposition = references` (all three trees) → `SKILL.md` +
  `references/state-*.md` kept as separate files. The router and state files ship
  as authored; the host harness loads a `references/state-*.md` only when the
  router points at it.

**The footprint win is universal.** Because all three tools support progressive
`references/` disclosure, a run loads the router plus exactly one
`references/state-{name}.md` on every tree — the per-state context saving
described in the M1 router flow is realized on Claude Code, Codex, and Cursor
alike. There is no "inline" fallback profile and no Claude-Code-first caveat; the
earlier open question OQ-2.1 (which scoped the footprint win to Claude Code) is
**resolved and dropped** by this finding.

#### Component boundaries — what feature-002 owns vs. consumes

- **Owns:** the thin-router anatomy, the `references/state-*.md` decomposition,
  the dispatch-table schema (with the simplified `Advance` column), the
  per-skill state-extraction work, and the `implementation-state.md` deletion (CR7 itself is retired per
  the Alignment Update above; only this deletion bullet survives, with the
  rationale now "absorbed into per-area STATE consolidation" rather than
  "absorbed into the two-zone task-NNN.md").
- **Consumes from work-002's feature-001-profile-driven-generator:** the
  `canonical/` source location and the generator that renders the trees.
- **Does not consume from feature-003 or feature-006:** both have been dropped
  from work-001. No hook infrastructure, no `emit-advance.sh`, no advance-signal
  record, no separate mechanical-offload mechanism is consumed.

#### Consistency with existing patterns

The refactor preserves, not replaces, the eight architecture patterns
(`architecture.md` §4): Pattern 1 (skills as state-machine orchestrators) is made
*more* explicit — the dispatch table is the state machine written down; Pattern 2
(sub-agent dispatch) is where the `Worker` column points when the per-skill
design calls for offload; Pattern 3 (reference-file decomposition) is generalized
from a Claude-Code-only habit into the canonical authoring form for every skill
on **every** tree — the host-tool research confirmed Codex and Cursor both honor
`references/` progressive disclosure, so the pattern is now genuinely universal
rather than tool-specific. No new pattern is introduced.

### Migration Plan

This is a brownfield structural change to all 10 skills. Per `tech-debt.md` H1/M5
the skills today carry full inline state machines (453–1,090 lines each) and drift
across trees. The migration runs **on `canonical/`** and is sequenced **after
work-002's feature-001-profile-driven-generator** (the generator and `canonical/`
must exist). There are no other hard sequencing constraints — with M3 dropped,
the earlier "after feature-003" gating is gone.

#### Per-skill state-extraction recipe

For each of the 10 skills, applied to `canonical/skills/aid-{name}/`:

1. **Inventory the states.** Read the current `SKILL.md`; list every `## Mode:` /
   state H2 and the `## State Detection` logic. (`aid-discover`: 6 states;
   `aid-summarize`: 10 — including the composite `DONE-IDEMPOTENT`; `aid-execute`,
   `aid-interview`: as documented.) A conditional/composite state such as
   `DONE-IDEMPOTENT` (entered only when STALE-CHECK finds nothing to do) is **not**
   given its own dispatch row — it collapses into the `DONE` row, with the
   detection logic selecting the idempotent variant of that one state-detail file.
2. **Extract each state body** into `references/state-{name}.md` with the
   `# State: {NAME}` shape from the Data Model. Move the steps verbatim — no
   rewording (this keeps behavior provably identical and the diff reviewable).
3. **Reduce SKILL.md to the router** — keep parts 1–4 (frontmatter, title,
   pre-flight, state detection); replace the removed state bodies with the
   `## Dispatch` table.
4. **Wire the dispatch table** — one row per state: `Detail` path, `Worker`
   (sub-agent name where the per-skill design calls for offload, otherwise
   `inline`), and `Advance` (`→ {NEXT-STATE-NAME}` for the normal flow, `→ halt`
   for `DONE` / `APPROVAL` / `Q&A`).
5. **Behavior-equivalence check** — diff the refactored skill's *content* against
   the original: every step must be reachable and unchanged. The pipeline must
   behave identically (REQUIREMENTS.md §9 FR3 AC5, §7).

Skills are migrated **incrementally, one at a time**. The generator is
structure-agnostic (work-002's feature-001 Migration Plan step 1): an
un-refactored skill is carried monolithic and rendered monolithic; a refactored
skill renders to the thin-router + `references/state-*.md` shape on **all three**
trees (every profile uses `references` decomposition). So the trees stay valid
and shippable after every single skill is converted — no big-bang cutover.

**Suggested order:** start with `aid-deploy` / `aid-monitor` (smallest at ~333–359
lines after the subagent-visibility-patch, identical across trees — lowest risk, fastest validation of the recipe),
then the mid-size skills, then `aid-discover` (largest, most states) last. The
exact order is `aid-plan`'s call.

#### Cross-tree and drift impact

Doing M1 uniformly on `canonical/` retires the skill-body triplication drift
(`tech-debt.md` H1, M5): there is one authored source and the generator produces
the trees. After migration, the thin-router shape inherits the post-work-002
uniform-line-count property — every skill renders byte-identically to all three
install trees, and that property extends to the per-state reference files.
(The pre-work-002 line-count divergence — 453/1,078/1,090 for aid-discover,
similar splits for other skills — was already retired by work-002's canonical
generator; M1 preserves that invariant at the per-state-file level.)

#### Backward compatibility (NFR2)

- **In-flight `.aid/` workspaces:** untouched. State detection reads the same
  disk files; a refactored skill resumes a pre-refactor workspace correctly.
- **Existing user installs:** a user re-running `setup.sh` receives the
  re-rendered trees via the installer's existing skip-identical / prompt-on-change
  behavior. No silent breakage.
- **State-to-state progression:** unchanged from today — the user re-invokes
  `/aid-{name}` between states. The refactor does not introduce, and does not
  depend on, any auto-advance mechanism.

#### Template surgery — two-zone `task-template.md` + `implementation-state.md` deletion (CR7)

> ***This subsection is superseded by the Alignment Update above. Retained as historical reference. Only the `implementation-state.md` deletion (step 3) survives — steps 1 + 2 (two-zone scaffold + `aid-detail` Execution Record write) are retired by the per-area STATE rule.***

In addition to the 10-skill router cutover, this feature performs a one-off
**template change** that the downstream features (notably feature-004) consume:

1. Extend `templates/delivery-plans/task-template.md` so a generated `task-NNN.md`
   has two explicit zones — a filled **Definition zone** (`Type`, `Source`,
   `Depends on`, `Scope`, `Acceptance Criteria`) and an **empty Execution Record
   zone scaffold** (the section headers `## Status`, `## Quick Check`,
   `## Delivery Gate`, `## Dispatches` — all empty).
2. Update `aid-detail` to write **both** zones when it creates a `task-NNN.md`:
   Definition zone filled from the plan; Execution Record zone written as empty
   scaffold. (`aid-execute` then populates Status / Quick Check / Dispatches
   during execution; feature-004 writes the `## Quick Check` and
   `## Delivery Gate` block bodies into the same scaffold.)
3. **Delete** `templates/implementation-state.md` — it is retired by the
   `task-NNN-STATE.md` → `task-NNN.md` Execution Record merge and no longer has
   a consumer. (`aid-execute`'s `templates/implementation-state.md` dispatch
   reference is removed by feature-004 as part of its `aid-execute/SKILL.md`
   edit-surface work — see feature-004 Layers & Components.)

This template work is performed **once across the install trees** under the same
canonical-source-of-truth rule as the skills.

#### Out of scope

- **Auto-advance / hook-driven chaining of any kind.** The earlier M3
  (Stop-hook auto-continue, 3-mode degradation ladder) is dropped — state-to-state
  progression is user-driven via `/aid-{name}` re-invocation.
- **A separate mechanical-offload feature.** M4 lives only as the
  per-skill authoring discipline inside the dispatch table's `Worker` column
  (see Data Model). The former feature-003 — which packaged M2 hooks and M4 as a
  standalone deliverable — is dropped from work-001.
- The human-readable `skills/` READMEs — they are not generator inputs; whether
  they are also restructured to the router shape is open question OQ-2.3.
