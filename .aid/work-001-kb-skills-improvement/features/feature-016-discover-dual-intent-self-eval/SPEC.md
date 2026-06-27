# Discover dual-intent KB self-evaluation + spine-keyed domain-general depth

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-25 | Feature authored to make `/aid-discover` produce KBs that work **off-software**, not only on the two domains AID dogfooded. feature-014 generalized discovery's *architecture* (the domain-agnostic spine + the domain→doc-set matrix) but left two depth/sufficiency mechanisms **filename-keyed and software-only**: (1) the per-doc **depth contract** in `document-expectations.md` is keyed by `### <filename>` and has entries for only **22** of the **58** unique doc filenames the domain→doc-set matrix can emit, leaving a **36-doc dangling-anchor gap** (basis: 58 matrix-emittable filenames − 22 covered = 36; the 36 include the **shared** `glossary.md` and `tooling-stack.md` plus all data-ml/content/research/design/ops domain docs — `data-schemas.md`, `data-pipeline.md`, `model-cards.md`, `content-model.md`, `style-guide.md`, `design-tokens.md`, `design-system.md`, `evidence-sources.md`, `methodology.md`, `config-schemas.md`, …) → the GENERATE custom-doc prompt points the researcher at a **dangling anchor** for every one of those, so those docs get only the generic spine question with no work-actionable depth contract (VERIFIED against `state-generate.md` §2.6); (2) `kb-actback-task.sh`'s representative-task selector and its `_doc_expects_class` owning-table are **filename-keyed software-only** → on a data/design doc-set the task degrades to "add an endpoint" and the operational-class presence check is **empty** (VERIFIED by reading the script). A modest **altitude-rule signature tax** also pushed some load-bearing operational contracts (field types, exit codes) out of the docs behind a bare `sources:` pointer. The **unifying fix** is to lift everything domain-specific from **filename-keyed → spine-dimension-keyed** (the matrix already carries the spine-dimension per doc) and to **derive the self-evaluation probes from the project's own source + capabilities** — yielding a **Dual-Intent KB Self-Evaluation** mechanism that measures both user intents (an agent can do quality work from the KB alone; a human can reconstruct the true essence from the KB alone) as domain-general REVIEW gates with **no external test corpus**. Four deliveries: D-013 spine-keyed depth contracts → D-014 generalize the safeguard → D-015 the dual-intent self-eval → D-016 altitude signature exception + dogfood + re-inject AID's lost depth. Grounded in the two critique rounds (`kb-comparison-verdict.md` + `kb-generator-verdict.md`) and the 2026-06-25 user intent. | user decision |

## Source

- REQUIREMENTS.md §5.L (FR-52–FR-56, NEW)
- REQUIREMENTS.md §5.J (FR-37–FR-44 — the feature-014 domain-driven discovery this feature deepens: the generic-core spine, the domain→doc-set matrix, the dual-audience authoring standard), §1.2 (KB value = the *delta* a newcomer cannot infer), §1.3 (the universal newcomer concerns = the spine)
- **Design seed (authoritative):** `.aid/design/aid-discover-dual-intent-self-eval.md` — the verified problem (filename-keyed/software-only depth contract + safeguard; the altitude-rule signature tax), the two intents → two measurable self-run gates, the unifying spine-keyed + self-sourced principle, the §4 Dual-Intent KB Self-Evaluation mechanism (Blind Work-Simulation = Intent 1; Blind Reconstruction + Source Confrontation = Intent 2), the §5 supporting fixes, the §6 fixture-based validation, and the §7 four-delivery phasing.
- **Extends / deepens:** feature-014 (`concern-model.md`'s 11-dimension spine + owning-table; `domain-doc-matrix.md`'s per-doc spine-dimension column; `document-expectations.md` keyed by `### <filename>`; `state-generate.md` §2.6 custom-doc prompt). Builds on feature-013 (the M4 act-back keystone + `kb-actback-task.sh`) and feature-005's M3 teach-back keystone — generalizing both panel mandates from software-only to spine-keyed + self-sourced + dual-intent-explicit.
- **Evidence (load-bearing anchors):** `document-expectations.md` (**22** `### <filename>` entries covering 22 of the 58 matrix-emittable filenames; **36 dangle** — incl. the shared `glossary.md`/`tooling-stack.md` + all data-ml/content/research/design/ops domain docs) · `state-generate.md` §2.6 custom-doc prompt ("per its expectations entry in references/document-expectations.md (keyed by ### <filename>)") · `kb-actback-task.sh` `_doc_expects_class` (filename-keyed software-only owning-table) + `_run_task` heuristic (falls to `task_type="endpoint"` off-software) · `concern-model.md` "Operational guidance is first-class structure" owning-table (the single-source the script encodes, filename-keyed today) · `domain-doc-matrix.md` (every doc row carries a `spine-dimension` column C0–C9/D/meta) · `principles.md` P1(d) + the altitude/summary+pointer rule (the signature-exception target) · `reviewer-prompt-actback.md` / `reviewer-prompt-teachback.md` (the M4/M3 keystone bodies the dual-intent eval generalizes) · `tests/canonical/fixtures/actback-task/` (the existing in-suite TSV-docset + mini-KB fixture pattern the §6 fixtures extend).

