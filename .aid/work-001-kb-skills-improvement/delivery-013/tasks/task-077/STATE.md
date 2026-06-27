# Task State -- task-077

> **Task:** task-077
> **Delivery:** delivery-013
> **Work:** work-001-kb-skills-improvement

---

## Task State

- **State:** Done
- **Review:** Pending
- **Elapsed:** --
- **Notes:** Design of record for feature-016 Change 1 (FR-52) authored below (this STATE
  `## Notes` IS the discoverable design artifact the SPEC Scope names; no separate report
  file, no canonical edit — task-078 implements it). Produced: (1) the per-spine-dimension
  depth-standard contract for every dimension C0-C9 + D; (2) the authority-file decision
  (extend `document-expectations.md` with one spine-dimension-keyed section — the lower-churn
  single-source form); (3) the doc->dimension->standard resolution contract for
  `state-generate.md` §2.6 + `agent-prompts.md`, with the per-filename entry as optional
  additive refinement. Counts re-verified against the real files: 58 matrix-emittable
  filenames, 22 covered, **36 dangle** (the dangling set spans all 11 dimensions). See the
  full proposal under `## Design of Record` below.

---

## Quick Check Findings

- **Reviewer Tier:** Small (quick check always uses Small tier)
- **Findings:** _none yet_

---

## Dispatch Log

| Date | Agent | ETA Band | Actual | Outcome |
|------|-------|----------|--------|---------|

---

## Design of Record

> **Design of record for feature-016 Change 1 (FR-52) — the per-spine-dimension depth
> standard, the authority-file decision, and the doc->dimension->standard resolution
> contract.** DESIGN only; task-078 authors the canonical edits this specifies. Every claim
> grounded in the real files re-read for this task: `document-expectations.md` (26 `###`
> headings = 22 matrix filenames + `INDEX.md` + `README.md` + 2 `{placeholder}` entries),
> `concern-model.md` (the 11-dim spine + the "Operational guidance is first-class structure"
> owning-table), `domain-doc-matrix.md` (per-doc `spine-dimension` column),
> `state-generate.md` §2.6 (lines 657-671), `agent-prompts.md` §"Custom-Doc Runtime
> Extension" (lines 102-126).

### 0. The verified gap this closes

