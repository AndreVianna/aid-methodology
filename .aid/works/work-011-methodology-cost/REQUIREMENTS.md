# Requirements

- **Name:** Methodology Cost Reduction
- **Description:** Reduce AID's token cost per work without weakening the grounding, instruction, and adversarial-review guarantees the methodology exists to provide.

## 1. Objective

AID's cost per work is dominated by review gates and by artifact size, not by the
work itself. A modelled full-path work at this project's observed averages
(3-4 features, 4-5 deliveries, 16-25 tasks, 5-7 review cycles per gate) spends
the large majority of its budget on review gates and roughly an eighth on the
grounding reads those gates exist to check.

Reduce that, while keeping the three things the harness is for: the Knowledge
Base as grounding, clear instructions for what to build, and adversarial review
of what was built.

**That last paragraph is the intent, and it does not change.** The figures below do,
because the ground moved: four works merged into this branch while it was open, one of
them (`work-012`) attacking the same review loop from the other side. §2 records what
was measured at the outset and §2a re-measures the same model today, so the objective
can be judged against the pipeline that now exists rather than the one that motivated it.

**Correction to the original wording.** This section first said "roughly 60-65% of its
budget on review gates and 10-13% on authoring — gates cost about five to seven times
the authoring". Re-running the meter at the commit where that sentence was written gives
**88.9% gates / 11.1% grounding, a ratio of 8.0x**. The share was understated and the
ratio slightly so; the two halves also contradicted each other, since 12% authoring at
5-7x implies 60-84% gates, and the text quoted the bottom of its own range. "Authoring"
was also the wrong word: the 11.1% line is the per-task GROUNDING READ of the oracle,
not the cost of writing it, which this model never priced.

## 2. Problem Statement

Four mechanisms, measured rather than assumed:

**Artifact size is the multiplier on everything.** Holding the gate structure fixed and
varying only feature-spec size, a modelled work costs **23.4MB** of reads with 138KB
specs and **14.5MB** with disciplined ones — size discipline alone is worth **~38%**,
and that figure is stable at 38-40% across every parameter set in the range above. Both
regimes came from the same skills, so size is unconstrained rather than wrong.

> **Corrected.** This first read "~24.9MB ... and ~10.1MB ... size discipline alone is
> worth ~60%, with no structural change". The first number is close; the second is not
> reproducible on the same shape, and ~60% is only reachable by comparing an
> undisciplined `today` against a disciplined RESTRUCTURED shape — which is precisely
> the conflation the phrase "with no structural change" denies. The mechanism is real
> and still the largest single multiplier; it was oversold by about 20 points.

**Gates multiply where documents do.** A gate per feature after Specify and a gate
per delivery after Detail means features x cycles and deliveries x cycles gate
points. `REQUIREMENTS.md` at 88KB gets re-read 15 to 28 times inside the Specify
gates alone.

**The same content is stated twice and can disagree.** A criterion was written in
REQUIREMENTS §9 and copied into every feature SPEC claiming it. Both CRITICAL
findings in this project's largest work were sibling specs asserting different
values for one shared fact.

**Stored views drift from what they derive from.** A hand-maintained wave-map
disagreed with the dependency table directly above it in the same file, and the
mandatory manual self-check that exists to prevent that did not catch it.

## 2a. Re-measured, after four merges

Same model, same parameters (3 features, 4 deliveries, 16 tasks, 5 cycles), same
default artifact sizes — only the pipeline underneath has changed:

| Regime | Total | Gates | Grounding | Gate share | Ratio |
|--------|-------|-------|-----------|-----------|-------|
| `today`, full cycles — where §1 started | 15.79MB | 14.04MB | 1.75MB | 88.9% | 8.0x |
| `folded`, full cycles — this work, before work-012 | 7.79MB | 5.36MB | 2.43MB | 68.8% | 2.2x |
| `folded` + scoped cycles — **the pipeline that now exists** | **7.04MB** | 4.61MB | 2.43MB | **65.5%** | **1.9x** |

**A 55% reduction against the starting point**, and the objective's own target range
(60-65% gates) is now met — though partly by accident, since the original figure was a
misstatement of an 88.9% reality rather than a goal.