## Description

feature-014 made `/aid-discover` **domain-general in architecture**: a domain-agnostic
**dimension spine** (C0–C9 + D), a curated **domain→doc-set matrix** that maps each domain to
the docs it should produce, and a **research fallback** for novel domains. But two mechanisms
that make a KB *useful* — not just present — were left **software-only in content**:

| Mechanism | What it does | Why it is software-only today |
|---|---|---|
| **Depth contract** (`document-expectations.md`) | Tells the researcher what *work-actionable depth* each doc must reach (the shapes + how-to-extend for a schema doc; the actual conventions for a standards doc) — the difference between a doc that exists and a doc an agent can act on. | Keyed by `### <filename>`. **22 docs** have expectations entries; **36 of the 58 matrix-emittable filenames dangle** (incl. the shared `glossary.md`/`tooling-stack.md` + all non-software domain docs), so the GENERATE custom-doc prompt points at a **dangling anchor** and those docs get only the generic spine question. |
| **Sufficiency safeguard** (`kb-actback-task.sh` + the M4 act-back gate) | Generates a *representative task* and checks the KB carries the operational guidance (conventions / invariants / gotchas / contracts) an agent needs to do it. | The task selector and the `_doc_expects_class` owning-table are **filename-keyed**. Off-software the task degrades to "add an endpoint" and the presence check is **empty** — the gate is provably inert. |

**Root cause (one sentence):** the depth layer and the sufficiency gate were authored for the two
domains AID dogfooded; the breadth layer was designed general — **breadth ran ahead of depth.**

This feature closes that gap with one principle and one mechanism.

**The principle — lift filename-keyed → spine-dimension-keyed, and derive the self-eval probes
from the project's own source + capabilities.** The spine (C0–C9 + D) is already the
domain-general abstraction, and the matrix already records *which spine dimension every doc
realizes*. So "the C5 doc — whatever it is named (`schemas.md`, `data-schemas.md`,
`content-model.md`, `design-tokens.md`, `config-schemas.md`) — must carry the data shapes +
types + constraints + how to add one; the C3 doc must carry the project's actual conventions" is
a **domain-general depth contract authored once per spine dimension**, not once per filename.
The same re-keying makes the safeguard's owning-table fire on whatever doc realizes a dimension
in this project's doc-set. And because the self-evaluation derives its probes from the project
itself (its source = ground truth; its C9 capability doc = task seeds), it adapts to any domain
with **no anticipated per-domain content and no external test corpus** — the project *is* the test.

**The mechanism — the Dual-Intent KB Self-Evaluation.** The two user intents become two
measurable, self-run REVIEW gates, generalizing the existing M4 (act-back) and M3 (teach-back)
keystones to be spine-keyed + self-sourced + dual-intent-explicit:

| Intent | Operationally | The gate |
|---|---|---|
| **(1) An agent can do the work with assertiveness + quality** | A clean-context, KB-only agent can plan **and** complete a representative task in the project's **own conventions**, without guessing or reaching for source, honoring the project's conventions/invariants/quality bars. | **Blind Work-Simulation** (generalized act-back) — the *assertiveness* gate. |
| **(2) The KB is a faithful reference of the project's true essence, for humans** | A clean-context reader can reconstruct the project's essence (what / how / why) from the KB alone, and that reconstruction **matches the source** — no load-bearing omission, no divergence from reality. | **Blind Reconstruction + Source Confrontation** (generalized teach-back + fidelity) — the *essence* gate. |

Both run **on the project being discovered**, using **its own source as ground truth** and **its
own capabilities as task seeds** — so a data / design / content project self-calibrates its own
probes and self-grades against its own source, exactly as AID's software KB does today.

Three **supporting fixes** give the gates a concrete depth standard to drive the FIX loop toward:
spine-keyed depth contracts (closes the dangling-anchor gap once, domain-generally); spine-keyed
safeguard wiring (the owning-table + task-shapes re-keyed to dimensions); and an
**altitude-rule signature exception** (load-bearing operational contracts an agent must honor to
ACT — field types, exit codes, args/modes/invariants — are stated INLINE or with a precise
grep-recoverable anchor, never a bare `sources:` file pointer).

Because there are **no in-the-wild non-software projects** to test on, the mechanism's generality
is proven with **fixtures** (§6): per-domain GOOD mini-KBs (must PASS both gates) and SHALLOW/WRONG
mini-KBs (must FAIL the right limb), extending the existing in-suite `actback-task` fixture pattern.
AID itself (software + methodology) is the **live regression dogfood**.

## User Stories

- As an **AI agent doing work on a non-software project** (a data-ml pipeline, a design system,
  a content site), I want the KB to carry the same work-actionable depth a software KB carries —
  the data shapes and how to extend them, the project's actual conventions, the invariants and
  quality bars — so I can plan and complete a representative change **from the KB alone**, in the
  project's own conventions, without guessing or reaching for source.