`document-expectations.md` is keyed by `### <filename>`. Of the **58 unique filenames** the
matrix can emit, only **22** have a `### <filename>` entry; **36 dangle** (re-verified by
diffing the matrix doc-records against the expectations headings; the two "extra" expectations
headings `INDEX.md`/`README.md` are meta/skill-self, not matrix doc-records, so they are not
counted in the 58). The §2.6 custom-doc prompt (state-generate.md:664-665) appends, per custom
doc, *"Also produce .aid/knowledge/<filename> per its expectations entry in
references/document-expectations.md (keyed by ### <filename>)"* — so each of the 36 dangling
docs is pointed at a **dangling anchor** and receives only the generic spine question.

**The 36 dangling docs span ALL 11 dimensions** (verified by mapping each to its matrix
`spine-dimension`): C0 (`tooling-stack.md`), C1 (`design-system.md`, `information-architecture.md`,
`methodology.md`, `platform-topology.md`), C2 (`component-inventory.md`, `content-map.md`,
`data-pipeline.md`, `deployment-map.md`, `evidence-map.md`), C3 (`analysis-conventions.md`,
`design-principles.md`, `ops-conventions.md`, `style-guide.md`), C4 (`glossary.md`), C5
(`config-schemas.md`, `content-model.md`, `data-schemas.md`, `design-tokens.md`,
`evidence-sources.md`), C6 (`accessibility-landscape.md`, `editorial-process.md`,
`evaluation-landscape.md`, `runbook-landscape.md`, `validation-landscape.md`), C7
(`limitations.md`), C8 (`delivery-pipeline.md`, `dissemination.md`, `publishing-pipeline.md`),
C9 (`content-inventory.md`, `design-overview.md`, `model-cards.md`, `research-questions.md`,
`service-inventory.md`), D (`experiment-log.md`, `findings-log.md`). **Therefore a depth
standard authored once per dimension C0-C9 + D gives every one of the 36 a non-empty,
work-actionable contract** — no per-filename authoring.

### 1. Authority-file decision (SPEC Scope bullet 2 / seed §8 open question)

**DECISION: extend `document-expectations.md` with ONE new spine-dimension-keyed section
(`## Spine-Dimension Depth Standards`, containing a `### C<N> — <dimension>` block per
dimension). Do NOT create a sibling `spine-depth-expectations.md`.**

Rationale (lower-churn, single-source):

1. **Single authority file = single resolution target.** §2.6 (state-generate.md:664) and
   `agent-prompts.md` (line 110-111) both already name exactly one file
   (`references/document-expectations.md`). Keeping the dimension layer *inside* that file means
   the §2.6 re-point changes only the *anchor form* (`### <filename>` -> doc's dimension's
   `### C<N>`), never the *file path* — the smallest possible diff to the two prompt sites and
   the REVIEW-grading reference (agent-prompts.md:125). A sibling file would add a second path
   that 3 sites must learn, plus a cross-file "see also" both directions.
2. **No new install/render surface.** `document-expectations.md` already ships and renders
   (canonical -> `.claude`). Adding a section keeps the manifest/DBI surface identical; a new
   file is a new rendered artifact to wire, risking render-drift/DBI churn for zero benefit.
3. **The 22 per-filename entries and the 11 dimension blocks are the same kind of thing**
   (research expectations) and belong adjacent so an author sees both the dimension floor and
   the optional filename refinement in one read. `concern-model.md` and `domain-doc-matrix.md`
   already point at `document-expectations.md` as *the* per-doc-expectations file (concern-model
   line 324; matrix line 446) — one file keeps those cross-refs valid unchanged.
4. **Byte-stable software seed is untouched.** The 22 existing `### <filename>` entries are NOT
   edited or removed (they become optional refinements — see §3); the new section is purely
   additive. No `synth_default_seed` change, no matrix-row change, no spine-cardinality change.

**Placement:** the new `## Spine-Dimension Depth Standards` section is inserted **before** the
first `### <filename>` entry (after the file's intro paragraph at lines 1-6), so the dimension
floor reads as the primary contract and the filename entries read as refinements beneath it.
The intro paragraph gains one sentence: *"Each doc's MUST-floor is its spine dimension's depth
standard below; a `### <filename>` entry, when present, is an optional additive refinement that
layers on top and never replaces the dimension floor."*

### 2. The per-spine-dimension depth-standard contract (SPEC Scope bullet 1 / AC-1)

Authored once per dimension. Each `### C<N> — <dimension>` block has a fixed shape so task-078
can render it mechanically and the reviewer/FIX loop can grep it:

- **MUST carry (the work-actionable floor):** the bulleted facts a doc realizing this dimension
  must contain for an agent to ACT from the KB alone — generalized from today's best software
  `### <filename>` entries, stated domain-generally.
- **Named operational sections it owns:** the `## Conventions`/`## Invariants`/`## Gotchas`/
  `## Contracts` heading(s) this dimension owns, **single-sourced from `concern-model.md`'s
  "Operational guidance is first-class structure" owning-table** (so D-014's re-keyed
  `kb-actback-task.sh` owning-table and this standard cite one source).
- **Red flags:** the calibration aids (e.g. "convention named but no example").

The eleven standards (C5/C3/C2/C6 explicit per the seed; the rest specified, not TBD):

| Dim | Dimension | MUST carry (work-actionable floor) | Owns named section(s) | Red flag |
|----|-----------|-------------------------------------|-----------------------|----------|
| **C0** | Technology / medium | Every language/framework/tool/runtime/medium **with its actual version from the config**, AND the exact runnable **build command** + **lint/validate command** (a tool name without the command is not actionable). | — | "Maven"/"npm" without the full command; "version TBD" on an extractable version. |
| **C1** | Build & shape | The actual structure/anatomy (the real layout, not a generic skeleton), why each major part exists, AND **the invariants a change must never break** (an ordering, a single-source-of-truth rule, a non-null guarantee). | `## Invariants` | A tree/skeleton dump with no purpose annotations; missing the structural invariants. |
| **C2** | Parts & connections | The parts (modules/stages/components/sources), **how they connect** (dependencies, hand-offs, data path), AND **how to add a part** (the naming + registration + wiring sequence) + the cross-boundary invariants/gotchas. | `## Conventions`, `## Invariants`, `## Gotchas` | A part listed with no purpose or no connections; "how to add one" absent. |
| **C3** | Conventions | The project's **own actual rules** (naming, layout, registration, handling patterns) **with a concrete example for each**, plus the red-flags a contributor must avoid — not general best practice. | `## Conventions` | Generic advice instead of project-specific rules; a convention named but **no example**. |
| **C4** | Vocabulary | Every native/coined/overloaded term defined **as it means here** (not in general), where it lives, why the project needs it, AND **which term boundaries carry conceptual invariants** (the distinctions a newcomer must never conflate). | `## Invariants` | Generic programming terms; a load-bearing coined term treated as noise (the "Relative bus" failure). |
| **C5** | Data & contracts | The data shapes / fields / **types / constraints**, how the shapes relate/connect, AND **the extension procedure — how to add or change a shape/field** (the contract a change must satisfy). | `## Contracts`, `## Conventions` | A shape/entity list with no types/constraints; no "how to add/change one"; field types pushed behind a bare `sources:` pointer (the altitude tax — D-016 exception). |
| **C6** | Quality & checking | How the work is **checked/graded/validated**, the **bars it must meet**, what kinds of checks exist and their real coverage/health, AND the **exact runnable command(s)** to run the checks. | — | The check framework named without the runnable command; no pass/quality bar; no coverage/health assessment. |
| **C7** | Risk & debt | What is risky/owed/worked-around, **classified by severity**, each with **location + risk-if-unaddressed + resolution note**, AND the **non-obvious gotchas** a change will trip (lockstep config, required build step, ordering hazard). | `## Gotchas` | Debt with no severity or no location; gotchas absent. |
| **C8** | Shipping & operation | How it goes from artifact to running/published (source control, CI/CD, packaging, **release/publish process**, versioning, runtime/operation), with the **runnable commands** where an agent acts; explicit "none" where a stage does not exist. | — | Tools listed with no how-configured/how-run; a stage assumed (e.g. Git) without verifying; missing "none" where absent. |
| **C9** | What it does for users | The user-facing capabilities/features/workflows, **what each accomplishes + its use-case/trigger**, **how each is invoked**, mapped to the parts/data they touch — the "what can it do" catalogue grounded in real capability definitions. | — | A bare capability list with no value/use-case; missing invocation detail; placeholder descriptions. |
| **D** | Decisions & rationale | The significant decisions, **what was decided + why + the alternatives considered and rejected**, the constraints/trade-offs that drove each, status + evidence — the rationale a newcomer cannot reconstruct from the artifacts alone. | — | Restates current state without the "why" or the rejected alternatives; invents rationale not grounded in evidence. |

Notes binding this table to the real files:
- C0/C6/C8 "runnable command" floor is lifted verbatim-in-spirit from today's
  `technology-stack.md` / `test-landscape.md` / `infrastructure.md` entries (lines 45-58,
  166-178, 197-212) — generalizing them to whatever doc realizes the dimension (`tooling-stack.md`
  for C0; `evaluation-landscape.md`/`editorial-process.md`/`runbook-landscape.md`/
  `validation-landscape.md`/`accessibility-landscape.md` for C6; `publishing-pipeline.md`/
  `delivery-pipeline.md`/`dissemination.md` for C8).
- The "Owns named section(s)" column is **copied from `concern-model.md`'s owning-table**
  (lines 293-298): Conventions->C3 + C2/C5; Invariants->C1 + C2 + C4; Gotchas->C7 + the
  concern it lives in; Contracts->C5 + C2. This is the single source D-014 also re-keys, so
  the depth standard and the safeguard owning-table cannot drift.
- The standards are **domain-general**: each is specialized to the doc's actual content at
  authoring time (C5's "shapes" = entities for `schemas.md`, datasets/columns for
  `data-schemas.md`, tokens for `design-tokens.md`, config keys for `config-schemas.md`).

### 3. The doc -> dimension -> standard resolution contract (SPEC Scope bullet 3 / AC-3)

**The resolution chain (what task-078 wires):**

1. **Doc -> dimension.** Each doc's spine dimension is already recorded: in
   `domain-doc-matrix.md` (the `spine-dimension` column of each row) for matrix docs, and in
   `state-generate.md` §2.6 Branch B for auto-researched docs (state-generate.md:317 already
   maps each custom doc to "exactly one spine dimension (C0-C9, D, or meta)"). The keying
   substrate **already exists** — this contract consumes it, adds nothing to the spine.
2. **Dimension -> standard.** The dimension keys into the new `### C<N> — <dimension>` block in
   `document-expectations.md`.
3. **Optional filename refinement.** If a `### <filename>` entry exists for the doc, it **layers
   additively on top** of the dimension standard — it never replaces it. (The 22 existing
   entries thus become refinements; the 36 dangling docs simply have no refinement and resolve
   to the dimension floor alone — which is now non-empty.)

**The §2.6 re-point (state-generate.md, lines 657-671).** Replace the custom-doc prompt line
(currently lines 664-665):

> *Old:* `Also produce .aid/knowledge/<filename> per its expectations entry in
> references/document-expectations.md (keyed by ### <filename>).`

> *New (task-078 authors the exact prose):* an instruction that resolves the doc's **spine
> dimension** (from the declared doc-set / matrix `spine-dimension` / the §2.6 Branch-B
> mapping), points the agent at the matching `### C<N> — <dimension>` **Spine-Dimension Depth
> Standard** in `references/document-expectations.md` as the **MUST-floor**, and adds: "if a
> `### <filename>` entry exists for this doc, also satisfy it as an additive refinement on top
> of the dimension standard." This guarantees **no doc resolves to a dangling anchor** — a
> custom doc with no filename entry still inherits its dimension's non-empty contract.

**The `agent-prompts.md` re-point (§"Custom-Doc Runtime Extension", lines 102-126).** The same
substitution in the canonical protocol prose (the runtime-append line at 110-111) and the
REVIEW-path sentence (line 125): the reviewer grades a custom doc against **its spine
dimension's depth standard** (plus any filename refinement), not against a (possibly missing)
`### <filename>` entry. The "appended once per custom doc / base prompt never modified /
owner-resolution" mechanics (lines 113-121) are unchanged — only the anchor target changes.

**Why this is correct + minimal:** the chain reuses the matrix `spine-dimension` column and the
§2.6 dimension mapping that feature-014 already shipped; the only edits are the two prompt
anchor lines + the additive depth-standards section. The byte-stable seed, the matrix domain
set, the classifier, and `synth_default_seed` are all untouched (AC-4).

### 4. Per-AC confirmation

- **AC-1 (per-dimension depth standard for every dimension):** SATISFIED — §2 specifies all
  11 (C0-C9 + D); C5/C3/C2/C6 are explicit per the seed and none is "TBD". The 36 dangling
  docs map across all 11 dimensions, so every one resolves to a non-empty floor (§0).
- **AC-2 (authority-file decision, justified, lower-churn):** SATISFIED — §1 decides "extend
  `document-expectations.md` with one spine-dimension-keyed section" over a sibling file, with
  the four-point lower-churn/single-source justification; task-078 inherits an unambiguous
  target (the new `## Spine-Dimension Depth Standards` section + placement).
- **AC-3 (doc->dimension->standard resolution contract + filename-as-optional-refinement):**
  SATISFIED — §3 specifies the chain and the exact re-point of state-generate.md §2.6 (lines
  664-665) and agent-prompts.md (lines 110-111, 125), with the layers-on-never-replaces rule
  stated; no doc left at a dangling `### <filename>` anchor.
- **AC-4 (consumes the spine, does not grow it):** SATISFIED — no change to the 11-dimension
  cardinality, the matrix domain set, the classifier, or `synth_default_seed` is proposed; the
  contract consumes the existing `spine-dimension` substrate and the existing §2.6 mapping.
- **AC-5 (section-6 gates / DESIGN task):** SATISFIED — proposal recorded in this STATE; no
  canonical edit in task-077, so no regen/DBI runs here (they run in task-078/079).
