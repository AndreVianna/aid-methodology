---
title: 'Skills'
description: 'All AID skills — 19 classic pipeline skills, the aid-triage router, the aid-ask Q&A alias, and the catalog-driven direct-entry shortcuts — grouped by skill group/family, with what each does and where it comes from.'
generatedFrom: 'canonical/skills/*/SKILL.md, canonical/aid/templates/shortcut-catalog.yml'
---

<!-- generated — do not edit; source: canonical/skills/*/SKILL.md -->

AID ships **111 skill directories** under `canonical/skills/`: **19 classic pipeline skills** across four skill groups (Support, Knowledge Base Maintenance, Definition, Execution), the suggest-only router **`/aid-triage`**, the friendly **`/aid-ask`** Q&A alias (of `/aid-query-kb`), and **64 engine-driven direct-entry shortcut skills** generated from a 94-row catalog (58 canonical names + 36 aliases); 30 of the rows (24 canonical + 6 alias) are `repurpose: true` — the 4 classic re-registered skills plus the work-005 hand-authored single-shot "collapse" skills, all hand-authored with their own directories). The six numbered phases — Discover through Execute — form the mandatory sequential full path; every skill runs as a slash command (e.g. `/aid-config`) inside your AI host tool. Classic and router skills below are generated from each skill's own definition in `canonical/skills/`; shortcuts are summarized by family from the catalog (see "Direct-entry shortcuts" below, nested inside the Definition group).

## Support

Set up the workspace and manage connectors.

### `aid-config`

**bootstrap · run once**

View or update AID pipeline settings. Bare invocation shows all values in a table; first run auto-creates .aid/settings.yml from the template. Pass a key (e.g., /aid-config name) to view + update one setting interactively.

[Definition: `canonical/skills/aid-config/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-config/SKILL.md)

### `aid-set-connector`

**on demand · upsert a connector into the catalog**

On-demand, off-pipeline upsert into the connector catalog. `aid-set-connector <tool> <type>` creates `.aid/connectors/<stem>.md` when the stem is absent, or updates that SAME descriptor in place when present (including an in-place connection_type transition) -- never invokes /aid-discover. Branches on <type> (mcp|api|ssh|cli) to ask the matching config question-set, prefilled from canonical/aid/templates/connectors/preset-catalog.md when <tool> matches a preset; the user confirms or edits. Reconciles the secret (connector-secret write/purge) per set-skill logic and runs reconcile.md's single-stem mode, so every OTHER catalogued connector is left byte-for-byte untouched.

[Definition: `canonical/skills/aid-set-connector/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-set-connector/SKILL.md)

### `aid-unset-connector`

**on demand · remove a connector from the catalog**

On-demand, off-pipeline removal from the connector catalog. `aid-unset-connector <tool>` deletes `.aid/connectors/<stem>.md` and purges its secret via connector-secret purge -- never invokes /aid-discover. Runs reconcile.md's single-stem REMOVE (purge-then-delete) so every OTHER catalogued connector is left byte-for-byte untouched, then rebuilds INDEX.md from whatever descriptors remain on disk. Idempotent: an already-absent stem is a clean no-op.

[Definition: `canonical/skills/aid-unset-connector/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-unset-connector/SKILL.md)

### `aid-read-ticket`

**on demand · non-destructive ticket fetch and display**

On-demand, non-destructive ticket read. `aid-read-ticket [<connector>:]<ticket-id>` parses the ref (an optional `<stem>:` prefix plus the tracker's own id), resolves which issue-tracker connector answers it via the shared connector-resolution ladder (explicit override; a single catalogued issue-tracker connector used silently; a choice asked when two or more are catalogued; the host tool's own tracker MCP as fallback; a "no issue-tracker connector found." notice otherwise), fetches the ticket through the host tool's own MCP -- AID resolves no credential and stores none -- and displays its fields. Never writes, locally or to the tracker, and never shows a confirmation prompt; a failed, not-found, unauthorized, or unavailable fetch surfaces the tracker's error verbatim and exits without side effects.

[Definition: `canonical/skills/aid-read-ticket/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-read-ticket/SKILL.md)

### `aid-create-ticket`

**on demand · preview + confirm before filing a ticket**

On-demand utility skill that files one new ticket via whatever issue-tracker connector the project has registered, or the host tool's own tracker MCP when none is catalogued. Parses `--connector <stem>`, `--level epic|story|task`, and `--parent <ref>` flags in any order ahead of a free-text `<description>` (create has no leading-token connector heuristic), resolves the connector via the shared ladder, composes the new-ticket payload (fixing level and parent by precedence, defaulting neither silently), resolves the canonical tier to the tracker's concrete issue-type at runtime via a non-destructive read (graceful degradation when the tracker has no matching type), previews the exact payload, and gates on one in-run AskUserQuestion confirm -- which also carries the epic|story|task pick when the level is neither explicit nor inferable -- before filing. Returns the new `<connector-stem>:<external-id>` only after the user confirms; nothing is filed, and no local file is ever written, before that.

[Definition: `canonical/skills/aid-create-ticket/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-create-ticket/SKILL.md)

### `aid-update-ticket`

**on demand · preview + confirm before mutating a ticket**

On-demand write skill that mutates exactly ONE named part of an existing ticket in whatever issue-tracker connector resolves for it: `aid-update-ticket <part> [<connector>:]<ticket-id> <content>` where `part` is the closed enum `description | comment | status`. `description` REPLACES the field, `comment` APPENDS a new comment, `status` SETS the ticket's state. Resolves the connector via the shared ticket-resolution ladder, loads whatever context the named part needs (status: the ticket's available transitions; description: its current value for a before/after preview; comment: nothing), composes the exact mutation, and shows it in an in-invocation `AskUserQuestion` confirm before the single host-MCP write. A `status` target is validated against the tracker's available transitions when the MCP can enumerate them (a mismatch lists the valid options and stops before the confirm gate); when transitions cannot be enumerated, the transition is attempted and the tracker's own error is surfaced verbatim on rejection. Never writes silently, and an MCP failure never leaves a partial write.

[Definition: `canonical/skills/aid-update-ticket/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-ticket/SKILL.md)

## Knowledge Base Maintenance

Build and keep current the team's understanding of the existing system.

### `aid-discover`

**Phase 1 · brownfield**

Brownfield project discovery with built-in quality gate. Run `/aid-config` first to scaffold the KB. Analyzes all repository content (code, configuration, and documentation) to populate KB documents. Reviews, collects user input, fixes issues, and gets user approval — one step per run. State-machine: ELICIT → GENERATE → REVIEW → Q-AND-A → FIX → APPROVAL → DONE.

[Definition: `canonical/skills/aid-discover/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-discover/SKILL.md)

### `aid-summarize`

**optional viewer**

Generate a single-file kb.html from .aid/knowledge/. Domain-driven, doc-set-based: one section per resolved doc derived from frontmatter (kb-category, objective, summary, tags, see_also). Audience: non-technical newcomer (visually rich; no KB authoring-rules leakage). Light/dark theme, click-to-expand lightbox, accessibility-first (WCAG AA). Two-grade quality gate (Machine + Human): script-verifiable checks score the Machine Grade; an interactive checklist scores the Human Grade (K1 KB-completeness, K2 fact-grounding, V1 mandatory human visual gate). APPROVAL requires BOTH grades >= minimum. Idempotent: re-running on an unchanged KB does nothing. State-machine: PREFLIGHT -> STALE-CHECK -> PROFILE -> GENERATE -> VALIDATE -> MANUAL-CHECKLIST -> FIX -> APPROVAL -> WRITEBACK -> DONE.

[Definition: `canonical/skills/aid-summarize/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-summarize/SKILL.md)

### `aid-housekeep`

**on demand**

Optional on-demand housekeeping skill. Runs three gated jobs in strict order: KB-DELTA (re-discover changed docs since last KB approval; brownfield docs take the doc<-code drift path, while source: forward-authored greenfield docs take the Conformance Lane -- a code->design shadow-extract that FLAGS design vs as-built divergence for human reconciliation and never auto-overwrites the design) → SUMMARY-DELTA (regenerate the visual summary if the KB changed) → CLEANUP (sweep stale work-area artifacts). Each stage commits its own changes on an aid/housekeep-* branch; the skill never pushes. Re-entrant: a stalled run resumes at the stalled stage on re-invocation. State-machine: PREFLIGHT → KB-DELTA → SUMMARY-DELTA → CLEANUP → DONE. Source-driven global reconcile; for a targeted prompt-named delta use /aid-update-kb.

[Definition: `canonical/skills/aid-housekeep/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-housekeep/SKILL.md)

### `aid-update-kb`

**on demand · targeted KB update**

Optional on-demand targeted KB update skill. Isolates itself in its own worktree, analyzes how a free-form instruction lands in the Knowledge Base (an aid-researcher Impact Map), turns that into a minimal aid-architect Scope Plan traced to the instruction (+ an explicit Not-Changing list), and pauses for an explicit human CONFIRM before any edit. Applies only the confirmed scope, reviews it through f005's four-mandate panel (scoped to the changed docs), and commits only after a second explicit human approval. State-machine: ANALYZE -> SCOPE -> CONFIRM -> APPLY -> REVIEW -> APPROVAL -> DONE (FIX loop inside REVIEW).

[Definition: `canonical/skills/aid-update-kb/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-kb/SKILL.md)

### `aid-query-kb`

**on demand · read-only Q&A**

Optional on-demand Q&A skill. Takes a free-form question and answers it in one pass, grounded in three context sources: the Knowledge Base (.aid/knowledge/), the live codebase, and in-flight AID works (.aid/works/work-*/STATE.md + progress). Returns an answer with source citations (KB doc names, file paths, or work-NNN STATE references). When the available context cannot answer the question, states the gap explicitly rather than fabricating an answer AND captures the gap as a Query-Gap entry in the STATE.md Q&A (Pending) backlog so it feeds the KB-improvement loop. Trivial questions are answered inline (Read/Glob/Grep only); broad or expensive investigations dispatch aid-researcher in strictly read-only mode. Writes are restricted to appending a Query-Gap entry to a STATE.md Q&A (Pending) section; no KB doc, settings, or code file is ever written.

