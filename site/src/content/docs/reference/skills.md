---
title: 'Skills'
description: 'All 14 AID pipeline skills — grouped by pipeline phase, with what each does and where its definition lives.'
generatedFrom: 'canonical/skills/*/SKILL.md'
---

<!-- generated — do not edit; source: canonical/skills/*/SKILL.md -->

AID ships **14 user-facing skills** across five pipeline groups, plus three off-pipeline on-demand skills. The six numbered phases — Discover through Execute — form the mandatory sequential pipeline; every skill runs as a slash command (e.g. `/aid-config`) inside your AI host tool. Each entry below is generated from the skill's own definition in `canonical/skills/`.

## Prepare

Set up the workspace and understand the system.

### `aid-config`

**bootstrap · run once**

View or update AID pipeline settings. Bare invocation shows all values in a table; first run auto-creates .aid/settings.yml from the template. Pass a dotted key (e.g., /aid-config project.name) to view + update one setting interactively.

[Definition: `canonical/skills/aid-config/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-config/SKILL.md)

### `aid-discover`

**Phase 1 · brownfield**

Brownfield project discovery with built-in quality gate. Run `/aid-config` first to scaffold the KB. Analyzes all repository content (code, configuration, and documentation) to populate KB documents. Reviews, collects user input, fixes issues, and gets user approval — one step per run. State-machine: GENERATE → REVIEW → Q-AND-A → FIX → APPROVAL → DONE.

[Definition: `canonical/skills/aid-discover/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-discover/SKILL.md)

### `aid-summarize`

**optional viewer**

Generate a single-file kb.html from .aid/knowledge/. Domain-driven, doc-set-based: one section per resolved doc derived from frontmatter (kb-category, objective, summary, tags, see_also). Audience: non-technical newcomer (visually rich; no KB authoring-rules leakage). Light/dark theme, click-to-expand lightbox, accessibility-first (WCAG AA). Two-grade quality gate (Machine + Human): script-verifiable checks score the Machine Grade; an interactive checklist scores the Human Grade (K1 KB-completeness, K2 fact-grounding, V1 mandatory human visual gate). APPROVAL requires BOTH grades >= minimum. Idempotent: re-running on an unchanged KB does nothing. State-machine: PREFLIGHT -> STALE-CHECK -> PROFILE -> GENERATE -> VALIDATE -> MANUAL-CHECKLIST -> FIX -> APPROVAL -> WRITEBACK -> DONE.

[Definition: `canonical/skills/aid-summarize/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-summarize/SKILL.md)

## Define

Define the problem and how to solve it.

### `aid-describe`

**Phase 2a · TRIAGE → full or lite**

Conversational requirements gathering through adaptive interview, driven by the seasoned-analyst elicitation engine (references/elicitation-engine.md): one fixed D1 opener plus a deterministic five-step next-move selector (stop check, gap selection, move selection, calibration shaping, NFR-7 envelope + emit). First run builds REQUIREMENTS.md incrementally. Subsequent runs resume the interview for incomplete sections. Final step presents approved requirements for handoff to /aid-define. State machine: FIRST-RUN -> Q-AND-A -> TRIAGE -> {full: CONTINUE -> {greenfield: DESCRIBE-SEED ->} COMPLETION [PAUSE -> /aid-define] | lite: CONDENSED-INTAKE -> TASK-BREAKDOWN -> LITE-REVIEW -> LITE-DONE}.

[Definition: `canonical/skills/aid-describe/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-describe/SKILL.md)

### `aid-define`

**Phase 2b · full path only · decompose features**

Feature decomposition and cross-reference validation from approved requirements. Begins from an approved REQUIREMENTS.md (produced by /aid-describe) and decomposes functional requirements into discrete feature folders with SPEC.md stubs (FEATURE-DECOMPOSITION), then validates the requirements and feature boundaries against the KB and codebase (CROSS-REFERENCE), then halts at DONE ready for /aid-specify. State machine: (Approved REQUIREMENTS) -> FEATURE-DECOMPOSITION -> CROSS-REFERENCE -> DONE [HALT -> /aid-specify].

[Definition: `canonical/skills/aid-define/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-define/SKILL.md)

### `aid-specify`

**Phase 3 · full path only**

Technical specification through conversational refinement, one feature at a time. The agent acts as a tech lead — reads KB, Requirements, and codebase, proposes technical solutions, and builds the spec collaboratively with the user. Writes to SPEC.md in the feature folder. State machine: INITIALIZE → CONTINUE → REVIEW → DONE (SPIKE / BLOCKED are loopback states that return to CONTINUE).

[Definition: `canonical/skills/aid-specify/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-specify/SKILL.md)

## Map

Turn requirements into an executable task list.

### `aid-plan`

**Phase 4 · full path only**

Sequence feature SPECs into deliverables — each one a functional MVP that builds on the previous. Strategy, not tactics. Use when feature SPECs are complete and you need a delivery roadmap. State machine: FIRST-RUN → REVIEW → DONE.

[Definition: `canonical/skills/aid-plan/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-plan/SKILL.md)

### `aid-detail`

**Phase 5 · full path only**

Break deliverables into small, dependency-driven, typed tasks — each one a reviewable unit. The ultimate breakdown. Detects task types (RESEARCH, DESIGN, IMPLEMENT, TEST, DOCUMENT, MIGRATE, REFACTOR, CONFIGURE) from SPEC signals. One type per task. Builds execution graph per delivery with explicit dependencies and parallelism. State machine: FIRST-RUN → REVIEW → DONE.

[Definition: `canonical/skills/aid-detail/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-detail/SKILL.md)

## Execute

Build, review, and test.

### `aid-execute`

**Phase 6 · 8 task types · graded loop**

Execute a task based on its type: RESEARCH, DESIGN, IMPLEMENT, TEST, DOCUMENT, MIGRATE, REFACTOR, or CONFIGURE. Built-in review loop per type. State machine: EXECUTE → REVIEW → FIX → back to REVIEW → DONE when grade ≥ minimum. Branch per delivery for isolation.

[Definition: `canonical/skills/aid-execute/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-execute/SKILL.md)

## Deliver (optional)

Optionally ship, monitor, and route what breaks back into the pipeline.

### `aid-deploy`

**optional · on demand**

Package completed deliveries into a release. Selects eligible deliveries, verifies the combined build, packages according to project infrastructure, generates release notes, and updates artifact statuses. Use when deliveries are complete and ready to ship. State machine: IDLE → SELECTING → VERIFYING → PACKAGING → DONE.

[Definition: `canonical/skills/aid-deploy/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-deploy/SKILL.md)

### `aid-monitor`

**optional · on demand**

Observe production, classify findings, and route actions. Combines telemetry interpretation with triage — detect anomalies, perform root cause analysis for bugs, and route findings to aid-describe (bugs via its lite bug-fix triage; change requests as new/changed requirements). Per-work scope. Use post-deployment, on schedule, or on-demand. State machine: OBSERVE → CLASSIFY → ROUTE → DONE.

[Definition: `canonical/skills/aid-monitor/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-monitor/SKILL.md)

## Off-pipeline

On-demand skills, outside the numbered phases.

### `aid-housekeep`

**on demand**

Optional on-demand housekeeping skill. Runs three gated jobs in strict order: KB-DELTA (re-discover changed docs since last KB approval; brownfield docs take the doc<-code drift path, while source: forward-authored greenfield docs take the Conformance Lane -- a code->design shadow-extract that FLAGS design vs as-built divergence for human reconciliation and never auto-overwrites the design) → SUMMARY-DELTA (regenerate the visual summary if the KB changed) → CLEANUP (sweep stale work-area artifacts). Each stage commits its own changes on an aid/housekeep-* branch; the skill never pushes. Re-entrant: a stalled run resumes at the stalled stage on re-invocation. State-machine: PREFLIGHT → KB-DELTA → SUMMARY-DELTA → CLEANUP → DONE. Source-driven global reconcile; for a targeted prompt-named delta use /aid-update-kb.

[Definition: `canonical/skills/aid-housekeep/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-housekeep/SKILL.md)

### `aid-query-kb`

**on demand · read-only Q&A**

Optional on-demand Q&A skill. Takes a free-form question and answers it in one pass, grounded in three context sources: the Knowledge Base (.aid/knowledge/), the live codebase, and in-flight AID works (.aid/work-*/STATE.md + progress). Returns an answer with source citations (KB doc names, file paths, or work-NNN STATE references). When the available context cannot answer the question, states the gap explicitly rather than fabricating an answer AND captures the gap as a Query-Gap entry in the STATE.md Q&A (Pending) backlog so it feeds the KB-improvement loop. Trivial questions are answered inline (Read/Glob/Grep only); broad or expensive investigations dispatch aid-researcher in strictly read-only mode. Writes are restricted to appending a Query-Gap entry to a STATE.md Q&A (Pending) section; no KB doc, settings, or code file is ever written.

[Definition: `canonical/skills/aid-query-kb/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-query-kb/SKILL.md)

### `aid-update-kb`

**on demand · targeted KB update**

Optional on-demand targeted KB update skill. Takes a free-form prompt describing what changed and applies the delta through the same review/calibration gate as aid-discover. Analyzes which KB docs the prompt implies, applies targeted summary+pointer edits, reviews them through f005's five-mandate panel (scoped to the changed docs), and commits only after explicit human approval. State-machine: ANALYZE -> APPLY -> REVIEW -> APPROVAL -> DONE (FIX loop inside REVIEW).

[Definition: `canonical/skills/aid-update-kb/SKILL.md`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-update-kb/SKILL.md)
