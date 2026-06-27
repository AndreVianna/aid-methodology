# Design plan — aid-discover dual-intent self-evaluation + domain-general depth (feature-016 seed)

> **Status:** design plan (input for interview→specify→plan→detail). NOT executed.
> **Source:** the two comparison rounds (kb-comparison-verdict.md + kb-generator-verdict.md) +
> user intent (2026-06-25): make the KB (1) let agents work with *assertiveness + quality*, and
> (2) faithfully represent the *true essence + content* of the project for humans — and build a
> SELF-evaluation mechanism that verifies both without needing real non-software test projects.
> **Continuation of:** work-001 (follows feature-014 domain-driven discovery + feature-015 summarize).

## 1. The problem (verified, from the two critique rounds)

The new `/aid-discover` is domain-general in *architecture* but software-complete only in *content*:

- **Depth contract is filename-keyed + software-only.** `document-expectations.md` has entries for
  ~24 docs (17 software + 7 methodology-tooling). The ~30 non-software filenames the matrix can emit
  (`data-schemas.md`, `design-tokens.md`, `content-model.md`, `methodology.md`, …) have **0** entries
  → the generator points the researcher at a dangling anchor → those docs get only the generic spine
  question, no work-actionable depth contract. (VERIFIED.)
- **The sufficiency safeguard is filename-keyed + provably inert off-software.** `kb-actback-task.sh`'s
  representative-task selector and its operational-class owning-table (`_doc_expects_class`) recognize
  only software filenames. Run on a data/design doc-set: the task degrades to "add an endpoint" and the
  presence-check table is **empty**. (VERIFIED by running it.)
- **Altitude-rule tax (software, modest).** "Volatile detail → `sources:`" pushed some load-bearing
  signature detail out of the docs (schemas field-types 16→1; exit-codes 38→17; host-tool matrix
  deleted), so an agent sometimes must re-derive from source what the KB used to state.

Root cause (one sentence): **the depth layer and the sufficiency gate were authored for the two
domains AID dogfooded; the breadth layer was designed general.** Breadth ran ahead of depth.

## 2. The two intents → two measurable, self-run gates

| Intent (user's words) | What it means operationally | The gate that verifies it |
|---|---|---|
| **(1) Support agents to do the work with assertiveness + quality** | A clean-context agent can plan AND complete a representative task **from the KB alone**, in the project's **own conventions**, without guessing or reaching for source; the KB conveys the conventions/invariants/quality-bars that make the work *good*, not merely functional. | **Blind Work-Simulation** (generalized act-back) — the *assertiveness* gate. |
| **(2) Represent + serve as a reference of the true essence + content of the project, for humans** | A clean-context reader can reconstruct the project's essence (what it is, what it does, how it's shaped, why) from the KB alone, and that reconstruction **matches the source** (no omission of load-bearing facts, no divergence from reality). | **Blind Essence-Reconstruction + Source Confrontation** (generalized teach-back + fidelity) — the *essence* gate. |

These already exist as the M4 (act-back) and M3 (teach-back) keystones — the plan **generalizes them
to be spine-keyed + self-sourced + dual-intent-explicit**, and makes them the convergence target of
the REVIEW⇄FIX loop for ANY domain.

## 3. The unifying principle

**Lift everything domain-specific from FILENAME-keyed to SPINE-DIMENSION-keyed, and derive the
self-evaluation probes from the project's own source + capabilities.**

- The spine (C0–C9 + D) is already the domain-general abstraction; the matrix already maps every doc
  → its spine dimension. So "the C5 doc (whatever it's named) must carry data-shapes + types +
  constraints + how-to-extend; the C3 doc must carry the actual conventions" is a **domain-general**
  depth contract that needs authoring **once per spine dimension**, not once per filename.
- The self-evaluation derives its probes from the project itself (its source = ground truth; its C9
  capability doc = task seeds), so it adapts to any domain with **no anticipated per-domain content**.

This is why it scales to "any project type" and why it needs **no external test corpus**: the
mechanism is calibrated by the project under discovery, every run.

## 4. THE MECHANISM — Dual-Intent KB Self-Evaluation (the core deliverable)

Runs in the existing REVIEW state (alongside/replacing the current M3/M4 keystones), domain-general.