[Definition: `canonical/skills/aid-query-kb/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-query-kb/SKILL.md)

### `aid-ask`

**on demand · friendly alias of aid-query-kb**

Friendly-named alias of /aid-query-kb -- the optional on-demand Q&A skill. Takes a free-form question and answers it in one pass, grounded in three context sources: the Knowledge Base (.aid/knowledge/), the live codebase, and in-flight AID works (.aid/works/work-*/STATE.md + progress). Returns an answer with source citations. When the available context cannot answer the question, states the gap explicitly and captures it as a Query-Gap entry so it feeds the KB-improvement loop. This file carries no logic of its own -- its full behavior is defined entirely by canonical/skills/aid-query-kb/SKILL.md, which this skill delegates to.

[Definition: `canonical/skills/aid-ask/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-ask/SKILL.md)

## Definition

Route, gather requirements, decide how to solve it, sequence the roadmap, and break it into tasks — the full path, or a shortcut.

### `aid-triage`

**router · suggest-only**

Suggest-only router for "I don't know which entry fits." Captures one short free-form description, infers the work type and judges scope, then suggests the single best entry: the matching aid-<verb>[-<artifact>] shortcut for a known single change-type, or the full path via /aid-describe for broad or ambiguous work. Reads canonical/aid/templates/shortcut-catalog.yml to resolve the suggestion to a canonical (non-alias) name. Routes and suggests only -- no interview, no scaffold, no work folder, no STATE.md. State machine: INTAKE -> CLASSIFY -> SUGGEST -> HALT.

