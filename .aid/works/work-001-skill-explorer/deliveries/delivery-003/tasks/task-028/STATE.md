---
state: Done
review: "--"
elapsed: "--"
notes: "--"
ticket_ref: "--"
---

# Task State -- task-028

[!NOTE]
This is the TASK-LEVEL STATE.md. It is **full-path only** -- it lives at
`deliveries/delivery-003/tasks/task-028/STATE.md`. The `## Task State` mutable cell
(state/review/elapsed/notes) lives in the YAML frontmatter block above; the remaining
sections (Quick Check Findings, Dispatch Log) are AUTHORED as markdown body. All of it
is written by a single writer: the delivery branch that owns this task. This file is the
SOLE write target for all per-task mutable state (state cell, review, elapsed, notes,
findings, dispatch log). Its parent `deliveries/delivery-003/STATE.md ## Tasks State` and
the work-level `## Tasks State` are DERIVED read-only views assembled from this file at
read time -- never written directly.
Lite (flattened) path has **no per-task STATE.md at all**: each task's mutable cells
live directly in the work-root `STATE.md § ### Tasks lifecycle`, written via
`writeback-state.sh --task-id` targeting that table row instead of a sibling file.
`task-028`/`delivery-003`/`work-001-skill-explorer` in the header blockquote below are INFERRED
from the folder path -- never authored in frontmatter.

Optional `ticket_ref` (frontmatter, full-path only): links this task to an external tracker item
(`<connector-stem>:<external-id>`, e.g. `jira:PROJ-123`). Left `--` when this task is not
independently linked; resolution then falls back to this task's owning (SPEC-traced) feature,
else its delivery, else the work (nearest-ancestor contract:
`.claude/aid/templates/connectors/consumption-protocol.md`). The flattened path (no per-task
STATE.md, `### Tasks lifecycle` above) carries no separate task-level `ticket_ref` of its own --
resolution for a flattened task passes straight through to its delivery/work levels, which do
carry the scalar (`work-state-template.md`'s frontmatter, both layouts). Coordinate with the
in-flight `work-003-state-schema` frontmatter conventions.

> **Task:** task-028
> **Delivery:** delivery-003
> **Work:** work-001-skill-explorer

---

## Task State

<!-- AUTHORED -- values live in the YAML frontmatter block at the top of this file
     (`state`, `review`, `elapsed`, `notes`), written ONLY by
     `writeback-state.sh --task-id NNN --field State --value VALUE` (surgical frontmatter
     rewrite; the markdown body is never touched by that write).
     State enum (closed; single source of truth):
       Pending | In Progress | In Review | Blocked | Done | Failed | Canceled
     Ordering (most-advanced wins on reconcile):
       Done > Canceled > In Review > In Progress > Blocked > Failed > Pending

     MANDATORY (aid-execute/references/state-execute.md § State-Write Protocol):
     `state` MUST be written the INSTANT it changes -- In Progress before work
     starts, In Review before the reviewer is dispatched, a terminal value
     (Done/Failed) when finished. Binds whoever executes this task -- the
     main/orchestrator agent running it directly, or a dispatched sub-agent --
     with no exception either way. (Blocked is a distinct, orchestrator-
     assigned value for a different, downstream task that depends on a failed
     one -- never self-written by the task being executed.) -->

---

## Quick Check Findings

- **Orchestrator verification before review. No defect found -- the notable thing is what the
  verification could and could not establish.**
- **The escaping is the risk this task carried**, because it is the family that produced
  delivery-002 worst shipped defect: an over-escaper that put visible entities on 70 of 111 pages,
  with a test structurally incapable of seeing it. A unit test asserting "the emitted source
  contains &amp;" passes whether a reader sees an ampersand or the literal text.
- **Settled empirically rather than by reasoning about defaults.** The site already SHIPS a
  hand-authored diagram using both constructs in one quoted label --
  `concepts/methodology.md`:43 renders `SC["aid-&lt;verb&gt;[-&lt;artifact&gt;]<br/>shortcut ..."]`.
  So entities and `<br/>` are known to render on this site, with this integration, at this Mermaid
  version (11.15.0). That matters because neither `htmlLabels` nor `mermaidConfig` is set in
  `astro.config.mjs`, and per KI-001 `astro-mermaid` forwards almost nothing anyway -- so the
  behaviour rests on a default, and the shipped precedent is better evidence than the default.
- **Rendered a probe chart carrying every character class the corpus actually contains** -- `>=`
  with `&` in one label, `ARTIFACT=""`, a backtick AND a pipe together, and the
  `aid-<verb>[-<artifact>]` pattern -- then read the output as Mermaid rather than as assertions.
  Clean: no raw ampersand outside an entity, no unbalanced quote on any line, no surviving
  backtick, and byte-identical across two calls. The lossy backtick/pipe-to-space substitution is
  contract, not improvisation -- the DETAIL specifies "any residual backtick or pipe becomes a
  space".
- **Spot-verified the mutation claim** (12 reported, 0 survivors) by removing the ampersand
  replacement: 2 tests die. The escaping is genuinely guarded.
- **Two items DEFERRED TO UI CHECKPOINT 2, neither a defect:**
  1. **`entry` and `exit` render as the SAME shape** -- both stadium `(["..."])` -- and are
     distinguished only by fill colour (green vs red). Legible in principle; worth a human eye on a
     real chart, since shape is the stronger visual cue and colour alone can fail for a
     colour-blind reader.
  2. **`classDef aidNode color:inherit` interacts with the kind classes by CSS declaration order.**
     Every node receives two class statements (`class n1 aidEntry` then `class n1 aidNode`), and
     because both land on one element with equal specificity, the winner is whichever classDef is
     declared LATER in the fence -- not the order in the class attribute. `aidNode` is emitted
     first, so the kind colours win and text stays legible on the dark fills. The reasoning holds,
     but it is exactly the kind of thing to confirm with eyes rather than with logic, and hook H3
     means the class cannot simply be dropped -- feature-006 binds to it.
---

## Dispatch Log

<!-- AUTHORED -- appended by the dispatcher on subagent completion (L1+L2+L3 traceability;
     always-on, never optional). One row per dispatch. The work-level ## Calibration Log
     and ## Dispatches views are DERIVED unions of all per-task Dispatch Log sections.
     Source: `.claude/skills/aid-discover/SKILL.md ## Dispatch Protocol`. -->

| Date | Agent | ETA Band | Actual | Outcome |
|------|-------|----------|--------|---------|
