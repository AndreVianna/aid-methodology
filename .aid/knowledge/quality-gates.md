---
kb-category: extension
source: hand-authored
objective: The methodology's review-and-grade gates — the deterministic A-grade gating, the reviewer ledger, per-phase REVIEW→FIX loops, minimum-grade thresholds, and the discover review panel — that AID's own work must pass before advancing.
summary: Read this to understand how AID grades the artifacts its pipeline produces (KB docs, specs, plans, tasks, code, releases) — distinct from the automated test suites in test-landscape.md. Covers the grade scale, the 7-column reviewer ledger, grade.sh, minimum-grade resolution, and which gates block vs advise.
sources:
  - .claude/aid/scripts/grade.sh
  - .claude/aid/templates/reviewer-ledger-schema.md
  - .claude/aid/templates/grading-rubric.md
  - .claude/aid/templates/reviewer-dispatch.md
  - .aid/settings.yml
  - .claude/skills/aid-discover/references/state-review.md
  - .claude/skills/aid-execute/references/state-delivery-gate.md
tags: [C6, quality-gates, review, grading, ledger, gates]
see_also: [test-landscape.md, authoring-conventions.md, pipeline-contracts.md]
owner: architect
audience: [developer, architect, pm]
intent: |
  The methodology's quality gates: A-grade gating, the reviewer agent + 7-column
  ledger, per-phase REVIEW loops, the A+..F scale, minimum-grade thresholds, the
  review->fix->re-review loop, and the discover review panel. Distinct from the
  automated tests in test-landscape.md.
contracts:
  - "Grade is computed ONLY from reviewer-ledger rows where Status in {Pending, Recurred}, by Severity column"
  - "Worst severity dominates; count within it sets the modifier (1 -> +, 2-5 -> none, 6+ -> -)"
  - "A skill exits REVIEW only when grade >= the resolved minimum_grade (per-skill override -> review.minimum_grade -> hardcoded A)"
  - "Every reviewer ledger is exactly one 7-column markdown table at .aid/.temp/review-pending/<scope>.md — no narrative"
changelog:
  - 2026-06-25: Initial discovery (aid-discover quality deep-dive)
---

# Quality Gates

AID grades **its own work**. Every pipeline phase that produces an artifact — a KB doc, a
spec, a plan, a task decomposition, code, a release bundle — runs a REVIEW state that
assigns a letter grade, and the phase may not advance until the grade clears a configured
bar. This is a separate mechanism from the automated test suites (those gate the *shipped
product* and live in `test-landscape.md`); the gates here govern the *methodology's
deliverables*.

## Contents