[Definition: `canonical/skills/aid-triage/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-triage/SKILL.md)

### `aid-describe`

**Phase 2a · full path only**

Conversational requirements gathering through adaptive interview, driven by the seasoned-analyst elicitation engine (references/elicitation-engine.md): one fixed D1 opener plus a deterministic five-step next-move selector (stop check, gap selection, move selection, calibration shaping, NFR-7 envelope + emit). First run builds REQUIREMENTS.md incrementally. Subsequent runs resume the interview for incomplete sections. Final step presents approved requirements for handoff to /aid-define. State machine: FIRST-RUN -> Q-AND-A -> CONTINUE -> {greenfield: DESCRIBE-SEED ->} COMPLETION [PAUSE -> /aid-define].

[Definition: `canonical/skills/aid-describe/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-describe/SKILL.md)

### `aid-define`

**Phase 2b · full path only · decompose features**

Feature decomposition and cross-reference validation from approved requirements. Begins from an approved REQUIREMENTS.md (produced by /aid-describe) and decomposes functional requirements into discrete feature folders with SPEC.md stubs (FEATURE-DECOMPOSITION), then validates the requirements and feature boundaries against the KB and codebase (CROSS-REFERENCE), then halts at DONE ready for /aid-specify. State machine: (Approved REQUIREMENTS) -> FEATURE-DECOMPOSITION -> CROSS-REFERENCE -> DONE [HALT -> /aid-specify].