- As a **human reading the KB to understand a project** (a newcomer, a stakeholder, a reviewer),
  I want the KB to faithfully convey the project's **true essence** — what it is, what it does,
  how it is shaped, and why — with **no load-bearing omission and no divergence from reality**, so
  the KB is a trustworthy reference instead of a partial or wrong picture.
- As an **AID maintainer**, I want a **single, domain-general depth and sufficiency standard**
  keyed to the spine dimension (not to a filename), so adding a new domain to the matrix does
  **not** require hand-authoring a new per-filename depth contract or extending a software-only
  owning-table — the dimension's standard is inherited automatically.
- As an **AID maintainer**, I want the KB's two intents to be **measured, enforced REVIEW gates**
  that run for **any** domain and need **no external test corpus** — the project's own source and
  capabilities are the test — so the assertiveness and essence guarantees hold off-software, not
  only on the two domains AID dogfooded.
- As an **AID maintainer**, I want the generality of the gates **proven by fixtures** (GOOD KBs
  pass, SHALLOW/WRONG KBs fail the right limb) and continuously **regression-tested by dogfooding
  on AID itself**, so a future change cannot silently re-introduce the software-only blind spot.

## Priority

Must

## Acceptance Criteria

- [ ] **(Spine-keyed depth contracts — closes the dangling-anchor gap)** Given a doc-set resolved
  from any matrix domain (software, data-ml, content, research, design, ops, methodology-tooling)
  or an auto-researched set, when GENERATE computes the custom-doc prompt for a doc, then **every**
  doc in the doc-set resolves to a **non-empty, work-actionable depth contract via its spine
  dimension** (the C5 doc carries the shapes/types/constraints + how-to-extend; the C3 doc carries
  the actual conventions + examples + red-flags; etc.) — **no doc is pointed at a dangling
  `### <filename>` anchor**, including the **36** of 58 matrix-emittable filenames that dangle today
  (basis: 58 emittable − 22 covered; incl. the shared `glossary.md`/`tooling-stack.md` + all
  non-software domain docs). *(FR-52)*
