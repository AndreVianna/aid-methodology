# Plan -- Knowledge Base Skills Overhaul

> **Work:** work-001-kb-skills-improvement
> **Created:** 2026-06-23
> **Source:** SPEC features feature-001..feature-012 (`features/`), REQUIREMENTS.md, whole-work-review.md

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-23 | Initial plan — 9 deliveries (essence-core-first → greenfield Could) | /aid-plan |
| 2026-06-23 | greenfield de-scope — the former greenfield-path delivery (then numbered delivery-009, a now-defunct identifier distinct from the current live delivery-009 Governance created in the later act-back insert) removed; work was 8 deliveries (delivery-001..008) at that point. Greenfield reduced to detect+signpost in delivery-004's recon (no generation engine / elicit path / closure / panel); f006/f012 brownfield-only scope notes updated; R1 (greenfield scope-split) retired. Forward-authored KB-seed deferred to a future interview-side work. | user decision |
| 2026-06-23 | act-back insert — feature-013 (Operational-Sufficiency / act-back gate) inserted as the NEW delivery-005 (4 tasks, 027-030); the downstream paper deliveries shift down one (Validation 005->006, Freshness 006->007, Topology+Ship 007->008, Governance 008->009) and renumber contiguously. delivery-006 (Validation) gains ONE new task (task-039, the act-back V-E fixture family) and now depends on delivery-005. Work is now **9 deliveries / 55 tasks** (delivery-001..004 + tasks 001-026 are FROZEN/byte-untouched — delivery-001 is built). | user decision (feature-013) |
| 2026-06-24 | domain-driven discovery insert — feature-014 added as **delivery-010** (8 tasks, 056-063) via the lite path; generalizes `/aid-discover` beyond software (FR-37–FR-44). EXECUTED + A+ delivery gate. Work is now **10 deliveries / 63 tasks**. | user decision (feature-014) |
| 2026-06-25 | summary-redesign insert — feature-015 (`kb.html` domain-driven redesign) added as **two deliveries**: **delivery-011** (correctness core — Changes 1-5) and **delivery-012** (visual & engineering — Changes 6-7 + the §7 visual-fidelity gate), D-012 depending on D-011. Task breakdown is authored by `/aid-detail` (these stanzas + delivery SPEC/STATE are scoping-only placeholders). Work is now **12 deliveries**. | user decision (feature-015) |
| 2026-06-25 | dual-intent self-eval insert — feature-016 (dual-intent KB self-evaluation + spine-keyed domain-general depth, FR-52–FR-56) added as **four deliveries**: **delivery-013** (spine-keyed depth contracts), **delivery-014** (generalize the safeguard + C9-derived task generation), **delivery-015** (the Dual-Intent KB Self-Evaluation — both limbs + ledger + convergence gates), **delivery-016** (altitude signature exception + AID dogfood + re-inject lost depth). Dependencies: D-014→D-013, D-015→(D-013,D-014), D-016→D-015; the feature depends on **feature-014** (already built/EXECUTED as delivery-010). Kept as four deliveries (not consolidated) — see the delivery-013 stanza for the grouping justification. Task breakdown is authored by `/aid-detail` (these stanzas + delivery SPEC/STATE are scoping-only placeholders). Work is now **16 deliveries**. | user decision (feature-016) |

This plan decomposes work-001 into **16 deliveries**. The sequence is user-approved.
Each delivery is one branch/PR (`aid/work-001-delivery-NNN`). The strategy: build the
**essence engine end-to-end first** (delivery-001 = the 'Relative bus' capability), then
flip AID's own surfaces onto the new schema (INDEX, migration), scale it to project shape
(adaptive paths), lock it in with a CI-anchored regression fixture, then layer the
Should-priority lifecycle skills (freshness, topology+ship, governance).