[Definition: `canonical/skills/aid-define/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-define/SKILL.md)

### `aid-specify`

**Phase 3 · full path only**

Technical specification through conversational refinement, one feature at a time. The agent acts as a tech lead — reads KB, Requirements, and codebase, proposes technical solutions, and builds the spec collaboratively with the user. Writes to SPEC.md in the feature folder. State machine: INITIALIZE → CONTINUE → REVIEW → DONE (SPIKE / BLOCKED are loopback states that return to CONTINUE).

[Definition: `canonical/skills/aid-specify/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-specify/SKILL.md)

### `aid-plan`

**Phase 4 · full path only**

Sequence feature SPECs into deliverables — each one a functional MVP that builds on the previous. Strategy, not tactics. Use when feature SPECs are complete and you need a delivery roadmap. State machine: FIRST-RUN → REVIEW → DONE.

[Definition: `canonical/skills/aid-plan/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-plan/SKILL.md)

### `aid-detail`

**Phase 5 · full path only**

Break deliverables into small, dependency-driven, typed tasks — each one a reviewable unit. The ultimate breakdown. Detects task types (RESEARCH, DESIGN, IMPLEMENT, TEST, DOCUMENT, MIGRATE, REFACTOR, CONFIGURE) from SPEC signals. One type per task. Builds execution graph per delivery with explicit dependencies and parallelism. State machine: FIRST-RUN → REVIEW → DONE.

[Definition: `canonical/skills/aid-detail/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-detail/SKILL.md)

### Direct-entry shortcuts

**64 engine-driven verb-first shortcut skills** — a fast, mostly-autonomous alternative to the full Describe→Detail path for a single, well-scoped change. Each is a thin doorway generated from one non-`repurpose` row of [`canonical/aid/templates/shortcut-catalog.yml`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/shortcut-catalog.yml) (94 rows total; the other 30 are `repurpose: true` — the 4 classic re-registered skills (`aid-deploy`/`aid-monitor`/`aid-query-kb`/`aid-ask`) plus the work-005 hand-authored single-shot "collapse" skills, all hand-authored with their own directory).