**The shape of the problem has inverted, and that is the finding that matters.** Gates
were 8x the grounding reads; they are now 1.9x. The single most expensive line has moved
from `gate SPEC (per feature)` at 4.49MB to `task grounding` at 2.43MB — and grounding is
paid PER TASK, so it scales with task count where a gate does not. Any further work aimed
at gates is now aimed at the smaller half.

Two mechanisms outside this work drove much of the change and should be credited as such:
`work-012` scoped the cycle-2+ hunt (verification stays full, protecting `Recurred`) and
sliced the per-feature requirements load. Its slice keys off the `AC-N` citations this
work put in § 11, and this work's fold makes its slice possible; neither would have
delivered the full figure alone.

**One number moved the wrong way.** The always-on surface — paid by every session before
the user types — grew from **12,712 to 18,428 tokens (+45%)** as the skill count went
76 → 111. That is `work-006`'s design family, not a regression in this work, and AC-2's
diff gate does flag it (it currently reports FAIL on instruction-surface growth). But it
is real, it is unaddressed by any criterion here, and at ~5.7k tokens per session it
repays attention in a way a one-off per-work saving does not.

## 3. Users & Stakeholders

| Who | Interest |
|-----|----------|
| Repo owner | cost per work; the quality guarantees are not negotiable |
| Adopting teams | the same pipeline, cheaper, with no new runtime dependency |
| Dispatched agents | fewer instruction bytes to load per state |

## 4. Scope

### In Scope

- Measurement tooling for both the instruction surface and gate cost
- Removing content that git already stores
- Requiring acceptance criteria to be verifiable
- Task-to-criterion traceability
- Folding the artifact set (features into REQUIREMENTS; BLUEPRINT into PLAN)
- Reducing the Lite path to REQUIREMENTS + task DETAILs
- Deriving what is derivable instead of authoring it

### Out of Scope

- Runtime token accounting (needs host cooperation; this work measures the static
  surface and models gates)
- Changing the grade scale, the severity enum, or the ledger's 7-column shape
- `work-004`'s declared-review-criteria mechanism — complementary, not duplicated
- Batching the Specify gate as a separate change — subsumed by folding, since one
  document has one gate

## 5. Functional Requirements

- **FR-1** Cost is measurable before and after any change, for both the static
  instruction surface and the modelled gate cost.
- **FR-2** No AID artifact carries a `## Change Log` or `## Revision History`
  section; git is the document history.
- **FR-3** Every acceptance criterion names an observable. Judgment criteria are
  permitted but must state what is judged and against what standard.
- **FR-4** Acceptance criteria carry stable `AC-N` ids, stated exactly once.
- **FR-5** Every task cites the `AC-N` criteria it implements.
- **FR-6** A feature is a section of `REQUIREMENTS.md § 11`, not a folder with its
  own `SPEC.md`.
- **FR-7** A delivery is a section of `PLAN.md` carrying its own gate criteria; no
  separate `BLUEPRINT.md` exists.
- **FR-8** The Lite path produces `REQUIREMENTS.md` + `tasks/task-NNN/DETAIL.md`
  only. No `SPEC.md`, no `PLAN.md`, no `BLUEPRINT.md`.
- **FR-9** Derived content is derived, never authored: the wave-map from the
  dependency graph, and on the Lite path the dependency graph from the task
  DETAILs.

## 6. Non-Functional Requirements

- **NFR-1** No new runtime dependency on the core path. Core AID installs assume
  neither node nor python, so core-path scripts are bash + awk.
- **NFR-2** The work ends with less instruction surface than it started.
- **NFR-3** Every cut is verifiable: a script's exit code or a byte count, never
  an assertion in prose.
- **NFR-4** Derived chains (`profiles/`, the dogfood trees) are refreshed exactly
  once, at the end.
- **NFR-5** No change weakens grounding, instruction, or adversarial review. A
  change that reduces cost by removing a guarantee is out of scope, not a
  trade-off to weigh.

## 7. Constraints

- **C-1** No other work's files are modified. `work-004`, `work-005` and the other
  live works are read-only references.
- **C-2** Files `work-004` has modified on its branch are not contended; edits to
  them wait until it lands.
- **C-3** `.aid/knowledge/` edits are the KB's own process; they happen only with
  explicit owner authorization.
