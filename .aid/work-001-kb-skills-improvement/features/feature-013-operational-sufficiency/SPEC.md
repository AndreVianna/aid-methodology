# Operational Sufficiency (the "act-back" gate)

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-23 | Feature authored post-detail to close the **agent-actionability** gap — the KB's primary purpose is operating guidance for an AI agent doing work in the project, but no existing gate verifies *actionability* (teach-back/calibration/closure verify comprehension + correctness, not "could an agent DO a representative change from the KB alone"). Adds the **act-back gate** (FR-36) as the operational sibling of teach-back. | user decision |

## Source

- REQUIREMENTS.md §5.D (FR-36 — operational sufficiency / act-back, NEW)
- REQUIREMENTS.md §1.2 ("KB value = the *delta* from what a generalist already knows" — the agent cannot infer the project's own way of doing a change), §1.4 (the review panel + teach-back keystone — act-back is the operational sibling), §1.6 (honest mechanical/judgment floor), §2.1/§2.2 (P1, P2 — the gate certifies "true + template-complete," not *useful for doing work*)
- §4 S4 (discovery quality — the review panel + the mandates), §9 AC16 (NEW)
- §10 (Must)
- **Extends feature-005** (the multi-mandate review panel + teach-back keystone) — adds a **6th mandate** to the same panel + reuses f005's parallel-dispatch + merged-ledger + `grade.sh` machinery.

## Description

The existing discovery gates verify **comprehension** and **correctness**: teach-back
asks "can a fresh agent *explain* the engine and answer 'what is X?'", calibration asks
"does each doc sit at the useful altitude", closure asks "is every native term grounded",
correctness asks "is every claim true vs source." **None of them verifies
*actionability*** — the thing the KB primarily exists for: could an agent, **given only
the KB**, correctly *perform a representative change* in the project, and where would it
be forced to **guess** or **reach for source**?

feature-013 closes that gap with the **operational-sufficiency / "act-back" gate** — the
**operational sibling of teach-back**. Teach-back = *explain*; act-back = *do*. It adds a
**6th mandate (M6)** to f005's review panel: a **clean-context agent** is given ONLY the
KB **+ a representative project task** (drawn from the project's own domain — "add an
endpoint", "wire a new module", "add a field to the pipeline contract") and must
**(a)** produce a *correct plan/outline* for that change AND **(b)** **flag every point
where the KB was insufficient** — every place it had to *assume* a convention, *guess* an
invariant, or *reach for source* because the KB did not say. Each insufficiency flag is a
finding — a description-side `[ACTBACK]` tag at a severity that feeds the **existing**
`grade.sh` (exactly like `[TEACHBACK]`) — and enough flags fail the gate.

To make the KB *act-on-able* (not just *explain-able*), feature-013 also **tightens the
doc model (extends f003)**: the operational guidance an agent acts on — **conventions,
invariants, gotchas, contracts** — must be **first-class structure** in the relevant
concern docs (a named, greppable section shape), **not buried in prose**. The act-back
mandate checks for that structure; the structural requirement gives act-back something
concrete to verify and gives the agent something concrete to act on.

This feature **reuses f005's panel + f003's doc model + f001's `sources:`** and does
**not** re-spec them. The act-back mandate is the agent analog of teach-back: deterministic
where mechanical, judgment where not, ASCII for any shipped script, render-drift-aware.

## User Stories

- As an **AI agent** about to do a task in the project, I want the KB to be *sufficient to
  act on* — the conventions, invariants, gotchas, and contracts I need are stated, not
  implied — so that I can perform a representative change correctly without guessing or
  re-deriving from source.
- As an **AID adopter (incl. AI-skeptic)**, I want the gate to certify *actionability* (an
  agent could do a representative change from the KB) and not just *comprehension*, so that
  a green gate means the KB is operationally useful, not merely explainable.
- As an **AID maintainer**, I want operational guidance (conventions / invariants / gotchas
  / contracts) to be first-class, greppable doc structure — so the act-back mandate can
  check for it deterministically and so agents and humans find it fast.

## Priority

Must

## Acceptance Criteria

- [ ] Given a reviewed KB, when the panel runs, then it applies a **6th mandate
  (Operational sufficiency / act-back)**: a clean-context agent, given ONLY the KB + a
  representative project task, produces a plan AND flags every KB-insufficiency point;
  each flag is a `[HIGH]` `[ACTBACK]` finding in the same merged ledger; enough flags fail
  the gate (act-back composes with teach-back as a **sibling keystone**). *(FR-36)*
- [ ] Given a KB doc that carries operational guidance, when it is authored, then its
  **conventions / invariants / gotchas / contracts** are **first-class structure** (named,
  greppable section shape per the f003 doc model), not buried in prose; the act-back
  mandate checks for that structure. *(FR-36; extends FR-9/FR-11)*
- [ ] Given an act-back **fixture** (a representative-task fixture + a pass/fail KB pair),
  when the downstream Validation delivery runs, then the **mechanical half** (the doc
  carries the named operational-structure sections; the representative-task spec exists and
  is well-formed) is CI-asserted and the **judgment half** (does the clean-context agent's
  plan succeed; are its insufficiency flags well-founded) is runtime-anchored — honoring the
  same mechanical-vs-judgment boundary f012 uses. *(supports AC16; f012 exercises)*

> Cross-cutting note: this feature carries the FR-23 / NFR-1–3 budget — act-back is **one
> more parallel `aid-reviewer` dispatch** on f005's existing fan-out (no new wall-clock
> critical path beyond one reviewer); it reuses the **existing** `grade.sh` + reviewer-ledger
> + merged-ledger machinery (no new grading infra); the **representative-task spec** is a
> fixed, mechanically-checkable input; the act-back *judgment* ("did the plan succeed / are
> the flags well-founded") is the named, minimized LLM surface — the operational analog of
> teach-back's engine-narration judgment. The act-back fixtures are provided by f012.

---

## Technical Specification

> Methodology/tooling feature — an **extension of f005's review panel**, the *operational*
> half of the essence-validation engine. Where teach-back (f005 M4) verifies the KB can be
> *explained*, act-back (this feature's M6) verifies the KB can be *acted on*: a clean-context
> agent, given only the KB + a representative project task, must produce a correct plan AND
> flag every point of KB insufficiency. f013 **adds a 6th mandate to f005's panel** (reusing
> the existing parallel-dispatch + merged-ledger + `grade.sh` machinery — it invents **no new
> grading infra**), **tightens f003's doc model** so operational guidance (conventions /
> invariants / gotchas / contracts) is first-class greppable structure the mandate can check,
> and **specifies a fixture** the downstream Validation delivery (f012) exercises. "Components"
> here are one new `aid-discover` REVIEW mandate prompt body, an addition to f005's panel
> orchestration, a doc-model structural rule authored into f003's `concern-model.md` /
> `principles.md`, **one** small mechanical script (the representative-task selector + the
> operational-structure presence check), the `review-rubric.md` tag addition, and a canonical
> test suite — **not** application code. Every claim is grounded against the files cited inline;
> genuine unknowns are flagged **[SPIKE]**, not guessed.
>
> **Boundaries (NOT absorbed here).** The **5-mandate panel** (Correctness, Anatomy/Coverage,
> Concept-closure, Teach-back, Calibration), the **parallel fan-out → merged single ledger →
> `grade.sh`** orchestration, the **clean-context discipline**, the **`[TEACHBACK]` keystone
> encoding**, and the **injectable `{{SCOPE}}` + doc-set seam** are **f005**'s — f013 *adds one
> mandate alongside them* and *reuses* the orchestration verbatim; it does not re-spec the panel.
> The **panel-size scaling by path** (full panel for brownfield-large; collapse to 1
> checklist-reviewer for brownfield-small) is **f006**'s wiring — f013's M6 joins the per-mandate
> dispatch list f006 scales (the act-back mandate is **invariant across paths**; only the panel
> *size* scales, exactly like the other mandates). The **doc model** (concerns → docs,
> summary+pointer, expectations-as-open-questions, `owner:`/`audience:`) is **f003**'s — f013
> *adds one structural rule* (operational guidance is first-class) to `concern-model.md` /
> `principles.md`; it does not re-author the doc model. The **frontmatter schema** (`sources:`,
> `objective:`, `summary:`, `tags:`) is **f001**'s — f013 *consumes* `sources:` (the act-back
> reviewer follows it only to confirm the agent did NOT need to). The **fixture corpus +
> regression suites + mechanical/judgment boundary** are **f012**'s — f013 *specifies the
> act-back fixture shape* and f012 *builds + exercises* it (the act-back fixture joins f012's
> `kb-essence/` corpus). **Migration** of AID's own KB to add the operational-structure sections
> is **f011**'s concern (re-grading under the new mandate is f005's re-REVIEW). Reuse the
> **existing `aid-reviewer` agent + reviewer-ledger schema + `grade.sh`** — f013 invents **no new
> grading infra**.