### 4.0 Probe derivation (domain-general, project-self-sourced)
From the resolved doc-set + spine + the project source, derive:
- **Work probes (Intent 1):** K representative tasks generated from the **C9 capability/what-it-does
  doc** + the domain — "add / modify / extend «a capability the project actually has»" — selected so
  the set collectively exercises the load-bearing spine dimensions (C5 data/contracts, C3 conventions,
  C2 parts, C6 quality). For software → "add a field to «contract X»"; for data-ml → "add a feature to
  «pipeline Y» / a column to «dataset Z»"; for design → "add a token / a component variant"; for
  content → "add a content type / a section"; for ops → "add a service / a runbook step". **Derived,
  not hardcoded.**
- **Essence probes (Intent 2):** "what is X / how does Y work / why Z" over the project's load-bearing
  concepts, sampled from the **C4 vocabulary** + **C9 capabilities** + **D decisions** docs AND from
  high-salience source facts (the things a newcomer must grasp).

### 4.1 Assertiveness limb (Intent 1) — Blind Work-Simulation
A clean-context agent (KB-only, **no source access**) plans each work probe step-by-step, in the
project's own conventions. For every step it tags: **STATED** (the KB gave the contract/convention I
needed) vs **ASSUMED** (I had to guess) vs **REACH** (I would have to read source). Scoring:
- Any **load-bearing ASSUMED/REACH** = a `[HIGH] [ACTBACK]` insufficiency → FAIL item → FIX target.
- **Quality check (not just functional):** does the plan honor the project's conventions (C3),
  invariants/gotchas, and quality bars (C6)? A plan that would "work" but violate the project's
  standards is a quality FAIL — the KB failed to convey the quality contract.
- Pass = a complete, correct, convention-honoring plan with zero load-bearing insufficiencies.

### 4.2 Essence limb (Intent 2) — Blind Reconstruction + Source Confrontation
Two stages:
1. **Reconstruct (KB-only):** a clean-context agent answers the essence probes + writes a short
   "what/why/how" project narrative, using ONLY the KB.