- **C-4** Nothing merges without explicit owner authorization.

## 8. Assumptions & Dependencies

- Token figures are `chars / 4` — deterministic and dependency-free, but an
  estimate. Byte counts are authoritative in every gate.
- The gate model multiplies real file sizes by an assumed dispatch shape. Absolute
  figures are indicative; the ratio between two shapes over identical inputs is
  the signal.
- `work-004` lands before the contended prose sweep completes.

## 9. Acceptance Criteria

- **AC-1** `tests/cost-meter.py collect` writes a deterministic inventory; two
  runs over an unchanged tree are byte-identical.
- **AC-2** `tests/cost-meter.py diff` exits non-zero on instruction-surface growth
  and zero on a reduction, reporting the reduction.
- **AC-3** `tests/cost-meter.py model` prices at least two pipeline shapes over
  identical inputs and its output scales with both `--cycles` and `--features`.
- **AC-4** `grep -rE '^## (Change Log|Revision History)' canonical docs examples`
  returns no matches, and a test asserts that count is zero.
  `tests/` is deliberately OUT of scope: the rule governs AID artifacts, and a
  fixture that simulates a legacy document must be free to contain the section
  it simulates — otherwise legacy input becomes untestable.
- **AC-5** `requirements-template.md` contains a section defining verifiable
  acceptance criteria, and the AC sections of the spec and task templates cite it
  rather than restating it.
- **AC-6** The task DETAIL template's `**Source:**` field names `AC-N` ids.
- **AC-7** `derive-waves.sh <plan> --check` exits 0 on a plan whose wave-maps
  match their dependency tables, 1 on a disagreement, and 2 on a cycle.
- **AC-8** `derive-waves.sh <plan> --write` is idempotent: three consecutive runs
  leave a correct plan byte-identical.
- **AC-9** No file under `canonical/` contains a broken relative citation
  (every `../`-relative path resolves to an existing file).
- **AC-10** No markdown file under `canonical/`, `.aid/knowledge/`, `docs/` or
  `examples/` contains a dangling in-page anchor.
- **AC-11** `aid-define` and `aid-specify` write feature content into
  `REQUIREMENTS.md § 11`; neither creates a `features/` directory or a `SPEC.md`.
- **AC-12** No `delivery-blueprint-template.md` exists and no skill instructs an
  agent to create a `BLUEPRINT.md`.
- **AC-13** The shortcut engine produces exactly `REQUIREMENTS.md`, `STATE.yml`,
  and `tasks/task-NNN/DETAIL.md` — and no `SPEC.md`, `PLAN.md`, or
  `BLUEPRINT.md`, which are the three it writes today that this removes.
- **AC-14** `profiles/` and the dogfood trees satisfy the render-drift and
  dogfood byte-identity gates at the end of the work.

## 10. Priority