Every engine-driven shortcut delegates to the shared **shortcut engine** — [`canonical/aid/templates/shortcut-engine.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/shortcut-engine.md) — which collapses the five definition phases (Describe → Detail) into one mostly-autonomous run:

```
INTAKE → CAPTURE → SPEC → PLAN → DETAIL → GATE → APPROVAL-HALT
```

CAPTURE/SPEC/PLAN/DETAIL run without a per-phase human checkpoint (unlike the full path's Propose→Discuss→Write→Review loops); the only interactive moments are a rare CAPTURE gap-question and the terminal APPROVAL-HALT. GATE grades every generated document mechanically against the project's minimum grade before halting. The engine never executes — `/aid-execute` is a separate, user-initiated run after approval. Not sure which shortcut fits your change? `/aid-triage` reads this same catalog and suggests exactly one.

| Family | Count | Forms |
|--------|-------|-------|
| Create (+ `add` alias) | 29 | 14 canonical `aid-create*` forms + 15 `aid-add*` aliases |
| Change (+ `update` alias) | 28 | 14 canonical `aid-change*` forms + 14 `aid-update*` aliases |
| Fix | 1 | `aid-fix` — diagnose and correct a defect, regression, incident, or vulnerability; no alias |
| Refactor | 1 | `aid-refactor` — restructure or optimize without changing behavior; no alias |
| Test + Experiment | 1 | `aid-test` + 3 typed forms (security, performance, data-quality) = 0, plus `aid-experiment`; no alias |
| Prototype | 0 | `aid-prototype`, `aid-prototype-ui`; no alias |
| Document | 0 | `aid-document` + -1 typed forms (decision, architecture, guideline, standard, runbook, tutorial, changelog); no alias |
| Report | 0 | `aid-report` — analyze data or usage and communicate insight; no alias |
| Show dashboard | 0 | `aid-show-dashboard` — build a durable dashboard or BI view; no alias |
| Remove (+ `delete` alias) | 2 | 1 canonical `aid-remove` form + 1 `aid-delete` alias |
| Deprecate | 1 | `aid-deprecate` — mark an artifact/API deprecated, add warnings and a migration path, without deleting yet; no alias |
| Migrate | 1 | `aid-migrate` — migrate data, a dependency, framework, or platform, with a rollback plan; no alias |
| Review (+ `audit` alias) | 0 | 0 canonical `aid-review` form + 0 `aid-audit` alias |
| Research (+ `investigate`/`spike` aliases) | 0 | 0 canonical `aid-research` form + 0 `aid-investigate`/`aid-spike` aliases |
| **Total** | **64** | |

### `aid-deploy`

**optional shortcut path · on demand**

Package completed deliveries into a release. Selects eligible deliveries, verifies the combined build, packages according to project infrastructure, generates release notes, and updates artifact statuses. Use when deliveries are complete and ready to ship. State machine: IDLE → SELECTING → VERIFYING → PACKAGING → DONE.

[Definition: `canonical/skills/aid-deploy/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-deploy/SKILL.md)

### `aid-monitor`

**optional shortcut path · on demand**

Observe production, classify findings, and route actions. Combines telemetry interpretation with triage — detect anomalies, perform root cause analysis for bugs, and route findings — bugs to /aid-fix, change requests to /aid-triage. Per-work scope. Use post-deployment, on schedule, or on-demand. State machine: OBSERVE → CLASSIFY → ROUTE → DONE.

[Definition: `canonical/skills/aid-monitor/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-monitor/SKILL.md)

## Execution

Build, review, and test.

### `aid-execute`

**Phase 6 · 8 task types · graded loop**

Execute a task based on its type: RESEARCH, DESIGN, IMPLEMENT, TEST, DOCUMENT, MIGRATE, REFACTOR, or CONFIGURE. Built-in review loop per type. State machine: EXECUTE → REVIEW → FIX → back to REVIEW → DONE when grade ≥ minimum. Branch per delivery for isolation.

[Definition: `canonical/skills/aid-execute/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-execute/SKILL.md)