### Overview

f005 turned REVIEW into a **5-mandate parallel panel** aggregated into one `discovery.md`
ledger that the **existing** `grade.sh` grades, with **teach-back closure** as the keystone
exit (encoded as `[HIGH] [TEACHBACK]` rows). Those five mandates verify the KB is **true**
(M1), **complete** (M2), **self-contained** (M3), **explainable** (M4 teach-back), and
**well-calibrated** (M5). What none of them verifies is the KB's **primary operational
purpose**: *could an agent, given only the KB, correctly DO a representative change?*

This is a distinct axis from teach-back. Teach-back's bar is **explanation** — "answer
'what is X?' and narrate how the engine works." An agent can pass that (it understands the
system) and still be unable to **act**: it knows *what* a 'Relative bus' is but the KB never
says *which convention* a new bus handler must follow, *which invariant* must hold, *which
gotcha* will bite, or *which contract* the change must satisfy — so to actually add a bus
handler it must **guess** or **reach for source**. The KB exists first and foremost to let
an agent operate in the project; act-back is the gate that certifies it does.

f013 adds **three things**, all grafted onto f005's existing panel + f003's existing doc
model (graft, don't replace — REQUIREMENTS 1.9):

1. **The 6th mandate, M6 (Operational sufficiency / act-back).** A **clean-context
   `aid-reviewer`** given ONLY the KB **+ a representative project task** must (a) produce a
   correct **plan/outline** for that change and (b) **flag every KB-insufficiency point** —
   every assumption it had to make, every invariant it had to guess, every time it would
   have to reach for source. Each flag is a `[HIGH]` `[ACTBACK]` row in the **same merged
   `discovery.md` ledger** f005 already grades; **any open `[ACTBACK]` row ⇒ not-Ready** (the
   sibling-keystone mechanism, realized exactly like teach-back — see Composition).
2. **Doc-model tightening (extends f003).** Operational guidance — **conventions,
   invariants, gotchas, contracts** — MUST be **first-class structure** (a named, greppable
   section shape) in the relevant concern docs, not buried in prose. This is authored into
   f003's `concern-model.md` + `principles.md` as a structural rule, and the M6 mandate
   **checks for it** (its absence is what forces the act-back agent to guess).
3. **One mechanical helper + the fixture shape.** A small ASCII script
   `kb-actback-task.sh` that (a) **selects/normalizes the representative task** from a
   deterministic source and (b) performs the **operational-structure presence check** (does
   each Full-Primary doc carry the named operational sections). The *agent's plan success +
   flag well-foundedness* is the irreducible judgment (the operational analog of teach-back's
   engine-narration limb). The **fixture** (a representative-task spec + an act-back pass/fail
   KB pair) is **f012**'s to build; f013 specifies its shape.

The deterministic substrate (the representative-task spec, the operational-structure presence
check, the existing `grade.sh`) is mechanical/CI-able; the irreducible LLM judgment ("did the
plan succeed", "is this insufficiency flag well-founded") is **minimized and anchored** to a
fixed representative task (REQUIREMENTS 1.6 honest floor; NFR-3) — exactly the discipline f005's
teach-back engine-narration limb and f012's judgment boundary already use.

### The 6th Mandate (M6 — Operational sufficiency / act-back)

M6 is a **scoped `aid-reviewer` dispatch** in f005's panel, with the same shape as the other
five — (a) a definition, (b) what it checks, (c) what it fails on, (d) a prompt focus — and it
writes to the same merged ledger. It extends f005's mandate table with a sixth row:

| # | Mandate | Definition | Checks | Fails when | Severity anchor |
|---|---------|------------|--------|------------|-----------------|
| M6 | **Operational sufficiency (act-back)** | Using ONLY the KB, **DO** a representative project change — produce a correct plan AND flag every point the KB was insufficient to act on. | A **clean-context** reviewer, given ONLY the KB + the **representative-task spec** (`kb-actback-task.sh` output), must (a) produce a correct, executable **plan/outline** for the change in the project's own conventions, and (b) **flag every insufficiency** — every convention it had to assume, invariant it had to guess, gotcha it could not anticipate, or contract it had to reach for source to find. The mandate also checks the **operational-structure presence** (does each touched concern doc carry the first-class conventions/invariants/gotchas/contracts sections the plan needs). | The plan cannot be produced correctly from the KB alone, **OR** any insufficiency flag is raised (the KB forced an assumption / a guess / a reach-for-source). Each is its own FAIL item. | `[HIGH]` `[ACTBACK]` row per FAIL item; any open `[ACTBACK]` row ⇒ not-Ready (the sibling-keystone gate, realized through the rows — see Composition). |

**Mandate-to-panel mapping (graft, don't replace).** M6 is a **new** operational axis,
parallel to M4 teach-back: M4 verifies *explanation*, M6 verifies *action*. It reuses the
**identical** scoped-dispatch shape — universal `reviewer-brief.md`, its own FOCUS body
(`reviewer-prompt-actback.md`), its own scratch ledger, merged into the one `discovery.md`. It
is **invariant across paths** (it is a mandate, not panel-size); only the panel *size* scales
(f006). Like M4, M6 routes nothing to the category rubric — it is a whole-KB operational probe,
not a per-doc-category check (the operational-structure *presence* check it runs is scoped to
Full-Primary docs, mirroring M5 Calibration).

#### The clean-context dispatch (the agent analog of teach-back)

M6 is special in the same way M4 is: it is a **clean-context** `aid-reviewer` with the
*stricter* context rule (the strongest form of `state-review.md`'s CLEAN-CONTEXT block):

- **Input = ONLY the KB** (`.aid/knowledge/*.md`) **+ the representative-task spec**. It is
  **not** given the project source, the project-index, the candidate-concepts list, or any
  generation context. The whole point is to simulate "a fresh agent told only 'here is the KB,
  now do this task'" — if the reviewer can reach the source, it is not *acting from the KB*, it
  is re-deriving (the same failure teach-back guards against). The reviewer may *cite* a doc's
  `sources:` to say "the KB **defers** this to `src/X` — I would have to reach for source here"
  (which is itself an `[ACTBACK]` insufficiency flag), but it does **not read** the source.
- **The representative task** is sourced from `kb-actback-task.sh` (see The Mechanical Helper).
  It is a **representative change in the project's own domain** — e.g. "add an endpoint", "wire a
  new module into the pipeline", "add a field to a contract" — *keyed to the project's own
  KB shape* so the task is real to this project, not a generic template. The task is **fixed and
  reproducible** (the same KB shape yields the same task), so M6's judgment is anchored to a fixed
  input, not free choice of what to attempt. **What is deterministic vs judgment is stated
  precisely in The Mechanical Helper:** the script reads only **machine-readable** substrate (the
  doc filenames + their `present|absent` status from the resolved `discovery.doc_set`, plus the
  first-class operational sections actually present in the KB — e.g. a doc carrying `## Contracts`);
  the concern→task-shape mapping is a documented **tuning HINT, not a machine field** (the resolver
  TSV carries no concern column — see The Mechanical Helper), and the exact task-shape heuristic is
  the calibrated judgment deferred via [SPIKE-A1].

#### Pass / fail (the sibling-keystone gate)

The act-back reviewer attempts the representative change **using only the KB**, then self-scores
along **two limbs** — both independent FAIL sources:

- **Plan-correctness limb ("can I do it right?"):** PASS iff the KB lets the reviewer produce a
  **correct, executable plan/outline** for the change in the project's *own* conventions (not a
  generic best-practice plan). A plan that is wrong for this project, or that cannot be assembled
  at all from the KB, = a **FAIL item**. *(This is the operational analog of teach-back's
  engine-narration limb — irreducibly LLM judgment; see Judgment Boundary.)*
- **Sufficiency limb ("did I have to guess?"):** for **every** point in the plan, the reviewer
  must flag whether the KB *stated* what it needed or whether it had to **assume / guess / reach
  for source**. Each such insufficiency is a **FAIL item** naming *what was missing and where the
  plan needed it* (so FIX has an actionable target — "the KB does not state the convention for
  registering a new bus handler; `module-map.md` should carry it"). The four insufficiency
  classes map to the doc-structure requirement below: a missing **convention**, a missing
  **invariant**, an un-anticipated **gotcha**, or an un-stated **contract**.
- **Operational-structure presence (mechanical anchor):** before judging, the mandate runs
  `kb-actback-task.sh`'s presence check — does each concern doc the plan touches carry the
  **first-class** conventions/invariants/gotchas/contracts sections (Doc-Model Tightening
  below)? A doc that *buries* its operational guidance in prose (or omits it) is the structural
  cause of a sufficiency-limb FAIL; the presence check is the deterministic evidence the
  reviewer's sufficiency judgment is anchored to (it does NOT replace the judgment — a doc can
  have the section header and still under-specify the convention).
- **Verdict (single mechanism, identical to teach-back):** each FAIL item from EITHER limb is a
  `[HIGH]` `[ACTBACK]` row in `discovery-actback.md` naming the change/insufficiency. There is
  **no separate verdict sentinel** — act-back is PASS iff zero open `[ACTBACK]` rows, FAIL
  otherwise.

### Composition with the panel + teach-back (sibling keystone, not combined)

**Decision: act-back is a SIBLING keystone to teach-back, not a combined gate.** The two are
**independent FAIL sources** that share **one mechanism** — both encode their FAILs as `[HIGH]`
rows in the **same merged `discovery.md`** ledger that the **existing** `grade.sh` already
grades. The rationale for *sibling* over *combined*:

- They verify **different axes** (explain vs do); a KB can pass one and fail the other (the
  caprica case: an agent can *explain* 'Relative bus' yet be unable to *add* a bus handler
  because no convention/contract for it is stated). Folding them into one verdict would hide
  which axis failed — the FIX target must distinguish "explain-gap" (`[TEACHBACK]`) from
  "act-gap" (`[ACTBACK]`).
- They reuse the **identical encoding**, so siblinghood costs nothing: each is a `[HIGH]` tagged
  row; **either** open row forces `grade.sh` to `<= D`; so **either** open keystone holds REVIEW
  open, with no separate boolean and no `AND`/`OR` to reconcile. The grade already enforces both:

```
READY  iff  grade(discovery.md) >= minimum_grade
         (any open [HIGH] [TEACHBACK] row  OR  any open [HIGH] [ACTBACK] row forces
          grade <= D, so either an explain-gap or an act-gap is, by construction, a
          not-Ready grade — two sibling keystones, one grader, no AND/OR to reconcile)
```

- **Distinct tags, distinct clean-context dispatches.** M4 (teach-back) and M6 (act-back) are
  **two separate** parallel `aid-reviewer` dispatches with **two separate** scratch ledgers
  (`discovery-teachback.md`, `discovery-actback.md`), each merged into `discovery.md` with its
  own description-side tag (`[TEACHBACK]` / `[ACTBACK]`) and its own stable per-mandate `#` ID
  (`TB-NNN` / `AB-NNN`). This keeps the two keystones' FIX targets un-conflated and lets each
  reviewer re-verify only its own rows cycle-to-cycle (the f005 cross-cycle consistency rule,
  applied identically to M6).
- **Reporting pair → triple.** f005's exit print reports `Grade: <g> | Teach-back: <PASS|FAIL>`.
  f013 extends it to the **triple** `Grade: <g> | Teach-back: <PASS|FAIL> | Act-back: <PASS|FAIL>`,
  each verdict derived from "any open row of that tag?" — e.g. `Grade: D | Teach-back: PASS |
  Act-back: FAIL -> NOT Ready (FIX act-back gaps first)`. The `[ACTBACK]` tag keeps these rows
  un-relaxable in practice exactly as `[TEACHBACK]` does (a reviewer cannot quietly downgrade an
  act-back gap below `[HIGH]` without dropping the tag FIX targets).

#### Panel orchestration delta (the one-dispatch addition to f005)

f005's `state-review.md` Step 1 fans out to **5** parallel `aid-reviewer` dispatches; f013 makes
it **6** by adding M6 to the existing mandate loop — a **minimal, additive** edit to f005's
orchestration, not a rewrite:

```
Step 1  Dispatch the Panel  (6 PARALLEL aid-reviewer dispatches — the full-panel default)
  1a  Render the universal brief (reviewer-brief.md) ONCE — unchanged.
  1b  For each mandate Mi in {Correctness, Anatomy/Coverage, Concept-closure, Teach-back,
      Calibration, ACT-BACK}: append that mandate's FOCUS body (reviewer-prompt-<mandate>.md)
      + (M6 only) the representative-task spec from kb-actback-task.sh + the operational-
      structure presence-check output.
  1c  Dispatch all 6 aid-reviewer sub-agents IN PARALLEL (one message, 6 dispatches) —
      the same A3 capability-probe degrade-to-sequential f005 specifies.
  1d  Each mandate reviewer writes to ITS OWN transient scratch ledger
      .aid/.temp/review-pending/discovery-<mandate>.md (M6 → discovery-actback.md).
  Wait for all 6 to complete.

Step 2  Aggregate + Grade  (unchanged f005 flow, +1 scratch ledger merged)
  2a  Concatenate the data rows from ALL SIX scratch ledgers (the five f005 ledgers PLUS
      discovery-actback.md's [HIGH] [ACTBACK] FAIL-item rows) into discovery.md, assigning
      each merged row its stable per-mandate # ID (M6 rows → AB-NNN; [ACTBACK] description tag).
  2b  Run the EXISTING grader unchanged: grade.sh --explain discovery.md. (No grade.sh change —
      it counts worst-severity over Status, indifferent to which mandate produced a row.)
  2c  Evaluate BOTH sibling keystones off discovery.md itself: teach-back PASS iff zero open
      [TEACHBACK] rows; act-back PASS iff zero open [ACTBACK] rows. No stored sentinel for either.
  2d  Delete the 6 transient scratch ledgers (incl. discovery-actback.md).

Step 3  Exit print + STATE report the TRIPLE: "Grade: <g> | Teach-back: <v> | Act-back: <v>".
```

This is the **only** change to f005's orchestration: **+1 mandate in the loop, +1 scratch
ledger merged, +1 verdict in the reporting triple.** Everything else — the brief render, the
parallel fan-out, the merge-to-single-ledger, the `grade.sh` invocation, the clean-context +
contamination blocks, the injectable `{{SCOPE}}` + doc-set seam — is **f005's, reused
verbatim**. Because M6 joins the per-mandate dispatch list, **f006's panel-size scaling applies
to it automatically** (the brownfield-small collapse to 1 checklist-reviewer folds M6's
act-back checks into the single reviewer's checklist, exactly as it folds the other mandates).

### Doc-Model Tightening (extends f003 — operational guidance is first-class)

For an agent to **act** from the KB, the operational guidance it acts on must be **stated
where it can find and trust it** — not buried in a paragraph it might skim past. f013 adds a
**structural rule** to f003's doc model: the four operational-guidance classes are
**first-class structure** in the relevant concern docs.

#### The rule (authored into `concern-model.md` + `principles.md`)

A concern doc that carries operational guidance MUST express it as **named, greppable
sections** — not interleaved prose. The four classes (matching M6's four insufficiency
classes):

| Class | What it states | Why an agent needs it to act | Lives in (concern) |
|-------|----------------|------------------------------|--------------------|
| **Conventions** | The project's *own way* of doing a recurring change (how a new endpoint/module/handler is named, registered, wired). | Without it the agent invents a convention → wrong for this project. | C3 Conventions (`coding-standards.md`); the relevant parts/contracts doc (C2/C5). |
| **Invariants** | What MUST always hold (an ordering, a non-null, a single-source-of-truth rule). | Without it the agent violates an invariant the source enforces silently. | C1/C2 (architecture / parts) + the concept-spine (C4) where the invariant is conceptual. |
| **Gotchas** | The non-obvious trap (a config that must change in lockstep, a build step, an ordering hazard). | The §1.2 "what a newcomer cannot infer" — exactly the KB's delta-value; without it the agent steps on the trap. | C7 Risk & debt (`tech-debt.md`) + the concern the gotcha lives in. |
| **Contracts** | The structural shape a change must satisfy (a schema, an interface, a pipeline contract). | Without it the agent's change breaks the contract → integration failure. | C5 Data & contracts (`schemas.md`), C2 (`pipeline-contracts.md`, `integration-map.md`). |

- **First-class = a named section shape, not a frontmatter field.** The rule is satisfied by a
  **named markdown section** (a stable, greppable heading — e.g. `## Conventions`,
  `## Invariants`, `## Gotchas`, `## Contracts`, or a project-named equivalent the
  `concern-model.md` rule enumerates) within the concern doc that owns that guidance. It is
  **NOT** a new frontmatter field (no f001 schema change) and **NOT** a new doc (no
  `concern-model.md` concern added) — it is a **structural expectation** layered onto the
  existing concern docs, the same class of rule as f003's summary+pointer and
  expectations-as-open-questions. **A doc only needs the sections relevant to its concern** (a
  glossary doc need not carry `## Contracts`); the rule is "where a doc carries operational
  guidance of class X, it carries it as the named section for X," not "every doc carries all
  four."
- **It rides f003's expectations-as-open-questions.** f003 rewrote `document-expectations.md`
  to lead each doc with the open question(s) it must answer. f013 **adds an operational
  open-question** to the relevant docs' expectations — e.g. architecture/parts:
  "*What must a newcomer follow, never break, and watch out for when changing this — the
  conventions, invariants, and gotchas?*" — so the researcher is prompted to surface the
  operational guidance *as the named section*, not bury it. This is a **prose addition to
  f003's `document-expectations.md` entries**, not a schema change (same parser, richer prompt).
- **It anchors M6 mechanically.** `kb-actback-task.sh`'s presence check greps for the named
  section headings in each Full-Primary doc and reports which operational classes are
  **structurally present vs absent** — the deterministic evidence the act-back reviewer's
  sufficiency judgment is anchored to (a structurally-absent class is the *likely* cause of an
  insufficiency FAIL; the reviewer confirms the guidance was actually needed for the task). The
  check is **scoped by this owning-table**: it reports `present|absent` only for the classes the
  table maps a doc as owning, so a doc that legitimately owns no class X (e.g. a glossary doc owns
  no `## Contracts`) is **not** over-reported as absent — the table only flags an *expected* class
  that is missing.

#### Why this extends f003 (not re-specs it)

f003 owns *what a KB document is* (concerns → docs, summary+pointer, audience/ownership,
open-questions). f013 adds **one structural expectation** to that model — operational guidance
is first-class — authored into f003's `concern-model.md` ("Operational guidance is first-class
structure" subsection) and cross-referenced from `principles.md` (a new principle line, beside
the existing summary+pointer principle). It touches **no** f003 machinery (the concern list, the
seed mapping, `doc-set-resolve.md`, `aid-summarize`) — it is the same additive class of rule
f003 itself applies. f003 lands the doc model; f013 sharpens it for action.

### The Mechanical Helper + new finding tag

- **`kb-actback-task.sh` (NEW, ASCII bash, pure coreutils).** One small script with two
  functions, each built on a **deterministic substrate** (the filename/presence/section scan
  below); the only non-mechanical element is the calibrated task-shape heuristic in (1), deferred
  via [SPIKE-A1]:
  - **(1) Representative-task selection.** Emits the **representative-task spec** the M6
    reviewer attempts — a fixed, reproducible "do this change" prompt **keyed to the project's
    own KB shape**, not a generic template.
    - **The deterministic substrate (what the script can actually read).** The script keys off
      **machine-readable** inputs only: the **doc filenames** + their **`present|absent` status**
      from the resolved `discovery.doc_set`, and the **first-class operational sections actually
      present** in those docs (the `## Conventions`/`## Invariants`/`## Gotchas`/`## Contracts`
      headings the presence check in (2) greps). **The concern column is NOT a machine field.**
      `doc-set-resolve.md` is explicit (L73-75, L108-110): the resolver TSV is
      `filename<TAB>owner<TAB>presence` — three fields only — and concern annotations live in
      standalone bash comments, never a fourth field. So `kb-actback-task.sh` **cannot mechanically
      read** "this project is C2/C5"; it reads the **filenames + presence + present operational
      sections**, which IS a deterministic substrate (same KB shape → same task).
    - **The concern mapping is a documented tuning HINT, not a machine input.** The concern→task
      mapping (f003's ownership model) is consumed by the **author of the selection heuristic** as
      a calibration hint for which task-shape suits which file profile (e.g. a KB carrying
      `schemas.md` + `pipeline-contracts.md` suggests a contract/endpoint change), but the script
      does not parse a concern field at runtime — it pattern-matches the **filenames + present
      sections** it can actually read.
    - **What is deterministic vs judgment, stated plainly.** *Deterministic (mechanical, CI-able):*
      the filename + presence + present-section **scan** is byte-reproducible. *Judgment
      (calibrated, not mechanical):* the **task-shape heuristic** — which file/section profile maps
      to which representative change — is the irreducible tuning surface, deferred via **[SPIKE-A1]**
      and **f012-calibrated** against the act-back fixtures (the fixture pins that the selected task
      is representative and well-formed; the heuristic is tuned, not guessed). The "deterministic
      substrate" claim is thus scoped to exactly what the script reads (filenames, presence,
      present sections) — not to a concern field the resolver does not emit.
  - **(2) Operational-structure presence check.** For each Full-Primary KB doc, greps for the
    named operational sections (`## Conventions` / `## Invariants` / `## Gotchas` /
    `## Contracts`, per the `concern-model.md` enumerated headings) and emits a per-doc table
    `doc | class | present|absent` — the M6 sufficiency anchor (mirroring f004's
    `closure-check.sh` coverage table shape). **Scoped to the classes each doc is *expected* to
    carry:** the check consumes f003's `concern-model.md` **owning-table** (the four classes →
    owning concerns → docs map) to determine which operational classes a given doc is expected to
    own, and reports `present|absent` **only for those expected classes**. So a `domain-glossary.md`
    (C4 vocabulary — owns no contracts) is **not** reported `## Contracts absent`; only a doc the
    owning-table maps as a Contracts owner (e.g. `schemas.md` / `pipeline-contracts.md`) is. This
    prevents the table over-reporting legitimate absences (a doc that owns no class X is not faulted
    for lacking section X). **Stable-sorted, byte-reproducible** (NFR-3).
  - It is **pure coreutils** (`grep`/`awk`/`sort`) — no LLM, no embedding, no `python3`/`pwsh`
    (C1/NFR-8). It vendors into the install bundles, so it is **ASCII-only** (C2) and added to
    `test-ascii-only.sh`'s `SHIPPED_SCRIPTS` allow-list.
- **New finding tag** (added to `review-rubric.md`'s "Lint output -> severity mapping" table,
  reusing the existing `[SEVERITY] [TAG] <description>` convention — no new grading infra):
  `[ACTBACK]` (HIGH — a point where the KB was insufficient to act on: a missing convention /
  invariant / gotcha / contract, or a plan that could not be produced from the KB). It is a
  **description-side tag** the reviewer emits with its severity prefix; `grade.sh` still counts
  only the **Severity column** (unchanged), so the tag is for FIX-targeting + human readability,
  exactly like `[TEACHBACK]`/`[CAL-*]`. **No `grade.sh` change.** The verbatim row to add to the
  table (mirroring the as-built `[TEACHBACK]` row at `review-rubric.md` L255, including the inline
  "forces grade <= D" clause so the rubric is self-describing):

  ```
  | `[ACTBACK]` | HIGH | An act-back FAIL item — using ONLY the KB, the agent cannot produce a correct plan for the representative change (plan-correctness limb), or it had to assume a convention, guess an invariant, hit an un-anticipated gotcha, or reach for source for a contract (sufficiency limb); any open `[ACTBACK]` row forces grade <= D |
  ```

### The Fixture (specified here; built + exercised by f012)

f013 specifies the **act-back fixture shape**; **f012 builds it into its `kb-essence/` corpus
and exercises it**, honoring the **same mechanical-vs-judgment boundary f012 uses** for
teach-back/calibration. The fixture has two halves:

- **A representative-task spec fixture** — a small fixed project shape (a confirmed
  `discovery.doc_set` — filenames + presence — plus the operational sections present in its docs)
  over which `kb-actback-task.sh` emits a **stable, well-formed representative task** (the
  *mechanical* half: the task spec exists, is deterministic over the machine-readable substrate,
  and is byte-reproducible; the task-shape heuristic the fixture calibrates is [SPIKE-A1]).
- **An act-back pass/fail KB pair** —
  - **`actback-pass-kb`** — a KB whose relevant docs carry the **first-class operational
    sections** (conventions / invariants / gotchas / contracts) the representative task needs;
    `kb-actback-task.sh`'s presence check reports them **present**; the clean-context agent can
    produce a correct plan with **no** insufficiency flag (the act-back PASS shape).
  - **`actback-fail-kb`** — the same KB with the operational guidance **buried in prose or
    omitted** (the named sections absent); the presence check reports the classes **absent**;
    the clean-context agent must **guess / reach for source** → at least one `[ACTBACK]` FAIL
    item (the act-back FAIL shape).
- **The mechanical / judgment split (mirrors f012's contract).**
  - **Mechanical half (CI-asserted by f012):** `kb-actback-task.sh` emits the same task
    deterministically (byte-reproducible); the presence check reports the named operational
    sections **present** for `actback-pass-kb` and **absent** for `actback-fail-kb`. These are
    pure script-over-fixture assertions, exactly like f012's V-B/V-C mechanical limbs.
  - **Judgment half (runtime-anchored, NOT a CI assertion):** *does the clean-context agent's
    plan succeed*, and *are its insufficiency flags well-founded* — these are **irreducibly LLM
    judgment** (the operational analog of teach-back's engine-narration limb; f012 already
    marks that limb as runtime-anchored, not CI-scored). The act-back reviewer (M6) attempts the
    representative task over each KB at runtime; CI does **not** score the plan — it asserts the
    **substrate** (the task is well-formed; the sections are present/absent) the judgment is
    anchored to. This is the **same honest floor** REQUIREMENTS 1.6 / f012's Judgment Boundary
    commit to.

The act-back fixture therefore slots into f012's existing structure as a new `kb-essence/actback/`
case + a new mechanical regression suite assertion family (a **V-E** family alongside f012's
V-A..V-D), with the judgment half added to f012's Judgment-Boundary table as a new AC16 row. f013
defines the *shape*; f012 owns the *files + suites + the threshold-pinning* (the `[SPIKE-A1]`
task-selection heuristic is f012-calibrated, exactly like f005's CAL floors and f006's recon
thresholds are).

### Grade Aggregation

The complete exit computation, consistent with f005 + the existing `grade.sh` + ledger schema:

```
1. SIX mandate reviewers (M1..M6) run in parallel, each writing discovery-<mandate>.md.
   M4 teach-back writes [HIGH] [TEACHBACK] rows; M6 act-back writes [HIGH] [ACTBACK] rows
   (plan-correctness FAILs AND sufficiency FAILs alike — NO separate verdict sentinel for either).
2. Orchestrator MERGES all six scratch ledgers into the single discovery.md (stable per-mandate
   # IDs Mi-NNN/TB-NNN/AB-NNN; [Mi]/[TEACHBACK]/[ACTBACK] description prefixes), then deletes
   the six transient scratch ledgers.
3. grade  = grade.sh discovery.md            # EXISTING grader, worst-severity-dominates,
                                              # counts Status in {Pending,Recurred} only.
                                              # Any open [HIGH] [TEACHBACK] OR [ACTBACK] row forces <= D.
4. READY iff grade >= minimum_grade          # single gate; an open teach-back OR act-back gap is a
                                              # [HIGH] row, so it already makes grade < minimum_grade.
                                              # No second boolean, no AND/OR to reconcile.
5. verdicts (reporting only) = teach-back FAIL iff any open [TEACHBACK] row; act-back FAIL iff any
                               open [ACTBACK] row.
6. STATE + exit print report the TRIPLE: "Grade: <g> | Teach-back: <v> | Act-back: <v> -> <Ready|NOT>".
```

This is fully consistent with the reviewer-ledger schema (one `<scope>.md`, 7-column table,
Status-filtered grading) and `grade.sh` (worst-severity dominates, modifier by count) — f013
adds **no new grade computation**; it adds **one** more input dispatch (5→6 reviewers → 1 ledger)
and encodes the sibling act-back keystone as `[HIGH] [ACTBACK]` rows the **existing** grader
already enforces (no separate boolean gate, no `AND`/`OR`). The `minimum_grade` resolution is
unchanged (`read-setting.sh --skill discover --key minimum_grade --default A`). Confirmed against
`grade.sh` (`.claude/aid/scripts/grade.sh` lines 132-139): a single `HIGH` row → `D$(modifier)`,
already `< minimum_grade`.

### Affected Components

| Component | Path | Change |
|-----------|------|--------|
| REVIEW flow | `canonical/skills/aid-discover/references/state-review.md` | **Additive edit to f005's panel orchestration:** Step 1 mandate loop gains **M6 (act-back)** (5→6 parallel dispatches, full-panel default, same A3 sequential degradation); Step 1b appends M6's FOCUS body + the `kb-actback-task.sh` representative-task spec + the operational-structure presence-check output; Step 1d adds the `discovery-actback.md` scratch ledger. Step 2 merges the 6th scratch ledger into the single `<scope>.md`, runs the **unchanged** `grade.sh`; the act-back gate is realized via the merged `[HIGH] [ACTBACK]` rows (no separate verdict sentinel). Step 3 exit print/STATE report the **(grade, teach-back, act-back) triple** (act-back derived from open `[ACTBACK]` rows). Clean-context + contamination blocks preserved (stronger for M6, like M4). **Reuses f005's `{{SCOPE}}` + doc-set seam verbatim** (M6 grades whatever doc-set is injected; f008's `aid-update-kb` reuses M6 with its own scope, no f013 work). |
| Act-back mandate prompt body | `canonical/skills/aid-discover/references/reviewer-prompt-actback.md` (NEW) | The M6 FOCUS body: clean-context "given ONLY the KB + the representative task, produce the plan AND flag every insufficiency"; the two limbs (plan-correctness + sufficiency); the four insufficiency classes (convention/invariant/gotcha/contract); the binary bar; **output redirection** — write findings to its **own scratch ledger** `.aid/.temp/review-pending/discovery-actback.md` (the 7-column ledger schema), NOT STATE.md (the orchestrator-only-orchestrates rule f005 establishes). `reviewer-prompt.md`'s thin index (f005) gains an M6 row. |
| Representative-task + structure helper | `canonical/aid/scripts/kb/kb-actback-task.sh` (NEW) | (1) Emits the representative-task spec from the **machine-readable** substrate (the resolved `discovery.doc_set` filenames + `present\|absent` status + the operational sections actually present); the concern→task-shape mapping is a documented tuning HINT (the resolver TSV carries **no** concern field — `filename<TAB>owner<TAB>presence` only), and the task-shape heuristic is f012-calibrated ([SPIKE-A1]). (2) the operational-structure presence check, **scoped per f003's owning-table to the classes each doc is expected to carry** (greps the named operational sections per Full-Primary doc → `doc \| class \| present\|absent`). Pure coreutils, ASCII, stable-sorted, byte-reproducible. No LLM. Sited at `canonical/aid/scripts/kb/` (the `aid/` segment is mandatory — see the implementer path-guard note below). |
| Doc model (operational guidance first-class) | `canonical/aid/templates/kb-authoring/concern-model.md` + `principles.md` | **Extends f003.** Add the "Operational guidance is first-class structure" subsection to `concern-model.md` (the four classes → named greppable sections → owning concerns table) + a cross-ref principle line in `principles.md`. **No** f003 machinery change (concern list, seed mapping, resolver untouched). |
| Expectations (operational open-question) | `canonical/skills/aid-discover/references/document-expectations.md` | **Extends f003.** Add an **operational open-question** to the relevant docs' entries ("what must a newcomer follow / never break / watch out for / satisfy — conventions, invariants, gotchas, contracts?") so the researcher surfaces operational guidance as the named section. Prose addition; same `### <filename>` keying, no parser change. |
| Review rubric | `canonical/aid/templates/kb-authoring/review-rubric.md` | Add the **`[ACTBACK]`** tag (HIGH) to the "Lint output -> severity mapping" table, beside f005's `[TEACHBACK]` (L255), using the **verbatim row** specified in The Mechanical Helper + new finding tag (it carries the inline "any open `[ACTBACK]` row forces grade <= D" clause, mirroring the `[TEACHBACK]` row). The category routing + existing rubrics + f005's mandate/calibration sections are unchanged. |
| CI — canonical suite | `tests/canonical/test-actback-task.sh` (NEW) | Assert `kb-actback-task.sh` emits the representative task deterministically + byte-reproducibly, and the operational-structure presence check reports present/absent correctly over a small in-suite fixture. Auto-discovered by `tests/run-all.sh`'s `tests/canonical/test-*.sh` glob. The end-to-end act-back fixture (pass/fail KB pair) + its judgment-anchored assertions are **f012**'s (the act-back fixture joins f012's `kb-essence/` corpus). |
| CI — ascii-only | `tests/canonical/test-ascii-only.sh` | Add **`kb-actback-task.sh`** to `SHIPPED_SCRIPTS` (C2). |
| render-drift | `test.yml` job `render-drift` | No edit; stays green by editing canonical only + re-running `run_generator.py` (the new `reviewer-prompt-actback.md` reference, the new `scripts/kb/kb-actback-task.sh`, the `state-review.md` / `concern-model.md` / `principles.md` / `document-expectations.md` / `review-rubric.md` edits render to all 5 trees). |

> **Implementer path-guard (do not copy f005's wrong invocation path).** The new
> `kb-actback-task.sh` is sited at **`canonical/aid/scripts/kb/kb-actback-task.sh`** (the `aid/`
> segment is mandatory — its siblings `closure-check.sh` / `kb-teachback-questions.sh` live there).
> When authoring the M6 dispatch into `state-review.md`, **invoke the helper (and reference its
> siblings) with the full `canonical/aid/scripts/kb/...` form and the render-token convention the
> working `state-generate.md` / `state-closure.md` already use** — do **NOT** copy f005's as-built
> `state-review.md` mistake, which invokes its siblings as `canonical/scripts/kb/closure-check.sh`
> (missing the `aid/` segment; an existing f005 path bug, not f013's). The correct path is the one
> in the Affected-Components row above.

### Constraints

- **C2 / Q2 — ASCII-only.** The **one** new script (`kb-actback-task.sh`) vendors into the
  install bundles → ASCII-only bash (PS-5.1 N/A). Added to `test-ascii-only.sh`'s allow-list.
  The new `reviewer-prompt-actback.md` + the `concern-model.md`/`principles.md`/
  `document-expectations.md`/`review-rubric.md` edits are markdown (not ASCII-gated, but kept
  ASCII for sibling consistency).
- **C1 / NFR-8 — no new runtime.** The one new script is pure coreutils (`grep`/`awk`/`sort`) —
  the toolset f004/f005's siblings already use. No embedding model, binary, MCP, or
  `python3`/`pwsh` escalation. The panel reuses the **existing** `aid-reviewer` agent +
  `grade.sh` + reviewer-ledger schema — **no new grading runtime, no new grade computation**.
- **C3 / NFR-4 — render-drift green.** All authored files are canonical (the new
  `reviewer-prompt-actback.md`, `state-review.md` edit, `kb-actback-task.sh`, the
  `concern-model.md`/`principles.md`/`document-expectations.md`/`review-rubric.md` edits). Edit
  canonical only; re-run `python .claude/skills/generate-profile/scripts/run_generator.py`;
  commit regenerated `profiles/` (render-drift-full-generator precedent). **[SPIKE-A2]** —
  verify the renderer auto-emits the net-new `reviewer-prompt-actback.md` reference + the new
  `scripts/kb/kb-actback-task.sh` to all 5 trees (it enumerates the tree; expected yes); if an
  emission manifest pins the `aid-discover/references/` or `scripts/kb/` list, regen, never
  hand-place.
- **C5 / NFR-3 — deterministic, CI-testable + evidence-anchored.** `kb-actback-task.sh`
  (representative-task selection + operational-structure presence check) and `grade.sh` are
  mechanical, stable-sorted, byte-reproducible (the script asserted in f013's new suite; the
  end-to-end fixture in f012). The representative task is a **fixed** input keyed to the
  **machine-readable** doc-set substrate (filenames + presence + present operational sections;
  **not** a concern field — the resolver emits none, so the concern mapping is a tuning hint, not
  a runtime input); the task-shape heuristic is the calibrated surface ([SPIKE-A1]). The
  irreducible judgment — act-back's **plan-correctness** limb ("can the
  KB support a correct plan") and **sufficiency** limb's well-foundedness ("is this flag real")
  — is the named, minimized LLM surface, the operational analog of teach-back's engine-narration
  judgment, anchored to the fixed task + the presence-check evidence (NFR-3 honest floor; see
  the Judgment split in The Fixture).
- **NFR-2 — wall-clock / parallel panel.** M6 is **one more parallel dispatch** on f005's
  existing fan-out (one message, now 6 dispatches), so the sequential critical path stays at one
  reviewer's wall-clock, not six (A3: degrade to sequential where parallel dispatch is
  unavailable). The presence-check helper is a single sub-second script pass (no dispatch).
- **NFR-1 — cost.** The panel grows from 5 reviewer dispatches to 6; this is the deliberate cost
  f006 *scales down* per path (brownfield-small collapses M6 into the single checklist reviewer).
  For brownfield-large the extra reviewer is justified by the operational-actionability axis
  (REQUIREMENTS NFR-1); the mechanical evidence (`kb-actback-task.sh`) is zero-token deterministic
  substrate, holding the LLM surface to the irreducible plan/flag judgment.
- **C4 — human-gated.** REVIEW grades + flags; the human approval gate (`state-approval.md`) is
  unchanged. An act-back FAIL (a missing convention/invariant/gotcha/contract) routes to FIX (or,
  where the operational guidance is genuinely ungroundable from the artifacts, to f004's
  human-Q&A escape hatch), never auto-resolves.
- **C6 — content-isolation.** The new script is namespaced under `aid/scripts/kb/`; M6's scratch
  ledger lives under the gitignored `.aid/.temp/review-pending/` (existing isolated tree); the
  merged ledger is the existing `<scope>.md` (`discovery.md` for `aid-discover`).
- **C8 — skill conventions.** No skill router change; f013 edits `references/` snippets +
  templates + adds one `scripts/kb/*.sh`, preserving the thin-router `SKILL.md` + `references/`
  state-machine pattern.

### Spikes (genuine unknowns flagged, not guessed)

- **[SPIKE-A1]** Representative-task selection heuristic — the exact mapping from a project's
  **machine-readable KB profile** (the resolved `discovery.doc_set` filenames + `present|absent`
  status + the operational sections actually present) → the representative change
  `kb-actback-task.sh` emits is **f012-calibrated** against the act-back fixtures: the fixture pins
  that the selected task is *representative* (a real change for this project shape) and *well-formed*
  (the reviewer can attempt it). f013 fixes the **deterministic substrate** (the script reads only
  filenames + presence + present sections — **not** a concern field, which the resolver TSV does not
  emit; the concern mapping is a documented tuning hint) and the *shape* (key off the project's own
  KB profile, byte-reproducibly); f012 tunes the **task-shape heuristic** (which file/section
  profile → which task) — the one non-mechanical element here. The judgment half (does the plan
  succeed) is runtime-anchored, not a pinned threshold.
- **[SPIKE-A2]** Net-new reference + script render — verify `run_generator.py` emits the net-new
  `reviewer-prompt-actback.md` and the net-new `scripts/kb/kb-actback-task.sh` to all 5 trees (it
  enumerates the tree); if any emission manifest pins the `aid-discover/references/` or
  `scripts/kb/` file list, update canonical + regen, never hand-place (render-drift-full-generator
  precedent).
- **[SPIKE-A3 — boundary, panel scaling]** The collapse of the full panel to fewer reviewers
  (down to 1 checklist-reviewer) for brownfield-small is **f006**'s wiring. f013's M6 joins the
  per-mandate dispatch list f006 scales (the act-back checks fold into the single reviewer's
  checklist on collapse, exactly as the other mandates do). Confirm with PLAN.md that f005 (the
  panel) and this feature (M6) land before/with f006's path→panel-size wiring
  (provide-before-consume); if M6 lands after f006, f006's collapse list must learn M6.
- **[SPIKE-A4 — sequencing]** f013 extends **f005** (the panel orchestration + the merged-ledger
  + `[TEACHBACK]` encoding it adds M6 alongside) and **f003** (the doc model it adds the
  operational-structure rule to), and consumes **f001**'s `sources:` (only to let M6 say "the KB
  defers this to source"). Confirm with PLAN.md that **f001 + f003 + f005 land before f013**
  (consume-after-define / extend-after-base); if f013 is sequenced earlier, the panel has no
  M6 slot to graft onto and the doc-model rule has no `concern-model.md` to extend. f013's
  fixture is **built + exercised by f012**, so confirm **f013 lands before f012**'s act-back
  assertion family (provide-before-exercise), mirroring f005→f012 / f006→f012.
- **[SPIKE-A5 — boundary, fixture ownership]** The act-back **fixture corpus** (the
  representative-task spec fixture + the `actback-pass-kb`/`actback-fail-kb` pair) and its
  regression assertions (the **V-E** family + the AC16 Judgment-Boundary row) are **f012**'s —
  f013 ships only `kb-actback-task.sh`'s small in-suite unit fixture (`test-actback-task.sh`).
  Confirm with PLAN.md that f013's in-suite fixture and f012's corpus do not duplicate/diverge
  (ideally the same files: f012's corpus is the single source; f013's unit suite points at it),
  exactly the f005/f006↔f012 [SPIKE-V3] arrangement.