**Greenfield is detect-and-signpost, not a generation path.** A from-scratch project
(recon detects ~0 source) is not discovered by a bespoke greenfield engine; `aid-discover`
emits a signpost and halts ("Nothing to discover yet — run /aid-interview to define the
project; the KB fills in via re-triage once code lands"). The two generation paths this
work builds are brownfield-small and brownfield-large. Forward-authored greenfield KB-seed
(eliciting intended architecture/conventions/ubiquitous-language for a from-scratch
project) is a **future interview-side capability, out of scope here.**

The strategy is **provide-before-consume**: every feature's frontmatter/schema/oracle
producer lands in or before the delivery that consumes it. delivery-001 establishes the
whole essence substrate (frontmatter primitive f001, concern model f003, the
harvest/spine/closure engine f004, the review panel f005) so the downstream deliveries
consume settled contracts.

## Deliverables

### delivery-001: Essence Core

- **What it delivers:** the 'Relative bus' capability end-to-end -- essence capture (mechanical
  coined-term harvest + the non-lexical conceptual-synthesis channel) feeding a grounded concept
  spine, a bounded comprehension/closure loop, and a multi-mandate review panel with teach-back as
  the keystone hard gate. After delivery-001, `/aid-discover` captures a project's essence and
  certifies it (teach-back closure replaces "severity >= A+" as the exit).
- **Features:** feature-001 (frontmatter & `sources:` primitive), feature-003 (KB document model /
  concern model), feature-004 (essence-capture research engine), feature-005 (review panel & rubric)
- **Depends on:** -- (none)
- **Priority:** Must

### delivery-002: INDEX Routing

- **What it delivers:** `INDEX.md` flips from today's prose-`intent:` list to the generated,
  deterministic routing table (Document | Objective | Summary | Tags | See-instead | Audience),
  composed mechanically by `build-kb-index.sh` from the frontmatter fields delivery-001 established.
- **Features:** feature-002 (INDEX routing table)
- **Depends on:** delivery-001
- **Priority:** Must

### delivery-003: KB Migration

- **What it delivers:** AID's own KB (plus a fixture old-format KB) migrated onto the new
  frontmatter schema and INDEX format; the `lint-frontmatter.sh` flipped to a hard gate **for AID**
  (the shipped soft-skip retained for adopter degrade-grace); old-format coexistence remains
  degrade-graceful. Moved early so AID dogfoods the schema and so later freshness operates on
  stamped `approved_at_commit:` docs.
- **Features:** feature-011 (KB migration)
- **Depends on:** delivery-001, delivery-002
- **Priority:** Must

### delivery-004: Adaptive Paths (brownfield)

- **What it delivers:** a recon pre-pass that **measures** source-availability/complexity and
  **proposes** a path (human-confirmed, not declared from `project.type`), then scales the closure
  engine + review panel to project size for the brownfield-small and brownfield-large paths.
- **Features:** feature-006 -- recon classifier (which **detects** greenfield, ~0 source),
  brownfield-small path, brownfield-large path. **Greenfield = detect + signpost, not a path:**
  when the classifier detects ~0 source, `aid-discover` emits a signpost and halts ("Nothing to
  discover yet — run /aid-interview to define the project; the KB fills in via re-triage once code
  lands"). There is **no** greenfield generation engine / elicit-via-interview-specify path /
  greenfield closure / greenfield panel. The only two *generation* paths are brownfield-small and
  brownfield-large. (Forward-authored greenfield KB-seed is a future interview-side work, out of
  scope — see the work-level scope note.)
- **Depends on:** delivery-001
- **Priority:** Must

### delivery-005: Operational-Sufficiency (Act-Back Gate)

- **What it delivers:** the **act-back gate** (FR-36) -- the operational sibling of teach-back. A 6th
  mandate (M6) grafted onto delivery-001 f005's review panel in which a clean-context `aid-reviewer`,
  given ONLY the KB + a representative project task, must produce a correct plan AND flag every point
  of KB insufficiency (each a `[HIGH]` `[ACTBACK]` row the **existing** `grade.sh` already grades --
  no new grading infra, no separate verdict sentinel). It also **tightens f003's doc model** so
  operational guidance (conventions / invariants / gotchas / contracts) is first-class greppable
  structure, and ships ONE small ASCII helper (`kb-actback-task.sh`: representative-task selector +
  operational-structure presence check). After delivery-005, `/aid-discover`'s REVIEW reports the
  **triple** `Grade | Teach-back | Act-back`, with act-back as a sibling keystone.
- **Features:** feature-013 (operational sufficiency / act-back gate)
- **Depends on:** delivery-001 (extends f005's panel + f003's doc model + consumes f001's `sources:`)
- **Priority:** Must

> **Note (extend, don't re-spec; [SPIKE-A4]):** f013 reuses f005's parallel-dispatch + merged-ledger +
> `grade.sh` + `{{SCOPE}}` seam **verbatim** and *adds one mandate alongside them*; it *extends* f003's
> doc model with one structural rule and *consumes* f001's `sources:`. It lands **after** delivery-001
> (extend-after-base) and **before** delivery-006 (Validation), which builds + exercises the act-back
> fixture shape f013 defines ([SPIKE-A5], provide-before-exercise). Because M6 joins the per-mandate
> dispatch list, f006's brownfield-small panel collapse folds M6 in automatically ([SPIKE-A3]).

### delivery-006: Validation Fixture

- **What it delivers:** the CI-anchored regression proof that locks in the essence engine -- the
  planted 'Relative bus' fixture proving capture-and-define, the closure self-containment proof, the
  calibration-severity calibration, the teach-back closure proof (pass/fail KBs), the two brownfield
  path fixtures, and a greenfield **detection + signpost** test.
- **Features:** feature-012 -- AC1 teach-back closure fixture, AC2 'Relative bus' regression,
  AC3 closure self-containment, AC6 calibration tuning, AC7 the **two brownfield-small/large path
  fixtures + a greenfield detection/signpost test** (asserts the classifier detects ~0 source and
  that `aid-discover` emits the signpost and halts -- **not** a greenfield path-runs/reaches-closure
  fixture, since greenfield is not a generation path), AND **AC16 -- the act-back V-E fixture family**
  (the new task-039): the representative-task spec fixture + the `actback-pass-kb`/`actback-fail-kb`
  pair + the V-E mechanical assertion that delivery-005's `kb-actback-task.sh` emits the task
  byte-reproducibly and the presence check reports the operational sections present/absent; the M6
  plan-success/flag judgment is runtime-anchored (Judgment-Boundary row), mirroring the
  teach-back/calibration mechanical-vs-judgment split. f013 defines the fixture *shape*; f012 builds +
  exercises it ([SPIKE-A5]).
- **Depends on:** delivery-001, delivery-004, delivery-005
- **Priority:** Must

### delivery-007: Freshness Primitive

- **What it delivers:** a deterministic per-doc, source-keyed staleness check (each doc's `sources:`
  last-changed commit vs its approval commit -> suspect flag) and its surfacing in both dashboard
  readers (replacing the coarse whole-KB badge); auto-detect/flag, never auto-apply.
- **Features:** feature-007 (per-doc freshness loop)
- **Depends on:** delivery-001
- **Priority:** Should

### delivery-008: Skill Topology + Ship

- **What it delivers:** the `aid-ask` -> `aid-query-kb` rename + the new `aid-update-kb` skill
  (reusing delivery-001's f005 review/calibration gate via the injectable-scope seam) + query-side
  gap-capture, AND the full cross-tree render / orphan-prune / 5-install-manifest lockstep /
  "N user-facing skills" count reconcile / docs-site propagation.
- **Features:** feature-008 (skill topology, author/behavior side), feature-009 (skill-change
  propagation, ship side)
- **Depends on:** delivery-001, delivery-007
- **Priority:** Should

> **Note (f008 + f009 inseparable):** feature-008 and feature-009 are ONE delivery -- one branch,
> one PR, no release tag cut between them. Per the whole-work review, render-drift CI is RED on
> f008 alone (canonical renamed but host trees not re-rendered); f009 is what makes it green.
> Cutting a release between them would ship a half-renamed repo. See Cross-Cutting Risks.

### delivery-009: Lifecycle Governance

- **What it delivers:** the non-overlapping `aid-housekeep` (KB-DELTA, source-driven, global) <->
  `aid-update-kb` (prompt-driven, targeted) boundary contract, with per-doc staleness (f007) as the
  shared scoping signal, AND concept-closure promoted from a discovery-only check to a standing
  invariant re-verified after every KB-mutating skill run.
- **Features:** feature-010 (housekeep <-> update-kb boundary & standing closure)
- **Depends on:** delivery-001, delivery-007, delivery-008
- **Priority:** Should

### delivery-010: Domain-Driven Discovery (+ dual-audience authoring)

- **What it delivers:** generalizes `/aid-discover` beyond software to **any digital work**
  (feature-014, FR-37–FR-44). Adds (1) a **domain-agnostic generic-core dimension spine**
  (standards-grounded -- arc42/C4/IEEE1016/ISO42010/ADR; the C0-C9 concern model becomes its
  *software rendering*); (2) **source-driven domain classification** (brownfield-first;
  decisive source classifies, uncertainty asks the user); (3) **doc-set via a curated
  domain->doc-set matrix with a research fallback** (anchored to the spine, composable for
  hybrids, proposed->confirmed; today's 15-doc seed = the matrix's *software row*); (4) the
  **matrix lifecycle** (ships in `canonical/`, local per-project persistence, optional
  PR-candidate emit, NO automatic install->canonical feedback); (5) **self-bootstrap STATE**
  (discovery self-creates `STATE.md`, no init precondition); (6) **source-first fill,
  user-as-gap-filler**; and (7) the **dual-audience authoring standard** -- single-concern
  small docs, junior-clear language, tables/bullets-no-diagrams, machine-consumable
  classification, `frontmatter->index->content->changelog` layout -- wired into kb-authoring +
  templates + generation prompts and **enforced by the review panel's Anatomy mandate**.
- **Features:** feature-014 (domain-driven, source-first KB discovery + dual-audience authoring)
- **Depends on:** delivery-001 (extends f003 doc model + f004 concept spine + f005 panel),
  delivery-004 (recon/paths -- the domain classifier is the source-driven sibling; Step 0f
  reconciliation), delivery-005 (act-back panel -- the Anatomy mandate enforces the standard)
- **Priority:** Must

> **Note (extend, don't re-spec):** f014 **generalizes** f004's concept model into the
> domain-agnostic spine, **rewires** the front of GENERATE (domain-classify -> matrix-or-
> research -> propose->confirm) in place of the fixed-seed Step 0d, and **extends** f003's doc
> model with the dual-audience authoring standard the f005 panel enforces. `synth_default_seed`
> is retained as the matrix's software-row generator (byte-stable for existing tests).
> **Deferred to a follow-on:** full downstream decoupling of `aid-summarize` section-templates
> + explicit `doc.md § Section` lookups from fixed filenames.

### delivery-011: Summary Correctness Core (`kb.html` domain-driven)

- **What it delivers:** realigns `/aid-summarize` so `kb.html` becomes **right and complete for
  the new domain-driven KB** and reframes it as a **non-technical-newcomer, visually-rich**
  product (feature-015, Changes 1-5, FR-45–FR-49). Adds (1) **doc-set/domain-driven section
  derivation** — reads `discovery.doc_set` + `## Discovery Domain`, renders one section per
  resolved doc / `kb-category` from frontmatter, retires profile-as-project-type, removes the
  phantom `repo-presentation.md`, derives the `noscript` doc list; (2) **concept-first content
  components** — glossary/definition, decision/ADR card, capability entry — rendering the Concept
  Spine + `decisions.md` + capabilities as CONTENT, not links; (3) **best-format-per-fact +
  completeness grading** — removes the C+-unless-N-diagrams cap, no diagram floor/ceiling, the KB
  no-diagrams rule does NOT apply to the summary; (4) **non-technical newcomer tone** — drops the
  KB's dual-audience/agent-frontmatter framing, "At a Glance" stops leading with software
  metrics; (5) **page-shell consistency** with `home.html` + CLI `index.html` (keep/align the
  chrome; redesign only the inner content). `state-profile.md`→doc-set-driven, `state-generate.md`,
  the `knowledge-summary/*` templates, `grading-rubric.md`, `grade-summary.sh` updated.
  **Shippable midpoint:** a correct, complete, shell-consistent summary of the new KB — still
  Mermaid-backed for any diagrams. Guardrails C1/C2/C3/C5/C6 + page-shell hold.
- **Features:** feature-015 (domain-driven `kb.html` summary redesign — Changes 1-5)
- **Depends on:** delivery-010 (consumes feature-014's `discovery.doc_set`, `## Discovery Domain`,
  the seven custom docs, the concept spine, and `decisions.md`)
- **Priority:** Must

### delivery-012: Summary Visual & Engineering (SVG pre-render + drop Mermaid + fidelity gate)

- **What it delivers:** makes the summary **rich + cheap + reproducible** (feature-015, Changes
  6-7 + the §7 visual-fidelity gate, FR-50–FR-51). Adds (6) **data-driven deterministic
  generation** from the resolved doc-set (not freehand-LLM HTML) — reproducible + auditable, the
  LLM narrowed to per-component content authoring; (7) **pre-render visuals to inline SVG /
  HTML+CSS at build time and DROP the ~3MB runtime Mermaid engine** (page 3.4MB → tens of KB;
  removes the silent-failure class) — `fetch-mermaid.sh` / `mermaid-init.js` removed,
  `mermaid-examples.md` retired/recast, the page stays single-file self-contained; and the **NEW
  §7 visual-fidelity gate** — every pre-rendered visual is validated by **Playwright render**
  (preferred) or explicit visual inspection for **readable text + minimal/zero overlap + correct
  basic layout**, replacing Mermaid's render-correctness check. `validate-diagrams.mjs` →
  `validate-visuals.mjs`; `state-generate.md` / `state-validate.md` reworked; the assemble path
  made deterministic. Guardrails C1/C2/C3/C5/C6 + page-shell hold.
- **Features:** feature-015 (domain-driven `kb.html` summary redesign — Changes 6-7 + §7 gate)
- **Depends on:** delivery-011 (builds on the correct, complete, shell-consistent summary; the
  engine re-architecture + fidelity gate follow the correctness core)
- **Priority:** Must

> **Note (reader, not re-spec):** feature-015 makes `/aid-summarize` a **reader** of
> feature-014's domain-driven output; it does NOT re-spec discovery or change `discovery.doc_set`.
> The redesign keeps the production-grade visual language (design tokens, theming, lightbox, a11y)
> and the dashboard self-containment + page-shell contracts (C1/C2/C3/C5/C6 + §5b); it changes
> information architecture, content components, and generation only. **Fast-follow (OUT of this
> work):** server-side gzip/cache of the dashboard leaf (`dashboard/server/server.mjs` +
> `server.py`) — highest-ROI perf fix but a different component (the server, not the skill).

### delivery-013: Spine-Keyed Depth Contracts

- **What it delivers:** closes the **dangling-anchor gap** feature-014 left (feature-016 Change 1,
  FR-52). feature-014's `document-expectations.md` is keyed by `### <filename>` with entries for
  the 17 software docs + the 7 `methodology-tooling` docs only; the ~20+ non-software filenames the
  matrix can emit (`data-schemas.md`, `content-model.md`, `style-guide.md`, `design-tokens.md`,
  `config-schemas.md`, the shared `glossary.md`, …) have **no entry**, so the GENERATE custom-doc
  prompt (`state-generate.md` §2.6) points at a dangling anchor. This delivery authors a
  **per-spine-dimension, work-actionable depth standard** (C0–C9 + D — the C5 doc carries
  shapes/types/constraints + how-to-extend; the C3 doc carries the actual conventions + examples +
  red-flags; etc.) and **re-points the custom-doc prompt at it** so every doc inherits its
  dimension's standard, specialized to its content. The per-filename entries become optional
  additive refinements. **Shippable midpoint:** every matrix doc (all domains) resolves to a
  non-empty depth contract via its spine dimension.
- **Features:** feature-016 (dual-intent self-eval + spine-keyed depth — Change 1 / FR-52)
- **Depends on:** delivery-010 (feature-014 — the spine, the matrix's per-doc `spine-dimension`
  column, `document-expectations.md`, and `state-generate.md` §2.6 this delivery re-keys)
- **Priority:** Must

> **Note (four deliveries, not consolidated — grouping justification).** feature-016's four changes
> form a strict dependency chain with **independently shippable, independently gateable** midpoints:
> the depth standard (D-013) is a content-authoring change to expectations + one prompt line; the
> safeguard re-key (D-014) is a script/owning-table change; the dual-intent self-eval (D-015) is the
> core REVIEW-state mechanism that **consumes both** (the depth standard is what the FIX loop drives
> toward; the C9-derived task selector is the probe seed); the signature exception + dogfood (D-016)
> is a principles edit + the live AID regression that **needs the gates built first** to enforce it.
> D-013 and D-014 touch disjoint files (expectations/prompt vs the actback script) and could run in
> parallel, but D-015 needs both, so the chain D-013→D-014→D-015→D-016 keeps each A+ gate scoped to
> one coherent change-class (the [SPIKE]-style extend-after-base discipline f013/f014 followed).
> Consolidating would force a single oversized A+ gate over four distinct change-classes and lose
> the shippable D-013 midpoint (a depth standard useful even before the self-eval lands).

### delivery-014: Generalize the Safeguard (spine-keyed owning-table + C9-derived tasks)

- **What it delivers:** makes the f013 act-back safeguard **fire off-software** (feature-016
  Change 2, FR-53). Today `kb-actback-task.sh`'s `_doc_expects_class` owning-table and `_run_task`
  selector are filename-keyed software-only, so on a data/design doc-set the presence check emits
  zero rows and the task degrades to "add an endpoint" (provably inert). This delivery **re-keys the
  owning-table from filenames → spine dimensions** (single-sourced from `concern-model.md`'s
  "Operational guidance is first-class structure" table, re-stated in dimension terms — the C5 doc
  owns Contracts, the C3 doc owns Conventions, the C2 doc owns Conventions/Parts, the C7 doc owns
  Gotchas), **carries the spine dimension into the doc-set substrate** the script reads, and replaces
  the filename-profile heuristic with a **C9-derived, domain-appropriate** task selector ("add /
  modify / extend «a capability the project actually has»"). Determinism is preserved (same doc-set +
  C9 doc → byte-identical task spec); the byte-stable software seed + existing TSV-consumers stay
  green. Tests: run on data/design fixtures → domain-appropriate task + non-empty presence check.
- **Features:** feature-016 (Change 2 / FR-53)
- **Depends on:** delivery-013 (the spine-keyed depth standard the safeguard's owning-table re-states
  in dimension terms; the dimension keying is shared)
- **Priority:** Must

### delivery-015: The Dual-Intent KB Self-Evaluation (the core)

- **What it delivers:** the **core mechanism** (feature-016 §4, FR-54 + FR-55) — turns the two user
  intents into measurable, domain-general REVIEW keystone gates with **no external test corpus**.
  Adds (a) **Blind Work-Simulation** (the assertiveness gate, Intent 1) — a clean-context KB-only
  agent plans each derived **work probe** in the project's own conventions, tagging steps
  **STATED/ASSUMED/REACH**; any load-bearing ASSUMED/REACH = `[HIGH] [ACTBACK]`, and a plan that
  violates the project's conventions/invariants/quality bars = a **quality FAIL** (generalizes M4
  act-back); (b) **Blind Reconstruction + Source Confrontation** (the essence gate, Intent 2) — a
  KB-only agent reconstructs the project's what/why/how, then a **source-grounded** agent confronts
  it: **Divergence** = `[HIGH] [FIDELITY]`, **Omission** = `[MED] [ESSENCE-GAP]` (generalizes M3
  teach-back with a source-confrontation stage); (c) the **probe-derivation helper** (work probes
  from the C9 doc + domain via D-014's C9-derived selector; essence probes from C4/C9/D + salient
  source facts); (d) the **dual-intent ledger** (7-column schema, `[ACTBACK]`/`[FIDELITY]`/
  `[ESSENCE-GAP]` tags) + the **convergence thresholds** wired into REVIEW as two **hard keystone
  gates** (a FAIL caps the grade). Tests: per-domain fixtures (GOOD PASS / SHALLOW+WRONG FAIL).
- **Features:** feature-016 (§4 core / FR-54 + FR-55)
- **Depends on:** delivery-013 (the spine-keyed depth standard the FIX loop drives toward),
  delivery-014 (the spine-keyed safeguard + the C9-derived task selector that seeds the work probes)
- **Priority:** Must

> **Note (extend, don't re-spec).** D-015 **generalizes** f005's M3 teach-back + f013's M4 act-back
> reviewer-prompt bodies and reuses f005's parallel-panel dispatch + `grade.sh` + the 7-column
> ledger schema **verbatim** — no new grading infra, no separate verdict sentinel, no new agent enum
> value (consistent with f013's extend-after-base discipline). The new probe-derivation helper
> extends `kb-actback-task.sh` / `kb-teachback-questions.sh`; the source-confrontation second stage
> is the one genuinely new sub-agent role-shape (a source-grounded confronter), built on the existing
> reviewer dispatch.

### delivery-016: Altitude Signature Exception + Dogfood + Re-inject Lost Depth

- **What it delivers:** repairs the **altitude-rule signature tax** (feature-016 Change 3, FR-56)
  and runs the **live AID dogfood regression**. Amends `principles.md` P1(d) + the
  altitude/summary+pointer rule with a **signature exception**: load-bearing operational contracts an
  agent must honor to ACT (field types, exit codes, args/modes/invariants) are stated **INLINE or
  with a precise grep-recoverable anchor**, never a bare `sources:` file pointer (the altitude rule
  keeps de-bloating *narrative* volatility, not *work-critical contracts*; the assertiveness limb
  enforces it automatically). Runs the dual-intent eval on AID's own KB (software + methodology) as
  the live regression and **re-injects the AID instance's altitude-rule-evicted depth** (the host-tool
  matrix, exit-codes) as the **first beneficiary** of the exception. Closes feature-016.
- **Features:** feature-016 (Change 3 / FR-56 + dogfood)
- **Depends on:** delivery-015 (the assertiveness gate that enforces the signature exception must
  exist before the exception is enforced + dogfooded)
- **Priority:** Must

## Cross-Cutting Risks

> **Retired R1 (greenfield scope-split).** The original R1 tracked the f006/f012
> brownfield-vs-greenfield split across delivery-004 (Adaptive Paths) + the Validation delivery
> (then delivery-005, now delivery-006 after the act-back insert) and the deleted greenfield-path
> delivery (the defunct pre-act-back greenfield-path delivery -- NOT the current live delivery-009
> Governance). With greenfield reduced to detect + signpost inside delivery-004's recon (no separate
> greenfield delivery, no greenfield generation path), there is no split to manage and the
> risk is moot. R2/R3 below retain their original numbering.

| # | Risk | Affected deliveries | Mitigation |
|---|------|---------------------|------------|
| R2 | **f008+f009 inseparability** -- a release tag cut between feature-008 (canonical rename) and feature-009 (cross-tree propagation) would ship a half-renamed repo: canonical renamed but the 5 host trees, install manifests, and skill counts stale, with render-drift CI red. | delivery-008 | The two features are **one delivery** -- one branch, one PR, **no intervening release tag**. render-drift CI is RED on f008 alone and green only once f009 propagates, so the gate itself enforces "ship together." |
| R3 | **calibration-floor back-patch** -- delivery-006 (validation fixtures) re-tunes defaults that ALREADY shipped in merged delivery-001 (f004 SPIKE-H2 denylist/salience floor, f005 SPIKE-C1 calibration severity) and delivery-004 (f006 triage thresholds). Per the contract "the default lives in the owning feature's file; the fixture pins it," editing a constant in an already-shipped delivery can regress that delivery's gate. **Impact: M.** | delivery-001, delivery-004, delivery-006 | After any threshold/floor edit prompted by a later delivery's fixture, re-run the owning delivery's gate suite (the owning feature's canonical tests) to confirm no regression. |
| R4 (f016) | **software-row byte-stability** -- re-keying the act-back safeguard substrate (delivery-014 adds a spine-dimension to the doc-set TSV / a filename→dimension map) and re-injecting altitude-evicted depth into AID's own KB (delivery-016) must **not perturb** `synth_default_seed`'s byte-stable software seed or its existing `kb-actback-task.sh` TSV-consumers, or DBI + the matrix seed-consistency check go red. **Impact: M (cross-delivery hazard).** | delivery-014, delivery-016 | The matrix seed-consistency check + the existing actback-task suite are the regression guards; the software rows stay byte-identical (additive dimension column / sidecar map only). Re-run both suites + DBI after any substrate edit. |
| R5 (f016) | **threshold calibration spans the dogfood** -- the dual-intent gates' concrete PASS thresholds (assertiveness % STATED, essence-coverage %) are deferred to DETAIL/delivery-015 and tuned against the **AID dogfood + the per-domain fixtures**; a number set too loose passes a shallow KB, too strict thrashes the FIX loop, and it is only validated once D-015's fixtures + the live AID regression both run. **Impact: M.** | delivery-015, delivery-016 | Start strict (zero HIGH; ≥90% STATED); calibrate on the AID dogfood + the GOOD/SHALLOW/WRONG fixtures; the fixtures pin the chosen number so a later drift is caught. |
| R6 (f016) | **probe-derivation quality** -- the dual-intent gates are only as good as the probes derived from the project's C9/C4/D docs + source; a thin probe set can pass a KB that a richer set would FAIL. **Impact: L.** | delivery-015 | Derive a spread across spine dimensions + a minimum count; the human may confirm/extend the probe set at the gate (the no-assumptions pattern). |
| R7 (f016) | **cost / agent-work scaling** -- two clean-context limbs x K probes per REVIEW cycle is materially more agent work than the single act-back/teach-back task today. **Impact: L.** | delivery-015 | Scale K by triage size; cache probes across REVIEW⇄FIX cycles. |

## Execution Graphs

The graphs below are derived mechanically from the `Depends on:` line of every
task SPEC (`delivery-NNN/tasks/task-NNN/SPEC.md`). Each delivery's `Depends On`
table lists the task's FULL dependency set; dependencies that point into an
**earlier** delivery are marked `(d-NNN)` and are pre-satisfied by the
delivery-order sequence (d001 -> d010), so they do not affect intra-delivery
wave ordering. The `wave-map` block is total over the delivery's own tasks.

**delivery-011 and delivery-012 are now detailed** (feature-015, authored by
`/aid-detail`): delivery-011 = tasks 064-070 (Changes 1-5, the correctness core)
and delivery-012 = tasks 071-076 (Changes 6-7 + the §7 visual-fidelity gate).
Their graphs below carry full `Depends On` tables + `wave-map` blocks like the
others; the invariant — "every dependency resolves to an existing task" — now
applies to them too. Every d011/d012 task also carries the cross-delivery
dependency (d011→d010, d012→d011) as a pre-satisfied edge that does not affect
intra-delivery wave ordering.

**Global-DAG validation (all 76 detailed tasks assembled across
delivery-001..012):** acyclic (76/76 topo-sorted); every dependency resolves to
an existing task; no forward reference across deliveries (no dep points into a
later delivery); no intra-delivery dependency on a higher-numbered sibling.
Roots (no deps at all): task-001, task-031, task-032, task-033, task-037,
task-045, task-047, task-073. (feature-013 / act-back was inserted as delivery-005
= tasks 027-030, all of which depend into delivery-001, so none is a root; the
downstream paper deliveries shifted down one and renumbered contiguously.
feature-015 added 13 tasks across delivery-011..012 — task-073 (d012's Playwright
provisioning, depends-on nothing) is the one new true root; task-064 is the d011
intra-delivery root but depends into delivery-010, so it is not a no-deps global
root. 76 tasks across delivery-001..012; tasks 001-026 / delivery-001..004 are
FROZEN/byte-untouched.)

### delivery-001 execution graph

| Task | Depends On |
|------|-----------|
| task-001 | — |
| task-002 | task-001 |
| task-003 | task-002 |
| task-004 | task-001 |
| task-005 | task-001 |
| task-006 | task-002 |
| task-007 | task-006 |
| task-008 | task-002, task-006 |
| task-009 | task-008 |
| task-010 | task-001, task-004 |
| task-011 | task-006, task-008, task-010 |
| task-012 | task-006 |
| task-013 | task-008 |
| task-014 | task-008, task-012 |

| Can Be Done In Parallel |
|------------------------|
| task-002, task-004, task-005 |
| task-003, task-006, task-010 |
| task-007, task-008, task-012 |
| task-009, task-011, task-013, task-014 |

```wave-map
delivery: 001
wave 1: task-001
wave 2: task-002, task-004, task-005
wave 3: task-003, task-006, task-010
wave 4: task-007, task-008, task-012
wave 5: task-009, task-011, task-013, task-014
```

### delivery-002 execution graph

| Task | Depends On |
|------|-----------|
| task-015 | task-002 (d001) |
| task-016 | task-015 |
| task-017 | task-015, task-016 |

| Can Be Done In Parallel |
|------------------------|
| — |

```wave-map
delivery: 002
wave 1: task-015
wave 2: task-016
wave 3: task-017
```

### delivery-003 execution graph

| Task | Depends On |
|------|-----------|
| task-018 | task-001 (d001), task-003 (d001), task-015 (d002) |
| task-019 | task-018 |
| task-020 | task-003 (d001), task-018 |
| task-021 | task-010 (d001), task-018 |
| task-022 | task-018, task-019, task-020, task-021 |

| Can Be Done In Parallel |
|------------------------|
| task-019, task-020, task-021 |

```wave-map
delivery: 003
wave 1: task-018
wave 2: task-019, task-020, task-021
wave 3: task-022
```

### delivery-004 execution graph

| Task | Depends On |
|------|-----------|
| task-023 | task-006 (d001) |
| task-024 | task-023 |
| task-025 | task-023, task-011 (d001) |
| task-026 | task-014 (d001), task-025 |

| Can Be Done In Parallel |
|------------------------|
| task-024, task-025 |

```wave-map
delivery: 004
wave 1: task-023
wave 2: task-024, task-025
wave 3: task-026
```

### delivery-005 execution graph

| Task | Depends On |
|------|-----------|
| task-027 | task-004 (d001), task-010 (d001) |
| task-028 | task-008 (d001), task-027 (d005) |
| task-029 | task-027, task-028, task-014 (d001) |
| task-030 | task-028 |

| Can Be Done In Parallel |
|------------------------|
| task-029, task-030 |

```wave-map
delivery: 005
wave 1: task-027
wave 2: task-028
wave 3: task-029, task-030
```

### delivery-006 execution graph

| Task | Depends On |
|------|-----------|
| task-031 | — |
| task-032 | — |
| task-033 | — |
| task-034 | task-031, task-006 (d001), task-008 (d001) |
| task-035 | task-032, task-008 (d001) |
| task-036 | task-033, task-023 (d004) |
| task-037 | — |
| task-038 | task-037, task-012 (d001) |
| task-039 | task-028 (d005), task-029 (d005) |

| Can Be Done In Parallel |
|------------------------|
| task-031, task-032, task-033, task-037 |
| task-034, task-035, task-036, task-038, task-039 |

```wave-map
delivery: 006
wave 1: task-031, task-032, task-033, task-037
wave 2: task-034, task-035, task-036, task-038, task-039
```

### delivery-007 execution graph

| Task | Depends On |
|------|-----------|
| task-040 | task-001 (d001), task-002 (d001) |
| task-041 | task-040 |
| task-042 | task-040, task-001 (d001) |
| task-043 | task-042 |
| task-044 | task-042 |

| Can Be Done In Parallel |
|------------------------|
| task-041, task-042 |
| task-043, task-044 |

```wave-map
delivery: 007
wave 1: task-040
wave 2: task-041, task-042
wave 3: task-043, task-044
```

### delivery-008 execution graph

| Task | Depends On |
|------|-----------|
| task-045 | — |
| task-046 | task-045 |
| task-047 | — |
| task-048 | task-047, task-014 (d001), task-040 (d007) |
| task-049 | task-046, task-048 |
| task-050 | task-049 |
| task-051 | task-050 |
| task-052 | task-049 |

| Can Be Done In Parallel |
|------------------------|
| task-045, task-047 |
| task-046, task-048 |
| task-050, task-052 |

```wave-map
delivery: 008
wave 1: task-045, task-047
wave 2: task-046, task-048
wave 3: task-049
wave 4: task-050, task-052
wave 5: task-051
```

### delivery-009 execution graph

| Task | Depends On |
|------|-----------|
| task-053 | task-048 (d008) |
| task-054 | task-053, task-040 (d007), task-008 (d001) |
| task-055 | task-054 |

| Can Be Done In Parallel |
|------------------------|
| — |

```wave-map
delivery: 009
wave 1: task-053
wave 2: task-054
wave 3: task-055
```

### delivery-010 execution graph

| Task | Depends On |
|------|-----------|
| task-056 | delivery-001 (base: f003 doc model + f004 concept spine) |
| task-057 | task-056 |
| task-058 | task-056, delivery-004 (recon/paths -- Step 0f reconciliation) |
| task-059 | task-057, task-058 |
| task-060 | — |
| task-061 | task-056, delivery-005 (act-back panel -- Anatomy mandate) |
| task-062 | task-059, task-060, task-061 |
| task-063 | task-062 |

| Can Be Done In Parallel |
|------------------------|
| task-056, task-060 |
| task-057, task-058, task-061 |

```wave-map
delivery: 010
wave 1: task-056, task-060
wave 2: task-057, task-058, task-061
wave 3: task-059
wave 4: task-062
wave 5: task-063
```

### delivery-011 execution graph

> Authored by `/aid-detail` (feature-015 Changes 1-5). All d011 tasks build on **delivery-010**
> (the domain-driven KB the summary reads) — a pre-satisfied cross-delivery dependency marked
> `(d-010)`; it does not affect intra-delivery wave ordering.

| Task | Depends On |
|------|-----------|
| task-064 | delivery-010 (feature-014 doc-set + domain + custom docs) |
| task-065 | task-064 |
| task-066 | task-065 |
| task-067 | task-064 |
| task-068 | task-065, task-066 |
| task-069 | task-065, task-066, task-067, task-068 |
| task-070 | task-065, task-066, task-067, task-068, task-069 |

| Can Be Done In Parallel |
|------------------------|
| task-065, task-067 |

```wave-map
delivery: 011
wave 1: task-064
wave 2: task-065, task-067
wave 3: task-066
wave 4: task-068
wave 5: task-069
wave 6: task-070
```

### delivery-012 execution graph

> Authored by `/aid-detail` (feature-015 Changes 6-7 + the §7 visual-fidelity gate). All d012
> tasks build on **delivery-011** (the correctness core the engine re-architecture builds on) — a
> pre-satisfied cross-delivery dependency marked `(d-011)`; it does not affect intra-delivery wave
> ordering. task-071 and task-073 are intra-delivery roots (task-073 provisions the Playwright
> dependency in parallel with the assembly re-architecture).

| Task | Depends On |
|------|-----------|
| task-071 | delivery-011 (summary correctness core) |
| task-072 | task-071 |
| task-073 | — |
| task-074 | task-072, task-073 |
| task-075 | task-071, task-072, task-074 |
| task-076 | task-071, task-072, task-073, task-074, task-075 |

| Can Be Done In Parallel |
|------------------------|
| task-071, task-073 |

```wave-map
delivery: 012
wave 1: task-071, task-073
wave 2: task-072
wave 3: task-074
wave 4: task-075
wave 5: task-076
```

### delivery-013 execution graph

> Authored by `/aid-detail` (feature-016 Change 1 / FR-52). Every d013 task carries the
> cross-delivery dependency on **delivery-010** (feature-014 — the spine + matrix +
> `document-expectations.md` + `state-generate.md` §2.6) as a pre-satisfied edge marked `(d-010)`
> that does not affect intra-delivery wave ordering. Linear DESIGN -> IMPLEMENT -> TEST chain:
> task-077 designs the dimension standard + authority-file decision, task-078 authors it + re-points
> the GENERATE prompt, task-079 asserts the 36-doc gap is closed + DBI.

| Task | Depends On |
|------|-----------|
| task-077 | delivery-010 (feature-014 spine + matrix + expectations + §2.6 prompt) |
| task-078 | task-077 |
| task-079 | task-078 |

| Can Be Done In Parallel |
|------------------------|
| — (linear chain) |

```wave-map
delivery: 013
wave 1: task-077
wave 2: task-078
wave 3: task-079
```

### delivery-014 execution graph

> Authored by `/aid-detail` (feature-016 Change 2 / FR-53). All d014 tasks build on **delivery-013**
> (the spine-keyed depth standard whose dimension keying the safeguard owning-table re-states) — the
> cross-delivery edge is realized as `task-080 -> task-078` (the dimension keying is shared), which
> does not affect intra-delivery wave ordering. Linear DESIGN -> IMPLEMENT -> TEST chain: task-080
> restates the owning-table in dimension terms + decides the substrate lookup, task-081 re-keys the
> script + concern-model.md, task-082 adds the doc-set TSV fixtures + off-software assertions + DBI.

| Task | Depends On |
|------|-----------|
| task-080 | task-078 (d-013 — spine-keyed depth / dimension keying) |
| task-081 | task-080 |
| task-082 | task-081 |

| Can Be Done In Parallel |
|------------------------|
| — (linear chain) |

```wave-map
delivery: 014
wave 1: task-080
wave 2: task-081
wave 3: task-082
```

### delivery-015 execution graph

> Authored by `/aid-detail` (feature-016 §4 core / FR-54 + FR-55). d015 builds on **delivery-013**
> (the depth standard the FIX loop drives toward) and **delivery-014** (the spine-keyed safeguard +
> the C9-derived task selector that seeds the work probes) — realized as `task-083 -> task-081`
> (C9 selector seed) and `task-083 -> task-078` (depth standard). task-083 (the probe-derivation
> helper) is the intra-delivery root; the two limbs (task-084 assertiveness, task-085 essence) both
> consume its probes and run **in parallel**; task-086 wires both limbs into the dual-intent ledger +
> keystone gates (incl. re-keying the §2c/§2d verdict greps); task-087 proves the gates fire
> off-software via the per-domain GOOD/SHALLOW/WRONG mini-KB fixtures + `test-dual-intent-self-eval.sh`.

| Task | Depends On |
|------|-----------|
| task-083 | task-081 (d-014 — C9-derived selector seed), task-078 (d-013 — depth standard) |
| task-084 | task-083 |
| task-085 | task-083 |
| task-086 | task-084, task-085 |
| task-087 | task-083, task-084, task-085, task-086 |

| Can Be Done In Parallel |
|------------------------|
| task-084, task-085 |

```wave-map
delivery: 015
wave 1: task-083
wave 2: task-084, task-085
wave 3: task-086
wave 4: task-087
```

### delivery-016 execution graph

> Authored by `/aid-detail` (feature-016 Change 3 / FR-56 + dogfood). d016 builds on **delivery-015**
> (the assertiveness gate that enforces the signature exception must exist before it is enforced +
> dogfooded) — realized as `task-088 -> task-086` (the dual-intent keystone gates). Linear IMPLEMENT
> -> DOCUMENT -> TEST chain: task-088 states the altitude signature exception in `principles.md`,
> task-089 re-injects AID's evicted depth (host-tool matrix, exit-codes) into its own KB docs + regens
> INDEX, task-090 runs the live AID dogfood (both gates pass) + the regen/DBI/hygiene re-checks that
> close feature-016.

| Task | Depends On |
|------|-----------|
| task-088 | task-086 (d-015 — the dual-intent keystone gates) |
| task-089 | task-088 |
| task-090 | task-089 |

| Can Be Done In Parallel |
|------------------------|
| — (linear chain) |

```wave-map
delivery: 016
wave 1: task-088
wave 2: task-089
wave 3: task-090
```