FR-1 first (nothing else is provable without it), then FR-2 and FR-3 (they shrink
the multiplicand every later change is multiplied by), then FR-4 and FR-5 (they
unblock FR-8's derivation), then FR-6 through FR-9.

## 11. Features

### Feature 001 — Cost measurement

- **Priority:** Must
- **Requirements:** §5 FR-1
- **Criteria:** AC-1, AC-2, AC-3

#### Description

A meter that measures what a session and a skill actually load, and a model that
prices a gate shape. Without it every claim in this work is an estimate and no
change can be proven.

#### User Stories

As the repo owner, I want a change's saving measured rather than argued, so that a
cost decision rests on a number I can reproduce.

#### Technical Specification

`tests/cost-meter.py`, following the `tests/coverage-parity.sh` convention:
`collect` writes a deterministic TSV plus a `.meta` provenance sidecar, `diff`
compares against a committed baseline and exits non-zero on un-excused growth, and
a shrink always passes and is reported as a reduction — the gate exists to enable
cuts, so it must never block one.

`model` prices pipeline shapes. Gate rows cost `reviewer_floor + fixer_floor +
2 x artifact` per cycle; read rows (task grounding — the oracle every task
consults) cost artifact bytes only, folded into a dispatch that already happens.
Both row kinds are needed because merging documents MOVES cost between the gate
stage and the grounding stage, and a gate-only model scores that wrong.

Dispatch floors are derived from the tree, never hardcoded, so an optimization
that shrinks an `AGENT.md` or a template scores itself automatically.

### Feature 002 — Artifact discipline

- **Priority:** Must
- **Requirements:** §5 FR-2, FR-3, FR-4
- **Criteria:** AC-4, AC-5, AC-9, AC-10

#### Description

Stop generating content git already stores, and require criteria to be
falsifiable. This is the only change that attacks artifact size at its source,
and size is the multiplier on every other saving.

#### User Stories

As a reviewer, I want every criterion to name something I can check, so that my
cycles go to judgment instead of to prose that cannot be wrong.

#### Technical Specification

The verifiability rule is stated once, in
`requirements-template.md § Verifiable Acceptance Criteria`, with a table of
accepted forms and worked pass/fail examples; the spec and task templates and the
five authoring instruction sites cite it rather than restating it. The Change Log
sweep needed 17 edits precisely because that rule lived nowhere.

### Feature 003 — Traceability

- **Priority:** Must
- **Requirements:** §5 FR-4, FR-5
- **Criteria:** AC-6

#### Description

Criteria get ids; tasks cite the ids they implement. The blocker was never the
task field — it was that a SPEC's criteria were bare checkboxes with no
identifier, so nothing downstream could reference one.

#### User Stories

As an executing agent, I want to load only the criteria my task answers to, so
that I do not read an 88KB document to implement one thing.

#### Technical Specification

`AC-N` ids in REQUIREMENTS §9, never reused or renumbered. A task's `**Source:**`
reads `feature-NNN-{name} -> delivery-NNN -> AC-N[, AC-N]`, at least one required.
The trace becomes mechanically checkable: every id either resolves in the cited
section or it does not.

### Feature 004 — Artifact folding

- **Priority:** Must
- **Requirements:** §5 FR-6, FR-7, FR-8
- **Criteria:** AC-11, AC-12, AC-13

#### Description

Features become sections of REQUIREMENTS; deliveries become sections of PLAN
carrying their own gate criteria; the Lite path reduces to REQUIREMENTS plus task
DETAILs.

#### User Stories

As the repo owner, I want one document per concern rather than one per instance,
so that two siblings cannot assert different values for the same fact.

#### Technical Specification

The rule that decides what survives is **store what was decided, derive what
follows from it.**

`PLAN.md` earns its place on the full path because delivery sequencing is a
decision nothing derives. It has no place on the Lite path, where there is one
delivery and so no sequencing decision — it would exist only to hold a derived
table.

`BLUEPRINT.md` does not survive either path. Its `## Gate Criteria` was defined as
translating each acceptance criterion into something verifiable; FR-3 now requires
criteria to be verifiable already, so the translation has nothing left to do.

### Feature 005 — Derivation over authoring

- **Priority:** Must
- **Requirements:** §5 FR-9
- **Criteria:** AC-7, AC-8

#### Description

Content computable from other content is computed, not written by an agent and
then manually self-checked.

#### User Stories

As the repo owner, I want the wave-map to agree with its dependency table by
construction, so that a manual totality check is not the thing standing between
me and a wrong plan.

#### Technical Specification

`canonical/aid/scripts/execute/derive-waves.sh`, bash + awk only per NFR-1.
`--write` is idempotent and splices each block into its own delivery section;
`--check` exits 0 / 1 / 2 for agrees / disagrees / malformed graph. On the Lite
path the dependency graph itself is derived from the task DETAILs' `Depends on`
fields, so no stored graph exists to drift.

### Feature 006 — Render and close-out

- **Priority:** Must
- **Requirements:** §6 NFR-4
- **Criteria:** AC-14

#### Description

`canonical/` renders into five `profiles/` trees and two tracked dogfood trees.
Refreshed exactly once, at the end.

#### User Stories

As the repo owner, I want one mechanical render commit rather than churn
interleaved with the reasoning, so that the diff stays reviewable.

#### Technical Specification

`python .claude/skills/generate-profile/scripts/run_generator.py`, then a
manifest-driven resync of the two dogfood trees — only the manifest-owned `dst`
paths are copied, so hand-authored files in those trees are never touched.