- [The Two Layers of Checking](#the-two-layers-of-checking)
- [The Grade Scale](#the-grade-scale)
- [The Reviewer Ledger](#the-reviewer-ledger)
- [How the Grade Is Computed](#how-the-grade-is-computed)
- [Minimum-Grade Thresholds](#minimum-grade-thresholds)
- [The Per-Phase REVIEW to FIX Loop](#the-per-phase-review-to-fix-loop)
- [The Discover Review Panel](#the-discover-review-panel)
- [The Delivery Gate (aid-execute)](#the-delivery-gate-aid-execute)
- [Mechanical Gates Run by the Orchestrator](#mechanical-gates-run-by-the-orchestrator)
- [Blocking vs Advisory](#blocking-vs-advisory)
- [Validation Commands](#validation-commands)
- [Change Log](#change-log)

---

## The Two Layers of Checking

| Layer | What it checks | How it runs | Where documented |
|---|---|---|---|
| Automated tests | The shippable product (CLI, render, dashboard, site) | `tests/run-all.sh` + GitHub Actions | `test-landscape.md` |
| Quality gates (this doc) | The methodology's own artifacts (KB, specs, plans, tasks, code, releases) | A dispatched reviewer agent + `grade.sh`, looped per phase | here |

The defining trait of the quality-gate layer: the grade is **deterministic**. The reviewer
*classifies* findings by severity; the grade *follows automatically* from a count, so two
reviewers with the same findings produce the same grade. CONFIRMED in
`.claude/aid/templates/grading-rubric.md` ("Grade is **deterministic**").

---

## The Grade Scale

A single universal rubric applies to every phase (KB docs, requirements, specs, code —
everything). CONFIRMED in `.claude/aid/templates/grading-rubric.md` (Grade Calculation table).

| Grade | Worst issue present | Quantity rule |
|---|---|---|
| A+ | None | Zero findings |
| A / A- | Minor | 1-5 minors / >5 minors |
| B+ / B / B- | Low | 1 / 2-5 / >5 lows |
| C+ / C / C- | Medium | 1 / 2-5 / >5 mediums |
| D+ / D / D- | High | 1 / 2-5 / >5 highs |
| E+ / E / E- | Critical | 1 / 2-5 / >5 criticals |
| F | Non-functional | Does not build/run or produces no usable output |

**Ordering:** `A+ > A > A- > B+ > B > B- > C+ > C > C- > D+ > D > D- > E+ > E > E- > F`.

**Two rules that drive everything:**
- **Worst severity dominates.** 3 minors + 1 medium = C+, not A.
- **Count sets the modifier within a severity:** exactly 1 → `+`; 2-5 → none; 6+ → `-`
  (CONFIRMED in `grade.sh` `modifier_for_count`).

Severity meanings (from the rubric): Minor = cosmetic; Low = works-but-deviates; Medium =
incorrect non-critical behavior / missing edge case; High = blocks functionality / security
/ data integrity; Critical = system failure / data loss / fundamentally wrong approach.

---

## The Reviewer Ledger

Every review — dispatched sub-agent, script validator, or ad-hoc user-prompted — writes its
findings to a single canonical artifact: a **7-column markdown table** and nothing else.
CONFIRMED in `.claude/aid/templates/reviewer-ledger-schema.md`.

```
| # | Severity | Status | Doc | Line | Description | Evidence |
```

- **Path:** `.aid/.temp/review-pending/<scope>.md`, where `<scope>` names the skill (and
  optionally work-item/task) so per-skill ledgers do not collide (e.g. `discovery.md`,
  `execute-task-NNN.md`, `plan.md`). The directory is gitignored — ledgers are local-only.
- **Contents:** the table is the *entire file*. No frontmatter, no headings, no summary
  section. A `## Summary` line that quotes severity tags is forbidden — it caused the
  "cycle-7" over-count bug where prose tags inflated the grade.
- **Severity enum (bracketed):** `[CRITICAL] | [HIGH] | [MEDIUM] | [LOW] | [MINOR]`. Brackets
  keep the tag from colliding with bare numbers elsewhere.
- **Status enum (plain word):** `Pending | Fixed | Recurred | Accepted | OOS | Invalid`.

| Status | Counts toward grade? | Meaning |
|---|---|---|
| `Pending` | **Yes** | Issue exists; needs fixing (reviewer at first discovery) |
| `Recurred` | **Yes** | Was Fixed earlier, came back — effectively Pending again |
| `Fixed` | No | Reviewer confirmed resolved this cycle (kept for audit) |
| `Accepted` | No | Decided not to fix; rationale + authorizer recorded (orchestrator + user) |
| `OOS` | No | Out of scope per the review rubric |
| `Invalid` | No | Reviewer was wrong; original claim was correct on disk |

**Separation of concerns (a load-bearing invariant):** the *reviewer* sets/updates Status;
the *fixer* addresses Pending/Recurred rows but **never** marks a row `Fixed` (that is the
next reviewer's job); the *orchestrator* runs `grade.sh`, may set `Accepted`/`Invalid` with
user authorization, and deletes the ledger at skill DONE. CONFIRMED in the schema's
"Authoring rules" sections.

---

## How the Grade Is Computed

`.claude/aid/scripts/grade.sh` reads the ledger as a markdown table and counts findings by
the **Severity column only**, filtered to rows whose **Status column** is `Pending` or
`Recurred`. CONFIRMED in `grade.sh` (schema-table parsing path).

Critically, `grade.sh` parses by *column position* (Severity = `cols[3]`, Status =
`cols[4]`), and only matches the bracketed enum exactly — severity-looking text in the
Description/Evidence columns is ignored. It never greps prose. This is the fix for the
cycle-7 over-count bug.

Edge cases (CONFIRMED in the schema): empty ledger (no rows) = A+; zero-byte file = A+; no
file at all = A+ for the artifact (but the orchestrator must not advance past REVIEW without
a ledger — the reviewer must create one). A `--non-functional` flag forces `F`.

---

## Minimum-Grade Thresholds

A phase exits REVIEW only when its grade is **at least** the configured minimum. The bar is
resolved in three tiers (CONFIRMED in `.claude/aid/templates/grading-rubric.md`):

1. per-skill override (e.g. `summary.minimum_grade`, `execute.minimum_grade`) →
2. global `review.minimum_grade` →
3. hardcoded default `A`.

Resolution command:

```bash
bash .claude/aid/scripts/config/read-setting.sh --skill <name> --key minimum_grade --default A
```

In **this** repo (`.aid/settings.yml`): the global `review.minimum_grade` is `A`, and there
is one active per-skill override — `summary.minimum_grade: A+` (the `/aid-summarize`
redesign is held to A+). The commented examples show other skills can be pinned similarly
(e.g. `execute`, `deploy` → A+). CONFIRMED in `.aid/settings.yml`.

---

## The Per-Phase REVIEW to FIX Loop

Every grading phase runs the same loop: REVIEW (classify → ledger → grade) → if grade <
minimum, FIX (address Pending/Recurred) → REVIEW again (re-verify, update Status, append
new findings) → repeat until grade ≥ minimum. CONFIRMED across the per-skill
`references/state-review.md` files and `reviewer-ledger-schema.md` (Lifecycle section).

Two safeguards stop infinite loops:
- **Loop detection:** the same grade across three cycles signals a systemic issue, not a
  retry-fixable one (stated in `grading-rubric.md` "Why This Scale").
- **Circuit breaker:** the delivery gate has an explicit `CIRCUIT-BREAKER-STOP` after 3
  cycles with no improvement (CONFIRMED in `state-delivery-gate.md` state machine).

The dispatched reviewer always receives a scoped brief with exactly 5 sections — `ARTIFACTS
UNDER REVIEW`, `CONTEXT`, `RUBRIC`, plus deliverable/scope rules — to prevent scope leak
inflating findings. CONFIRMED in `.claude/aid/templates/reviewer-dispatch.md`.

---

## The Discover Review Panel

`/aid-discover` (which produced this KB) does not run a single reviewer — it dispatches a
**panel** of mandates, chosen by the `review.panel` parameter set at triage. CONFIRMED in
`.claude/skills/aid-discover/references/state-review.md`.

| `review.panel` value | Path | Dispatches |
|---|---|---|
| `full` | brownfield-large (this project) | 4 parallel mandate dispatches |
| `collapsed` | brownfield-small | 3 dispatches (sequential-passes reviewer + clean-context teach-back + clean-context act-back) |
| (none) | greenfield | never reaches the panel |

Before dispatch, the orchestrator runs deterministic oracles that feed the mandates:
- `closure-check.sh` — emits the `sources:`-anchored per-doc coverage table (consumed by the
  Anatomy mandate's coverage-gap/altitude judgments) and the ungrounded-term termination
  oracle.
- `kb-dual-intent-probes.sh essence` — the Intent-2 (Blind Reconstruction + Source
  Confrontation) teach-back probe set, derived from the project's own C4/C9/D docs.
- `kb-dual-intent-probes.sh work` + `kb-actback-task.sh check` — the Intent-1 (Blind
  Work-Simulation / assertiveness) work-probe set + the operational-structure presence check,
  spine-keyed to whatever doc realizes each load-bearing dimension (C5→Contracts,
  C3→Conventions, C2→Parts, C7→Gotchas).

These oracles degrade gracefully (emit empty output, not an error) when their inputs are
absent. CONFIRMED in `state-review.md`.

---

## The Delivery Gate (aid-execute)

`/aid-execute` adds a second tier on top of per-task REVIEW: a **per-delivery** gate that
runs once after all tasks in a delivery reach `Done`. CONFIRMED in
`.claude/skills/aid-execute/references/state-delivery-gate.md`.

Its state machine: `AGGREGATE → SCORE → REVIEW → GRADE → ROUTE`; if grade ≥ minimum →
`RECORD → DELIVERY-DONE`; if grade < minimum → `FIX` and loop back to REVIEW; after 3 cycles
with no improvement → `CIRCUIT-BREAKER-STOP`.

**Interlock (invariant):** the delivery gate MUST NOT run while any task in the delivery has
status `Failed` or `Blocked` — the pool-dispatch guard (PD-5) ensures all tasks are `Done`
before the gate is entered.

---

## Mechanical Gates Run by the Orchestrator

Some checks are scripts (not a reviewer agent) that the orchestrator gates on directly, so a
defect is caught at GENERATE rather than one phase later at REVIEW:

| Gate | Script | What it enforces |
|---|---|---|
| Citation lint | `.claude/aid/scripts/kb/kb-citation-lint.sh` | No volatile bare `file.ext:LINE` citations in KB docs (durable anchors required) |
| Frontmatter lint | `.claude/aid/scripts/kb/lint-frontmatter.sh` | Required KB frontmatter fields present |
| INDEX freshness | `.claude/aid/scripts/kb/build-kb-index.sh` | `INDEX.md` matches a fresh regeneration |
| Spine closure | `.claude/aid/scripts/kb/closure-check.sh` | Every load-bearing concept is grounded or dismissed |
| Version sync | `.claude/aid/scripts/release/check-version-sync.sh` | All version carriers agree (release gate) |

These also run in CI's `kb-hygiene` job for this repo (CONFIRMED in
`.github/workflows/test.yml`), making them blocking for merges to master.

---

## Blocking vs Advisory

| Gate | Blocking or advisory? | Override path |
|---|---|---|
| Per-phase grade < `minimum_grade` | **Blocking** — phase cannot advance | Lower `minimum_grade` in `.aid/settings.yml`, or orchestrator marks specific findings `Accepted` with explicit user authorization (recorded in the ledger Evidence) |
| Delivery gate grade | **Blocking** (with 3-cycle circuit breaker → STOP, not auto-pass) | Same `Accepted` path; human decides at the circuit breaker |
| Citation / frontmatter / INDEX / version-sync scripts | **Blocking** in `kb-hygiene` / release `gate` CI | Fix the source; there is no skip flag |
| `visual-fidelity` Playwright gate | Blocking *when `kb.html` exists*; SKIPs (advisory) when absent | Generate the summary, or leave unbuilt |
| Loop-detection (same grade ×3) | **Advisory signal** → escalates to human judgment | Human decides: accept, re-scope, or abandon |

The only sanctioned way to pass a finding without fixing it is `Status: Accepted`, and that
requires **user authorization recorded in the ledger** — the orchestrator cannot self-accept.
CONFIRMED in `reviewer-ledger-schema.md` (Status values + orchestrator rules).

---

## Validation Commands

```bash
# Compute the grade from a reviewer ledger (with count breakdown)
bash .claude/aid/scripts/grade.sh --explain .aid/.temp/review-pending/<scope>.md

# Resolve the minimum grade for a skill
bash .claude/aid/scripts/config/read-setting.sh --skill discover --key minimum_grade --default A

# Mechanical KB gates the orchestrator runs
bash .claude/aid/scripts/kb/kb-citation-lint.sh --root .aid/knowledge
bash .claude/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge
bash .claude/aid/scripts/kb/build-kb-index.sh --root .aid/knowledge --output /tmp/INDEX.regen.md

# Force F for a non-functional artifact (build/run failed)
bash .claude/aid/scripts/grade.sh --non-functional
```

---

## Change Log

| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.0 | 2026-06-25 | aid-discover | Initial quality-gates analysis (custom C6 doc, quality deep-dive) |