- [ ] **(Spine-keyed safeguard fires off-software)** Given a **non-software** doc-set (e.g. the
  `data-ml` or `design` row), when `kb-actback-task.sh` runs, then it emits a **domain-appropriate
  representative task** (e.g. "add a feature to «pipeline Y» / a column to «dataset Z»", "add a
  token / a component variant") — **not** the default "add an endpoint" — and the operational-class
  **presence check is non-empty**, firing on whatever doc realizes the owning dimension (the C5 doc
  for Contracts, the C3 doc for Conventions, the C2 doc for Conventions/Parts, the C7 doc for
  Gotchas) — keyed by **spine dimension**, single-sourced from `concern-model.md`. *(FR-53)*
- [ ] **(Dual-Intent Self-Eval — Intent 1, assertiveness limb)** Given the REVIEW state on any
  domain, when the **Blind Work-Simulation** limb runs, then a clean-context KB-only agent plans
  each derived work probe step-by-step in the project's own conventions, tagging each step
  **STATED / ASSUMED / REACH**; any **load-bearing ASSUMED/REACH** is a `[HIGH] [ACTBACK]`
  insufficiency (FAIL → FIX target), and a plan that would "work" but violates the project's
  **conventions (C3) / invariants / quality bars (C6)** is a **quality FAIL**; PASS = a complete,
  correct, convention-honoring plan with zero load-bearing insufficiencies. *(FR-54)*
- [ ] **(Dual-Intent Self-Eval — Intent 2, essence limb)** Given the REVIEW state on any domain,
  when the **Blind Reconstruction + Source Confrontation** limb runs, then a clean-context KB-only
  agent reconstructs the project's what/why/how essence from the KB alone, and a second
  **source-grounded** agent confronts that reconstruction against the actual project: a **Divergence**
  (KB-only answer WRONG vs source) is a `[HIGH] [FIDELITY]` FIX target, and a load-bearing
  **Omission** (a source fact the reconstruction could not supply) is a `[MED] [ESSENCE-GAP]` FIX
  target; PASS = no divergence + load-bearing essence-coverage ≥ threshold. *(FR-55)*
- [ ] **(Dual-intent ledger + convergence as enforced keystone gates)** Given the REVIEW⇄FIX loop,
  when the panel emits its **dual-intent ledger**, then both limbs are **hard keystone gates** (a
  FAIL caps the grade, as M3/M4 are today): **Assertiveness** passes only at zero `[HIGH] [ACTBACK]`
  + STATED-coverage ≥ threshold + all quality-contracts present; **Essence** passes only at zero
  `[HIGH] [FIDELITY]` + essence-coverage ≥ threshold — domain-generally, for any doc-set. *(FR-54,
  FR-55)* **The concrete PASS thresholds (assertiveness % STATED, essence-coverage %) are a
  deliberate scoping deferral — calibrated in DETAIL / D-015 against the AID dogfood + the per-domain
  fixtures (start strict: zero HIGH, ≥90% STATED), not omitted; this SPEC fixes the gate shape, DETAIL
  fixes the number.**
- [ ] **(Altitude-rule signature exception)** Given the KB authoring rules, when a doc carries a
  **load-bearing operational contract an agent must honor to ACT** (field types, exit codes, the
  args/modes/invariants), then that contract is stated **INLINE or with a precise grep-recoverable
  anchor** — **never** a bare `sources:` file pointer; the altitude/summary+pointer rule continues
  to de-bloat *narrative* volatility but **not** work-critical contracts (and the assertiveness
  limb enforces this automatically — if the agent must REACH for it, it FAILs). *(FR-56)*
- [ ] **(Fixture validation proves the gates fire off-software)** Given **fixture** mini-KBs per
  non-software domain in two variants — a **GOOD** KB (work-actionable depth + faithful essence)
  and a **SHALLOW/WRONG** KB (omits field types / diverges from a fixture "source") — when the
  suite runs, then: the probe derivation produces a **domain-appropriate** task (not "add an
  endpoint"); the owning-table presence check **fires on the domain's C5/C3/etc. doc**; the
  assertiveness limb **FAILs the SHALLOW KB** on the missing contract; and the essence limb
  **FAILs the WRONG KB** on divergence — proving the gates fire correctly off-software (the exact
  thing broken today). *(FR-52–FR-56)*
- [ ] **(Dogfood regression)** Given AID's own KB (software + methodology), when the dual-intent
  eval runs as the live regression, then it passes both gates; the AID instance's previously
  altitude-rule-evicted depth (e.g. host-tool matrix, exit-codes) is **re-injected** as the first
  beneficiary of the signature exception. *(FR-56)*
- [ ] **All section-6 quality gates pass:** canonical→render parity (full `run_generator.py`),
  dogfood byte-identity (DBI — the canonical→`.claude` render-parity check for D-013/014/015, which
  touch only `canonical/` sources; **plus** the `.aid/knowledge/*` doc-content sync for **D-016**,
  the only delivery that re-injects depth into AID's own KB docs), ASCII-only + WinPS-5.1 lint for
  any shipped/changed script, and the new + affected canonical suites (matrix, actback-task,
  actback-fixtures, the new dual-intent fixtures) re-run green.

---

## Technical Specification

> Design of record for feature-016. Realized across **four deliveries** — delivery-013
> (spine-keyed depth contracts) → delivery-014 (generalize the safeguard) → delivery-015 (the
> dual-intent self-eval) → delivery-016 (altitude signature exception + dogfood + re-inject), on
> branches `aid/work-001-delivery-013..016`. This feature **deepens** feature-014's
> domain-driven discovery; it does not re-spec the spine, the matrix, or the classifier.
> **This SPEC is scoping only** — it defines the HOW and the affected files; it does NOT modify
> the skill yet (the deliveries' tasks do, authored by `/aid-detail`).
>
> **Path anchor (DBI safety) — read this before editing any file below.** The real, editable
> sources live under `canonical/` and are **rendered** into `.claude/` (which is generated —
> never edit it directly, or DBI breaks). The affected-file lists below cite canonical paths.
> DETAIL/EXECUTE edit `canonical/...`, then regen via the full `run_generator.py` — never the
> rendered `.claude/` copy.

### 0. The one principle that drives everything

**Lift everything domain-specific from FILENAME-keyed → SPINE-DIMENSION-keyed, and derive the
self-evaluation probes from the project's own source + capabilities.** The matrix
(`domain-doc-matrix.md`) already records the `spine-dimension` of every doc in every row, and
`state-generate.md` §2.6 already maps each custom doc to "exactly one spine dimension (C0–C9, D,
or meta)". So the keying substrate already exists — this feature consumes it. Every change below
is an application of this principle.

### 1. Spine-keyed depth contracts (Change 1, D-013) — FR-52

**Today (the defect, VERIFIED):** `document-expectations.md` is keyed by `### <filename>`, with
entries for **22** of the **58** unique doc filenames the matrix can emit — a **36-doc
dangling-anchor gap** (basis: 58 matrix-emittable filenames − 22 covered = 36). `state-generate.md`
§2.6's custom-doc prompt extension appends, for each custom doc:
`Also produce .aid/knowledge/<filename> per its expectations entry in
references/document-expectations.md (keyed by ### <filename>).` The 36 uncovered filenames span the
**shared** `glossary.md` and `tooling-stack.md` plus all data-ml/content/research/design/ops domain
docs (`data-schemas.md`, `data-pipeline.md`, `model-cards.md`, `content-model.md`, `style-guide.md`,
`design-tokens.md`, `design-system.md`, `evaluation-landscape.md`, `evidence-sources.md`,
`methodology.md`, `analysis-conventions.md`, `config-schemas.md`, `ops-conventions.md`,
`platform-topology.md`, domain `*-inventory`/`*-overview` C9 docs, …) — for each there is **no**
`### <filename>` entry → the prompt points at a **dangling anchor** and the doc gets only the
generic spine question.

**Redesign:**
- Author a **per-spine-dimension, work-actionable depth standard** — once per dimension, not once
  per filename. The standard for each dimension states what a doc realizing that dimension MUST
  carry to be *work-actionable*, generalizing today's best software entries:
  - **C5 Data & contracts:** the shapes / fields / types / constraints **+ the extension procedure
    (how to add/change one)** — generalizes `schemas.md`'s "show relationships + how entities
    connect" to `data-schemas.md`, `content-model.md`, `design-tokens.md`, `config-schemas.md`.
  - **C3 Conventions:** the project's **actual rules + concrete examples + red-flags** ("convention
    named but no example" = red flag) — generalizes `coding-standards.md` to `style-guide.md`,
    `analysis-conventions.md`, `ops-conventions.md`, `authoring-conventions.md`,
    `design-principles.md`.
  - **C2 Parts & connections:** the parts, how they connect, **how to add a part**.
  - **C6 Quality & checking:** how work is graded/validated + the bars to meet.
  - **C0 / C1 / C4 / C7 / C8 / C9 / D** similarly (technology+build/lint commands; structure +
    invariants; vocabulary + conceptual invariants; risk/debt + gotchas; ship/operate; capabilities
    + how-invoked; decisions + rationale + rejected alternatives).
- **Re-point the GENERATE custom-doc prompt at the spine-dimension standard.** Each doc inherits
  its **dimension's** depth standard (resolved via the matrix's `spine-dimension` column / the
  §2.6 dimension mapping), specialized to its actual content — so a doc with no per-filename entry
  still receives a non-empty, work-actionable contract. Per-domain *refinements* for curated matrix
  domains stay **optional and additive** (a filename entry, when present, layers on top of the
  dimension standard; it never replaces it).
- **Decision (seed §8):** the spine-dimension depth standard is authored as a **new section keyed
  by spine dimension** — preferred form is a new `### C<N> — <dimension>` block set within
  `document-expectations.md` (keeping one authority file) **or** a sibling
  `spine-depth-expectations.md`; DETAIL picks the lower-churn form. Either way the §2.6 prompt
  resolves doc → dimension → standard.

**Affected files:** `canonical/skills/aid-discover/references/document-expectations.md` (add the
per-spine-dimension depth standard; the existing `### <filename>` entries become optional
refinements), `canonical/skills/aid-discover/references/state-generate.md` §2.6 + the custom-doc
prompt line (resolve doc → spine dimension → standard, not a bare filename anchor),
`canonical/skills/aid-discover/references/agent-prompts.md` § "Custom-Doc Runtime Extension" (the
full protocol prose), `canonical/aid/templates/kb-authoring/concern-model.md` /
`domain-doc-matrix.md` (cross-reference the dimension depth standard).

### 2. Spine-keyed safeguard wiring (Change 2, D-014) — FR-53

**Today (the defect, VERIFIED):** `kb-actback-task.sh`'s `_doc_expects_class` owning-table is
filename-keyed software-only (`Conventions → coding-standards.md|module-map.md|pipeline-contracts.md`;
`Contracts → schemas.md|pipeline-contracts.md|integration-map.md`; etc.), and `_run_task`'s
`task_type` heuristic checks for `schemas.md`/`module-map.md`/`feature-inventory.md`/… and falls
through to `task_type="endpoint"` when none match. On a `data-ml`/`design` doc-set the presence
check emits **zero rows** and the task is "add an endpoint" — provably inert.

**Redesign:**
- **Re-key `_doc_expects_class` from filenames → spine dimensions.** The owning-table becomes
  "the doc realizing dimension C<N> owns class X" (C5 → Contracts; C3 → Conventions; C2 →
  Conventions/Parts; C1/C4 → Invariants; C7 → Gotchas) — single-sourced from `concern-model.md`'s
  "Operational guidance is first-class structure" owning-table, which is itself re-stated in
  dimension terms. The script reads each doc's spine dimension from the doc-set substrate so the
  check fires on `data-schemas.md` / `design-tokens.md` exactly as on `schemas.md`.
- **Carry the spine dimension into the doc-set substrate the script reads.** The doc-set TSV that
  `kb-actback-task.sh` consumes is `filename<TAB>owner<TAB>presence` (no dimension column) today.
  Add a **dimension lookup** so the script can map filename → dimension (the matrix / §2.6 mapping
  is the source); DETAIL chooses whether to extend the TSV with a 4th `spine-dimension` field or
  resolve it from a shipped filename→dimension map. The byte-stable software seed and existing
  TSV-consumers must stay green (the matrix already proves the software rows are byte-consistent).
- **C9-derived, domain-appropriate task generation (probe seed for §4.0).** Replace the
  filename-profile `task_type` heuristic with a **dimension-aware + C9-derived** selector: the task
  is "add / modify / extend «a capability the project actually has»", seeded from the **C9
  capability/what-it-does doc** of the resolved doc-set, selected to exercise the load-bearing spine
  dimensions (C5 data/contracts, C3 conventions, C2 parts, C6 quality). Software → "add a field to
  «contract X»"; data-ml → "add a feature/column to «pipeline/dataset»"; design → "add a token /
  component variant"; content → "add a content type / section"; ops → "add a service / runbook
  step". **Derived, not hardcoded.** Determinism (NFR-3) is preserved: same doc-set + same C9 doc →
  byte-identical task spec.

**Affected files:** `canonical/aid/scripts/kb/kb-actback-task.sh` (`_doc_expects_class` re-keyed to
spine dimensions; `_run_task` selector dimension-aware + C9-seeded; the doc-set substrate parse
extended with the dimension), `canonical/aid/templates/kb-authoring/concern-model.md` ("Operational
guidance is first-class structure" owning-table re-stated in spine-dimension terms as the single
source the script encodes), `canonical/skills/aid-discover/references/doc-set-resolve.md` (the
substrate / dimension-lookup contract), `canonical/skills/aid-discover/references/reviewer-prompt-actback.md`
(the four-class table + task-spec framing follow the dimension keying).

### 3. The Dual-Intent KB Self-Evaluation (Change core / §4, D-015) — FR-54, FR-55

Runs in the existing REVIEW state, alongside/replacing the current M3/M4 keystones, domain-general.

**3.0 Probe derivation (domain-general, project-self-sourced).** From the resolved doc-set + spine
+ the project source, derive:
- **Work probes (Intent 1):** K representative tasks generated from the **C9 capability/what-it-does
  doc** + the domain (Change 2's C9-derived selector is the deterministic seed), selected so the set
  collectively exercises the load-bearing dimensions (C5, C3, C2, C6). Derived, not hardcoded.
- **Essence probes (Intent 2):** "what is X / how does Y work / why Z" over the project's
  load-bearing concepts, sampled from **C4 vocabulary** + **C9 capabilities** + **D decisions**
  docs and from high-salience source facts (what a newcomer must grasp).
- **Spread + minimum-count + human-confirm:** probes are spread across spine dimensions with a
  minimum count, and the human may confirm/extend the probe set at the gate (the no-assumptions
  pattern). K scales by triage size; probes cache across REVIEW⇄FIX cycles (cost mitigation, §8).

**3.1 Assertiveness limb (Intent 1) — Blind Work-Simulation.** A clean-context KB-only agent
(no source access) plans each work probe step-by-step in the project's own conventions, tagging
each step **STATED** (KB gave the contract/convention) / **ASSUMED** (had to guess) / **REACH**
(would have to read source). Scoring: any **load-bearing ASSUMED/REACH** = `[HIGH] [ACTBACK]`
insufficiency → FAIL → FIX target. **Quality check (not just functional):** a plan that would
"work" but violates the project's conventions (C3), invariants/gotchas, or quality bars (C6) is a
**quality FAIL** — the KB failed to convey the quality contract. PASS = a complete, correct,
convention-honoring plan with zero load-bearing insufficiencies. This **generalizes** the M4
act-back mandate (`reviewer-prompt-actback.md`) from a single representative task to a derived
probe set with explicit STATED/ASSUMED/REACH tagging + a quality dimension.

**3.2 Essence limb (Intent 2) — Blind Reconstruction + Source Confrontation.** Two stages:
1. **Reconstruct (KB-only):** a clean-context agent answers the essence probes + writes a short
   what/why/how project narrative, using ONLY the KB.
2. **Confront (source-grounded):** a second agent **with source access** checks the reconstruction
   against the actual project. Two failure classes:
   - **Divergence** (KB-only answer WRONG vs source) = `[HIGH] [FIDELITY]` → FIX (the KB
     misrepresents reality).
   - **Omission** (a load-bearing source fact the reconstruction could not supply) = `[MED]
     [ESSENCE-GAP]` → FIX (the KB omits essence).
   PASS = no divergence + load-bearing essence-coverage ≥ threshold. This **generalizes** the M3
   teach-back mandate (`reviewer-prompt-teachback.md`) with an explicit **source-confrontation**
   second stage that catches divergence (not just omission).

**3.3 Spine-coverage + operational-class presence (domain-general).** Consumes Change 2's
re-keyed owning-table: the C5 doc owns Contracts, the C3 doc owns Conventions, the C2 doc owns
Parts + how-to-extend, the C6 doc owns Quality/checking, C7 owns Gotchas/debt — the presence check
fires for whatever doc realizes that dimension in this project's doc-set.

**3.4 The dual-intent ledger + convergence loop.** REVIEW runs 3.1–3.3 → emits a **dual-intent
ledger** (the 7-column reviewer-ledger schema, with `[ACTBACK]` / `[FIDELITY]` / `[ESSENCE-GAP]`
tags) → FIX deepens the flagged docs → re-REVIEW, until:
- **Assertiveness:** zero `[HIGH] [ACTBACK]`, STATED-coverage ≥ threshold, all quality-contracts
  present.
- **Essence:** zero `[HIGH] [FIDELITY]`, load-bearing essence-coverage ≥ threshold.
Both are **hard keystone gates** (a FAIL caps the grade, as M3/M4 are today) — but now
domain-general. **Threshold calibration (§8) — deliberate scoping deferral, not omission:** the
concrete PASS numbers (STATED-coverage %, essence-coverage %) are **calibrated in DETAIL / D-015**
against the AID dogfood + the per-domain fixtures; start strict (zero HIGH; ≥90% STATED) and tune
there. This SPEC fixes the gate shape; DETAIL fixes the number.

**3.5 Why no external test projects (the self-eval property).** Both limbs run **on the project
being discovered**, using **its own source as ground truth** and **its own capabilities as task
seeds** — no anticipated domain knowledge, no separate test corpus. A data/design/content project
self-calibrates its own probes and self-grades against its own source, the same way AID's software
KB does today.

**Affected files:** `canonical/skills/aid-discover/references/reviewer-prompt-actback.md`
(generalize to the Blind Work-Simulation limb with STATED/ASSUMED/REACH + quality check),
`canonical/skills/aid-discover/references/reviewer-prompt-teachback.md` (add the
Source-Confrontation second stage; `[FIDELITY]`/`[ESSENCE-GAP]` classes),
`canonical/skills/aid-discover/references/state-review.md` (wire the dual-intent ledger + the two
keystone gates + the convergence thresholds into REVIEW — **and update the verdict-derivation greps
in §2c/§2d**, which today match the literal `[TEACHBACK]`/`[ACTBACK]` strings to derive the
teach-back/act-back verdicts: the new `[FIDELITY]`/`[ESSENCE-GAP]` essence tags and the renamed
`[ACTBACK]` assertiveness tag MUST be wired into the grade aggregation so the essence verdict no
longer keys on `[TEACHBACK]` alone and the act-back/assertiveness verdict picks up the
spine-keyed insufficiencies), a **probe-derivation helper** under
`canonical/aid/scripts/kb/` (extends `kb-actback-task.sh` / `kb-teachback-questions.sh`: derive the
work + essence probe sets from the C9/C4/D docs + the doc-set; deterministic + ASCII + WinPS-safe),
`canonical/skills/aid-discover/references/state-generate.md` (REVIEW⇄FIX loop framing).

### 4. Altitude-rule signature exception (Change 3, D-016) — FR-56

**Today (the defect):** `principles.md` P1(d) + the altitude/summary+pointer rule push volatile
detail behind a `sources:` pointer. Applied too broadly, this evicted some **load-bearing
operational contracts** (the AID instance lost its host-tool matrix; schemas field-types went
16→1; exit-codes 38→17), so an agent must re-derive from source what the KB used to state.

**Redesign:** amend the altitude rule with a **signature exception**: **load-bearing operational
contracts an agent must honor to ACT** — field types, exit codes, the args/modes/invariants — are
stated **INLINE** or with a **precise grep-recoverable anchor** (the P1(d) durable-anchor form),
**never** a bare file pointer. The altitude rule keeps de-bloating *narrative* volatility; it does
**not** apply to *work-critical contracts*. The assertiveness limb (§3.1) enforces this
automatically: if the agent must REACH for a contract, it FAILs.

**Affected files:** `canonical/aid/templates/kb-authoring/principles.md` (P1(d) + the
altitude/summary+pointer rule gain the signature exception), `canonical/aid/templates/kb-authoring/concern-model.md`
(the "Operational guidance is first-class structure" section cross-references the exception),
`canonical/aid/templates/kb-authoring/tier-model.md` (the T-tier guidance on what stays inline, if
touched). **Dogfood beneficiary:** AID's own KB docs — re-inject the host-tool matrix + exit-codes
that the over-broad altitude rule evicted (the first beneficiary of the exception).

### 5. Fixture validation strategy (§6) — proves the gates generalize off-software

Because there are no in-the-wild non-software projects, validate the **machinery**, not a real KB,
with fixtures extending the existing in-suite pattern at `tests/canonical/fixtures/actback-task/`
(TSV doc-sets + a `kb/` mini-KB dir):
- **Per non-software domain (data-ml, design, content) build two mini-KB variants:** a **GOOD**
  mini-KB (work-actionable depth + faithful essence → must PASS both gates) and a **SHALLOW/WRONG**
  mini-KB (omits field types / diverges from a tiny fixture "source" → must FAIL the right limb),
  each with a matching doc-set TSV carrying its spine dimensions and a tiny fixture "source" tree
  for the source-confrontation stage.
- **Tests assert:** (a) probe derivation produces a **domain-appropriate** task (not "add an
  endpoint"); (b) the re-keyed owning-table presence check **fires on the domain's C5/C3/etc.
  doc**; (c) the **assertiveness** limb FAILs the SHALLOW KB on the missing contract; (d) the
  **essence** limb FAILs the WRONG KB on divergence. Determinism + ASCII + HOME-pinning per the
  existing suite conventions.
- **Dogfood (real):** continue running the dual-intent eval on AID itself (software + methodology)
  as the live regression, including the re-injected depth (§4).

**Affected files (tests) — fixture ownership by delivery:** new/extended
`tests/canonical/test-actback-task.sh` (non-software doc-set TSVs + dimension keying) **and its
minimal `data-ml.tsv` / `design.tsv` doc-set substrate fixtures land in D-014** (the substrate its
own owning-table + selector gate asserts against); `tests/canonical/test-actback-fixtures.sh` (the
per-domain GOOD/SHALLOW assertions), a **new `tests/canonical/test-dual-intent-self-eval.sh`** (the
essence limb + source-confrontation fixtures), and the **full per-domain GOOD/SHALLOW/WRONG mini-KBs
+ tiny source trees** under `tests/canonical/fixtures/{actback-task,dual-intent}/` **land in D-015**;
`tests/canonical/test-domain-doc-matrix.sh` (extend if the spine-dimension substrate changes).

### 6. Delivery boundary (what lands where)

- **D-013 (spine-keyed depth contracts)** — Change 1 (FR-52): the per-spine-dimension depth
  standard + re-point the GENERATE custom-doc prompt at it (kill the dangling anchor). Tests: every
  matrix doc (all domains) resolves to a non-empty depth contract via its spine dimension.
- **D-014 (generalize the safeguard)** — Change 2 (FR-53): re-key `_doc_expects_class` + the
  task-shape selector to spine dimensions; carry the dimension into the doc-set substrate;
  C9-derived task generation. **Owns its own minimal doc-set TSV fixtures** (`data-ml.tsv` /
  `design.tsv` — the substrate its presence-check + selector gates assert against); the **full
  per-domain GOOD/SHALLOW/WRONG mini-KBs + their tiny source trees are D-015's**. Tests: run on its
  doc-set TSVs → domain-appropriate task + non-empty presence check (owning-table + selector only;
  full-KB PASS/FAIL defers to D-015). **Depends on D-013.**
- **D-015 (the dual-intent self-evaluation — the core, §4)** — Changes FR-54 + FR-55: the Blind
  Work-Simulation + Blind Reconstruction & Source-Confrontation limbs, the dual-intent ledger, the
  convergence thresholds, the probe-derivation helper, wired into REVIEW. Tests: fixtures (GOOD
  PASS / SHALLOW+WRONG FAIL) across domains. **Depends on D-013 + D-014** (consumes the spine-keyed
  depth standard + the spine-keyed safeguard / C9-derived probes).
- **D-016 (altitude signature exception + dogfood)** — Change 3 (FR-56) + docs + the AID dogfood
  regression + re-injecting the AID instance's altitude-rule-evicted depth (host-tool matrix,
  exit-codes) as the first beneficiary. **Depends on D-015.**

### 7. Scope boundaries

**In scope (this feature):** FR-52–FR-56 across D-013..016 — the spine-keyed depth contracts, the
spine-keyed safeguard wiring + C9-derived task generation, the Dual-Intent KB Self-Evaluation
(both limbs + ledger + convergence gates), the altitude signature exception, the fixture
validation, and the AID dogfood + depth re-injection.

**Won't (this work):** any change to feature-014's domain classifier, the matrix's domain set, or
the spine's cardinality (the 11-dimension T2 contract is untouched — this feature *consumes* the
spine, it does not grow it); any change to `synth_default_seed`'s byte-stable software seed; any
new agent enum value (the dual-intent limbs reuse the existing `aid-reviewer` parallel-panel +
`grade.sh` + the 7-column ledger schema — no new grading infra, no separate verdict sentinel,
consistent with f013).

### 8. Risks (carried to PLAN Cross-Cutting Risks)

- **Probe-derivation quality** — the gates are only as good as the derived probes. Mitigation:
  derive a spread across spine dimensions + a minimum count; human confirm/extend at the gate (the
  no-assumptions pattern).
- **Cost** — two clean-context limbs × K probes per REVIEW cycle is more agent work. Mitigation:
  scale K by triage size; cache probes across cycles.
- **Threshold calibration** — what assertiveness/essence % = pass? Start strict (zero HIGH; ≥90%
  STATED) and calibrate on the AID dogfood + fixtures.
- **Software-row byte-stability** — re-keying the safeguard substrate must not perturb the
  byte-stable software seed or its existing TSV-consumers; the matrix's seed-consistency check +
  the existing actback-task suite are the regression guards.

### 9. Engineering constraints (reused)

- Any shipped/changed script ASCII-only + WinPS-5.1-safe; deterministic where mechanical (probe
  derivation, presence check, fixture assertions) and judgment only where irreducible (the plan
  quality, the essence reconstruction, the source confrontation).
- Canonical edits → full `run_generator.py` regen → `.claude` dogfood sync → DBI green (per the
  standing build cornerstones).
- **Grade gate:** **A+** for every delivery (this work's quality bar, above the default A minimum).