2. **Confront (source-grounded):** a second agent **with source access** checks the reconstruction
   against the actual project. Two failure classes:
   - **Divergence** (KB-only answer is WRONG vs source) = `[HIGH] [FIDELITY]` → FIX (the KB
     misrepresents reality).
   - **Omission** (a load-bearing source fact the reconstruction couldn't supply) = `[MED]
     [ESSENCE-GAP]` → FIX (the KB omits essence).
- Pass = the KB-only reconstruction is correct (no divergence) and complete on load-bearing essence.

### 4.3 Spine-coverage + operational-class presence (domain-general)
Re-key the operational-class owning-table from filenames → spine dimensions: the **C5 doc owns
Contracts/schemas**, the **C3 doc owns Conventions**, the **C2 doc owns the parts + how-to-extend**,
the **C6 doc owns Quality/checking**, **C7 owns Gotchas/debt**. Presence check fires for whatever doc
realizes that dimension in this project's doc-set — so it works for `data-schemas.md` or
`design-tokens.md` exactly as for `schemas.md`.

### 4.4 The convergence loop + thresholds
REVIEW runs 4.1–4.3 → emits a dual-intent ledger → FIX deepens the flagged docs → re-REVIEW, until:
- **Assertiveness:** zero `[HIGH] [ACTBACK]`, ≥ threshold of steps STATED, all quality-contracts present.
- **Essence:** zero `[HIGH] [FIDELITY]`, load-bearing essence-coverage ≥ threshold.
Both are hard keystone gates (a FAIL caps the grade), as M3/M4 are today — but now domain-general.

### 4.5 Why this needs no external test projects
Both limbs run **on the project being discovered**, using **its own source as ground truth** and
**its own capabilities as task seeds**. There is no anticipated domain knowledge and no separate test
corpus — the project *is* the test. A data/design/content project self-calibrates its own probes and
self-grades against its own source, the same way AID's software KB does today.

## 5. Supporting fixes (make the gates have something to drive toward)

1. **Spine-keyed depth contracts.** Add, to `document-expectations.md` (or a new
   `spine-depth-expectations.md`), a **per-spine-dimension** work-actionable depth standard:
   - C5 Data & contracts: the shapes/fields/types/constraints + **how to add/change one** (the
     extension procedure) — generalizes "schemas must show relationships + how entities connect".
   - C3 Conventions: the actual rules + concrete examples + red-flags ("convention named but no
     example" = red flag).
   - C2 Parts & connections: the parts, how they connect, **how to add a part**.
   - C6 Quality & checking: how work is graded/validated + the bars to meet.
   - C0/C1/C4/C7/C8/C9/D similarly. Each doc inherits its dimension's standard, specialized to its
     actual content. **Closes the dangling-anchor gap once, domain-generally** — no per-filename
     authoring. (Per-domain *refinements* for curated matrix domains stay optional, additive.)
2. **Spine-keyed safeguard wiring.** Re-key `kb-actback-task.sh`'s owning-table + task-shape selector
   from filenames → spine dimensions (single-sourced from `concern-model.md`, which already names the
   owning docs per dimension). C9-derived task generation (4.0).
3. **Altitude-rule signature exception.** Amend the "volatile → `sources:`" rule: **load-bearing
   operational contracts an agent must honor to ACT** (field types, exit codes, the
   args/modes/invariants) are stated INLINE or with a **precise grep-recoverable anchor** — never a
   bare file pointer. The altitude rule keeps de-bloating *narrative* volatility, not *work-critical*
   contracts. (The assertiveness gate enforces this automatically: if the agent must REACH for it,
   it FAILs.)

## 6. Validating that the MECHANISM generalizes (since no IRL non-software projects)

We cannot run a real data/design project, so validate the *machinery*, not a real KB, with fixtures:
- **Fixture KBs** per non-software domain (data-ml, design, content) in two variants each:
  a **GOOD** mini-KB (work-actionable depth + faithful essence → must PASS both gates) and a
  **SHALLOW/WRONG** mini-KB (omits field types / diverges from a fixture "source" → must FAIL the
  right limb). (The adversary already built `data-ml.tsv`/`design.tsv` doc-set fixtures — extend to
  full mini-KBs + a tiny fixture "source".)
- **Tests assert:** the probe derivation produces domain-appropriate tasks (not "add an endpoint");
  the owning-table presence check fires on the domain's C5/C3/etc. docs; the assertiveness limb FAILs
  the shallow KB on the missing contract; the essence limb FAILs the wrong KB on divergence. This
  proves the gates *fire correctly off-software* — the exact thing that's broken today.
- **Dogfood (real):** continue to run on AID itself (software+methodology) as the live regression.

## 7. Phased work breakdown (feature-016 — proposed; A+ gate between phases)

- **D-A — Spine-keyed depth contracts** (Change 1): author the per-spine-dimension depth standard +
  re-point the custom-doc prompt at it (kill the dangling anchor). Tests: every matrix doc resolves
  to a non-empty depth contract via its spine dimension.
- **D-B — Generalize the safeguard** (Changes 2): re-key the owning-table + task-shapes to spine
  dimensions; C9-derived task generation. Tests: run on data/design fixtures → meaningful task +
  non-empty presence check.
- **D-C — The dual-intent self-evaluation** (the core, §4): the Blind Work-Simulation + Essence-
  Reconstruction-&-Confrontation limbs, the dual-intent ledger, the convergence thresholds, wired
  into REVIEW. Tests: fixtures (good PASS / shallow+wrong FAIL) across domains.
- **D-D — Altitude-rule signature exception** (Change 3) + docs + the regression dogfood on AID +
  re-inject the AID instance's lost depth (host-tool matrix, exit-codes) as the first beneficiary.
- Sequencing: D-A → D-B → D-C (D-C consumes A+B); D-D last. Each A+-gated.

## 8. Risks + open questions (for the user)
- **Probe-derivation quality.** The gates are only as good as the derived probes. Mitigation: derive
  a *spread* across spine dimensions + a minimum count; let the human confirm/extend the probe set at
  a gate (the no-assumptions pattern).
- **Cost.** Two clean-context limbs × K probes per REVIEW cycle is more agent work. Mitigation:
  scale K by triage size; cache probes across cycles.
- **Threshold calibration.** What assertiveness/essence % = pass? Start strict (zero HIGH; ≥90%
  STATED) and calibrate on the AID dogfood + fixtures.
- **Decision:** is this feature-016 in work-001, or a new work? (Recommend: feature-016, continuation.)
- **Decision:** spine-depth standard as a new doc vs extending `document-expectations.md`?

## 9. How this delivers the two intents (explicit tie-back)
- **Intent 1 (assertive + quality work):** the Blind Work-Simulation makes "an agent can actually do
  quality work from this KB alone" a **measured, enforced, domain-general gate** — exactly the
  property that's software-only today.
- **Intent 2 (true essence for humans):** the Blind Reconstruction + Source Confrontation makes
  "the KB faithfully conveys the project's real essence" a **measured, enforced gate** — catching both
  omission and divergence against the source ground truth, for any domain.
- Both are **self-evaluated** (no external test data) because they probe the project with the
  project's own source + capabilities. The supporting fixes (spine-keyed depth + safeguard +
  signature exception) give the gates a concrete depth standard to drive the FIX loop toward.
