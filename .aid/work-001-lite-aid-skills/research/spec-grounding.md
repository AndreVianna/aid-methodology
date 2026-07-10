# Spec-Grounding Research Report — work-001-lite-aid-skills

> **Author:** aid-researcher · **Date:** 2026-07-07 · **Phase grounded:** `/aid-specify`
> **Purpose:** For each open spec-phase decision (A-2, A-6, A-7, A-8, A-9, cutover), separate
> **what the current code/requirements already settle** from **what genuinely needs a human
> design choice**. Read-only investigation; the only file written is this report.
> **Citation style:** path + grep-recoverable symbol/heading (durable anchors), not bare line numbers.
> **Confidence tags:** CONFIRMED (directly observed) · LIKELY (strong inference) · UNCERTAIN.

---

## Q-A2 — Skill definition & invocation mechanics (the master decision)

### Code answer (facts + citations)

**1. How a skill is defined.** A user-facing skill is a directory `canonical/skills/<name>/`
containing `SKILL.md` (required) + optional `references/*.md` + optional `scripts/`. The
`SKILL.md` frontmatter carries `name:`, `description:` (with an inline `State machine:` line),
`allowed-tools:`, and an optional `argument-hint:`.
CONFIRMED — `canonical/skills/aid-describe/SKILL.md` frontmatter (`name: aid-describe`,
`argument-hint: "[work-001] resume work ..."`); `canonical/skills/aid-execute/SKILL.md`
frontmatter (`name: aid-execute`, `argument-hint: "work-001 ... task-001 ..."`).

**2. How the generator renders the invocation name — it is the DIRECTORY NAME, not a
frontmatter field.** In `render.py` (`.claude/skills/generate-profile/scripts/render.py`), the
skills branch (grep `translate == "skills"`) does:
`skill_slug = skill_dir.name` → `out_skill_dir = dst_dir / skill_slug` → writes
`out_skill_dir / "SKILL.md"`. The loop is strictly one-to-one over `skill_dirs`
(grep `for skill_dir in skill_dirs`). The frontmatter `name:` is carried through untouched
(only `allowed-tools` is remapped via `_rewrite_skill_frontmatter`); nothing reads `name:` to
mint the output path. CONFIRMED — `render.py` (grep `skill_slug = skill_dir.name`).
Contrast with **agents**, where the output name DOES come from frontmatter
(`agent_name = fm.get("name", src_path.parent.name)`, grep `_translate_agent` in `render.py`) —
skills deliberately do not do this. Consequence: **one canonical skill directory ⇒ exactly one
rendered skill directory ⇒ exactly one slash-command, in every one of the five profiles.** The
host tool derives `/aid-<dir>` from that directory (its `name:` frontmatter equals the dir name
by convention). KB corroboration: `architecture.md § Skill State-Machine Model`
("A skill's entry file is `canonical/skills/<name>/SKILL.md`").

**3. Is there an alias mechanism? NO.** A repo-wide search for `alias` finds only (a) model-tier
aliases in the generator (`aid_profile.py` grep `model_tiers`; `render.py` grep `tier alias`),
and (b) KB-glossary concept synonyms (`canonical/aid/scripts/kb/closure-check.sh` grep
`Aliases:`; `aid-discover/references/agent-prompts.md` grep `Aliases (optional)`). There is **no
command-alias / two-names-one-skill facility** anywhere in the generator or the skill model.
The `EMISSION-MANIFEST.md` render table (grep `canonical/skills/`) confirms skills mirror
1:1 into `<root>/skills/`. CONFIRMED.

**4. Is there a parameterized-invocation precedent? YES — two distinct patterns, both
*internal* (not a command-arg alias).**
- **`aid-execute` dispatches by task-type at RUNTIME by reading a file field.** It reads the
  `Type` field from the task `SPEC.md` (grep `Read task` / `Type` in
  `canonical/skills/aid-execute/SKILL.md § Check 2`), then applies per-type rules from
  `canonical/skills/aid-execute/references/task-type-rules.md` (one `## IMPLEMENT`/`## TEST`/…
  section per type). One skill, eight behaviors, selected from a file field — NOT from a
  distinct command name. CONFIRMED.
- **`aid-describe` handled recipes/sub-paths by INTERNAL routing + slot-fill.** Its `TRIAGE`
  state (`canonical/skills/aid-describe/references/state-triage.md`, grep `Find best-matching
  recipe`) infers a `workType` and scans `canonical/aid/recipes/` to pick a recipe by
  `applies-to` + `summary:`, then `parse-recipe.sh`
  (`canonical/aid/scripts/interview/parse-recipe.sh`) extracts the recipe's slots and emits the
  work. One skill (`aid-describe`) fans out to 51 work-types via a *parameter captured at
  runtime*, not via 51 command names. CONFIRMED. This is the direct precedent the shortcut
  engine (feature-003) generalizes.

**5. What the code makes feasible for the 45-name + 24-alias catalog.** Because invocation
name == directory (fact 2) and there is no alias facility (fact 3), **every distinct invocation
name a user can type MUST be its own `canonical/skills/<name>/` directory with its own
`SKILL.md`.** That is code-determined: 45 canonical names + 24 aliases = **69 skill directories
are mandatory** for AC-1's "45 canonical skills … and the 24 aliases resolve correctly" to hold
under the current generator. There is no topology in which fewer than 69 directories yield 69
working slash-commands, absent a new host/generator alias mechanism (which would be net-new
machinery and is not what A-2 contemplates).

What each option would then require:
- **(a) 45 (really 69) *fat* SKILL.md directories** — each a full state-machine. Requires
  nothing new in the generator, but duplicates the entire Lite-path state machine 69× →
  directly violates NFR-8 ("must not multiply maintenance cost") and NFR-1 byte-review load.
- **(b) 69 *thin* entry-point SKILL.md directories over one shared engine** — each `SKILL.md`
  is a few lines that bind `{verb, artifact}` and delegate to a single shared shortcut-engine
  reference. The engine logic lives ONCE. Feasible today because skills already reference shared
  assets under `canonical/aid/` (templates/scripts) by install-path-rewritten path
  (`render.py` grep `rewrite_install_paths`; the `canonical/aid/` subtree is copied verbatim
  once per profile — grep `translate="none"` in `render.py`). So the engine can live at e.g.
  `canonical/aid/templates/shortcut-engine.md` (or a new `canonical/aid/` sub-file), copied once,
  and all 69 thin `SKILL.md`s point at it. Requires: the 69 dirs (mechanical/generated) + one
  shared engine doc + a generation helper so the 69 near-identical dirs are not hand-maintained.
- **(c) hybrid** — ~13 "fat" verb skills (`aid-prototype`, `aid-create`, `aid-change`,
  `aid-refactor`, `aid-fix`, `aid-test`, `aid-experiment`, `aid-document`, `aid-deploy`,
  `aid-monitor`, `aid-report`, `aid-show-dashboard`, `aid-triage`) that hold the state machine,
  plus the artifact-suffixed + alias names as thin shims that set the artifact parameter and
  delegate to their verb sibling's engine. This is (b) with the shared engine co-located in the
  bare-verb skill's `references/` rather than under `aid/`.

**Code-determined vs. human-preference split:**
- CODE-DETERMINED: 69 directories are required (one per invocation name); there is no alias
  layer; the shared logic *can* be centralized under `canonical/aid/` and referenced by path.
- HUMAN-PREFERENCE: how thin each `SKILL.md` is; where the shared engine physically lives
  (`canonical/aid/` shared doc vs. bare-verb `references/`); and whether the 69 dirs are authored
  by hand or emitted by a small generation helper from a catalog manifest.

### Residual human decision

> **Decision:** Given that 69 directories are mandatory regardless, how thin should each
> `SKILL.md` be and where does the single shared engine live — one central engine under
> `canonical/aid/` referenced by 69 thin shims (b), or the state machine held in ~13 bare-verb
> skills with suffixed/alias forms as delegating shims (c)?
>
> **Tech-lead recommendation:** Option **(b) with a catalog-driven generator** — a single
> `shortcut-engine` reference under `canonical/aid/`, plus a tiny build helper that emits the 69
> thin `SKILL.md` dirs from a `catalog.yml` (`verb, artifact, alias-of, intent`). This honors
> NFR-8 (logic authored once), NFR-1 (byte-review surface stays small — you review the engine +
> the generator + the manifest, not 69 hand-written state machines), and matches the existing
> `aid-describe`→recipe precedent (one engine, many parameterized work-types). Reserve (c) only
> if a host tool proves it cannot resolve a `name`-only shim without body content.

---

## Q-A6 — Task-type enum (non-code coverage)

### Code answer (facts + citations)

**1. The enum is 8 values and its authoritative source is the task SPEC schema.** CONFIRMED,
exact list: `RESEARCH | DESIGN | IMPLEMENT | TEST | DOCUMENT | MIGRATE | REFACTOR | CONFIGURE`.
- Authoritative schema: `artifact-schemas.md` frontmatter `contracts:` ("Task Type enum
  (closed, 8): RESEARCH | DESIGN | IMPLEMENT | TEST | DOCUMENT | MIGRATE | REFACTOR | CONFIGURE")
  and its `## Task SPEC.md` section.
- Template source: `canonical/aid/templates/task-spec-template.md` (grep `Type`), consumed by
  `canonical/skills/aid-execute/SKILL.md § Check 2` and enforced per-type in
  `canonical/skills/aid-execute/references/task-type-rules.md` (`## IMPLEMENT` … `## CONFIGURE`).
- Contract note: `pipeline-contracts.md § Typed Artifact Contracts` and `§ Contracts`
  ("Task contract … changing the enum breaks both [executor and reviewer]").

**2. The per-task/delivery gate is NOT hardcoded to code artifacts.** The build/lint/test gate
is (a) *per-IMPLEMENT-task*, (b) *read from the KB*, and (c) *conditional*: `task-type-rules.md
## IMPLEMENT` says "Verify gates pass (from KB — technology-stack.md § Commands via INDEX): 1.
Build — ALWAYS 2. Lint — IF CONFIGURED 3. Unit tests — IF CONFIGURED." The non-code types
explicitly declare no build gate: `## RESEARCH` ("No code changes to the project — research
produces documents only"), `## DESIGN` / `## DOCUMENT` ("Write artifacts to paths specified in
task Scope"). CONFIRMED.
The **delivery gate itself is type-agnostic**: it is the reviewer + `grade.sh` loop, not a
compiler. `canonical/skills/aid-execute/references/state-delivery-gate.md` (`## DELIVERY-GATE
State Machine`: AGGREGATE → SCORE → REVIEW → GRADE → ROUTE → RECORD) re-verifies "build/lint/test
gates pass (**as applicable to the delivery's task types**)" — grep `as applicable`. Its
complexity SCORE table already weights non-code types at `+0`
(`RESEARCH/DESIGN/DOCUMENT/CONFIGURE +0`). CONFIRMED.

**3. Does prototype / experiment / report / dashboard need new types? NO — they map onto the
existing enum.** LIKELY mapping (each is an existing type, no pipeline-contract change):
- **prototype** → `DESIGN` (low-fidelity model / wireframe) or `IMPLEMENT` (throwaway working code).
- **experiment (A/B)** → `RESEARCH` (hypothesis → analyze → recommend; `## RESEARCH` already says
  "Compare ≥2 alternatives … end with a recommendation"), with an `IMPLEMENT` task if variants
  must be built.
- **report / EDA** → `RESEARCH` (analysis producing a document) or `DOCUMENT` (writing it up).
- **show-dashboard** → `IMPLEMENT` (a BI view is code/config) or `DESIGN` (the view layout).
The enum was built to cover exactly this non-code space; nothing in `task-type-rules.md` or
`state-delivery-gate.md` forces a code artifact.

### Residual human decision

> **Decision:** Confirm no new task type is introduced, and fix the *default type mapping* each
> non-code shortcut assigns to its generated tasks (a scaffolding convention, not a
> pipeline-contract change).
>
> **Tech-lead recommendation:** **Do NOT extend the 8-type enum** (extending it is a lockstep
> break across `grade.sh`, both dashboard reader twins, and every grading skill —
> `artifact-schemas.md § Contracts` "Closed STATE enums are byte-stable"). Instead specify a
> per-verb default-type table inside the shortcut engine: prototype→DESIGN, experiment→RESEARCH,
> report→RESEARCH, show-dashboard→IMPLEMENT (others follow the obvious verb→type match). This is
> a `/aid-specify` scaffolding detail, not an A-6 pipeline change. A-6 is **code-settled**.

---

## Q-A7 — Grading gates vs. "materially faster" (NFR-5) — *(synthesis-scoped; short)*

### Code answer

The grading machinery is generic and **already supports batching**: the delivery gate dispatches
ONE `aid-reviewer` over a whole delivery's worth of artifacts at once — the gate reviewer's
`{{ARTIFACTS}}` is "the full delivery branch diff + every task's STATE.md row + the PLAN.md
delivery section" (`state-delivery-gate.md § Gate Reviewer Inputs`), graded by a single `grade.sh`
run (`§ Step 3: GRADE`). There is no code requirement that each document be a *separate*
reviewer dispatch; the 7-column ledger + `grade.sh` (per CLAUDE.md "Review output format") work
over any artifact set. So a single batched pass over the small flattened `{REQUIREMENTS, SPEC,
PLAN}` triple is mechanically supported today. CONFIRMED.

### Residual human decision

> **Decision:** Keep per-phase separate reviewer dispatches (4+ passes: REQUIREMENTS, SPEC, PLAN,
> each task SPEC) or batch the flattened definition docs into fewer passes to satisfy NFR-5?
>
> **Tech-lead recommendation:** **Batch the three definition docs** (`REQUIREMENTS`+`SPEC`+`PLAN`)
> into ONE reviewer dispatch producing one ledger, and batch the task `SPEC.md` set into a second
> pass — 2 dispatches instead of 4+, reusing the existing "one reviewer, many artifacts" pattern.
> Each still clears `minimum_grade` via REVIEW→FIX (FR-11 preserved); the win is fewer sub-agent
> round-trips (NFR-5). The gates are **not** removed — the *dispatch granularity* is the only
> lever, and it is a pure `/aid-specify` policy choice with no contract impact.

---

## Q-A8 — Delivery-scoped state in the flattened (single-delivery) layout

### Code answer (facts + citations)

**1. What lives in `delivery-NNN/STATE.md` today.** Source `canonical/aid/templates/delivery-state-template.md`
+ `artifact-schemas.md § Delivery STATE.md`. Three AUTHORED sections + one DERIVED:
- `## Delivery Lifecycle` (AUTHORED): `State: Pending-Spec | Specified | Executing | Gated |
  Done | Blocked` (independently authored, **not** a task rollup — see the template's
  `DELIVERY LIFECYCLE ENUM` comment "NOT a derivation of child task states"), `Updated`,
  conditional `Block Reason`/`Block Artifact`.
- `## Delivery Gate` (AUTHORED): `Reviewer Tier`, `Grade`, `Issue List`, `Timestamp`.
- `## Cross-phase Q&A` (AUTHORED): per-Q blocks (`Category`/`Impact`/`State`/…).
- `## Tasks State` (DERIVED rollup from `tasks/task-NNN/STATE.md`).
- **git branch:** `aid/work-NNN-delivery-NNN` (template header `> **Branch:**`; and
  `aid-execute/SKILL.md § Check 5` grep `aid/{work}-delivery-NNN`).
CONFIRMED.

**2. What the schema constrains.** From `artifact-schemas.md § Contracts`: (i) "One writer per
file" and "DERIVED sections are read-only" — the AUTHORED/DERIVED split exists specifically to
keep **two parallel delivery branches from colliding** on a shared file (the "disjoint-write
property"). (ii) "Closed STATE enums are byte-stable" — the `Delivery Lifecycle` and `Delivery
Gate` grade strings are parsed by **both dashboard reader twins** (`dashboard/reader/*.py` +
`reader.mjs`) and `writeback-state.sh`; moving the *fields* is fine, renaming/dropping their
*enum values* is a lockstep break. The `pipeline-contracts.md § Contracts` "State-file contract"
adds: "the dashboard and `/aid-execute` read these files to track a pipeline … Renaming or
restructuring `STATE.md` sections breaks the dashboard reader."

**3. Why the flattened case is *unconstrained* by the collision rule.** The disjoint-write
property only bites when there are ≥2 delivery branches. FR-8 stipulates **exactly one delivery**
(no `delivery-NNN/`), so there is exactly one writer — the collision rationale evaporates. Note
today's lite path does **not** flatten: `artifact-schemas.md § Delivery STATE.md` says
"On the lite path, `aid-describe` creates `delivery-001/STATE.md` directly (State `Executing`)" —
so there is **no existing precedent** for delivery-scoped state living outside a `delivery-NNN/`
folder. That gap is exactly what A-8 must fill. CONFIRMED.

**Options for where the fields go (all schema-legal since single-writer):**
- (i) Promote the AUTHORED delivery sections into the **work-root `STATE.md`** as first-class
  authored sections (`## Delivery Lifecycle`, `## Delivery Gate`), alongside the existing
  `## Pipeline State`/`## Lifecycle History`. In the multi-delivery full path these are DERIVED
  unions; in the single-delivery lite work they become directly AUTHORED (no union needed).
- (ii) Put the gate grade in a `PLAN.md` block — weaker: `PLAN.md` is a rev-tracked product doc,
  not a state file; the readers key on `STATE.md` (`pipeline-contracts.md` "Artifact files alone
  are not trackable"). Not recommended.
- (iii) Push everything down to task `STATE.md` — cannot express a delivery-level gate grade
  (the template comment forbids treating lifecycle as a task rollup).

**git branch:** with no `delivery-NNN`, the `aid/{work}-delivery-NNN` derivation
(`aid-execute § Check 5`) has no `NNN`. Either synthesize `NNN=001` (branch
`aid/{work}-delivery-001`, minimal reader/executor change) or adopt a work-level branch
`aid/{work}`. LIKELY the executor already tolerates single-delivery graphs — `state-delivery-gate.md
§ Step 1` and `compute-block-radius.sh`/`complexity-score.sh` (grep `lite/recipe SPEC`) already
special-case "a single top-level graph, no delivery wrapper."

### Residual human decision

> **Decision:** In the flattened layout, do the delivery-scoped AUTHORED fields (lifecycle State,
> gate grade/tier/issues, delivery Cross-phase Q&A) live in the work-root `STATE.md`, and what is
> the git-branch name with no `delivery-NNN`?
>
> **Tech-lead recommendation:** **Option (i)** — author `## Delivery Lifecycle` + `## Delivery
> Gate` sections directly in the work-root `STATE.md` for single-delivery lite works (they mirror
> the delivery-template sections verbatim, so `grade.sh` / `writeback-state.sh` / both reader
> twins parse the identical enum strings — no byte-stability break, satisfying `artifact-schemas.md
> § Contracts`). For the branch, **synthesize `delivery-001`** (`aid/{work}-delivery-001`) so
> `aid-execute § Check 5`'s branch derivation and the execution-graph resolver need only the
> already-present "single top-level graph" path, not a new branch scheme. The reader/executor
> adjustment this implies is AC-8 / FR-9 work and belongs to feature-001.

---

## Q-A9 — aid-deploy / aid-monitor re-purpose

### Code answer (facts + citations)

**aid-deploy.** State machine `IDLE → SELECTING → VERIFYING → PACKAGING → DONE`
(`canonical/skills/aid-deploy/SKILL.md` frontmatter `State machine:`). Lifecycle position:
**post-Execute, optional Deliver group** (`pipeline-contracts.md § Phase Input/Output Contracts`
lists it under off-pipeline/optional; `capability-inventory.md § Pipeline skills` "Ship a
release"). It **consumes an existing finished work** — it selects *completed deliveries*,
verifies the combined build, and writes `package-NNN-*.md` + the `## Deploy State` work-STATE
block (`aid-deploy/SKILL.md § Workspace`). Executor `aid-operator`.

**aid-monitor.** State machine `OBSERVE → CLASSIFY → ROUTE → DONE`
(`canonical/skills/aid-monitor/SKILL.md` frontmatter). Lifecycle position: **post-deployment,
optional Deliver group**. It observes telemetry, classifies findings, and **routes back into the
pipeline**. Executor `aid-orchestrator`.

**Critical coupling with the cutover (LIKELY blast-radius surprise).** `aid-monitor`'s routing
targets are written *directly against `aid-describe`'s lite/triage*, which FR-12 removes:
`aid-monitor/SKILL.md § Agents Involved` — "BUG classification → re-enters at `aid-describe`
(lite bug-fix triage)"; "Change Request → re-enters at `aid-describe` as new/changed
requirements." The KB feedback loops L9/L10 encode the same (`pipeline-contracts.md § Feedback
Loop Contracts`: "L9 Monitor→Describe (bug)… LITE-BUG-FIX"). So NFR-7 ("re-purposing
aid-deploy/aid-monitor must keep their current role working") **cannot be satisfied by
aid-monitor alone**: once `aid-describe` is full-only, aid-monitor's BUG route must re-point to
`aid-fix` (the new bug shortcut) and its CR route to `/aid-triage` or `/aid-describe`. This is a
cutover dependency A-9 shares with features 013/014, not an isolated re-purpose. CONFIRMED.

**Lifecycle mismatch (the actual A-9 tension).** The shortcut-entry model (feature-003) is a
**pre-Execute** operation: invoke → scaffold a flattened lite work (Describe→Detail) → stop for
approval. But aid-deploy and aid-monitor's current jobs are **post-Execute** (deploy consumes a
finished work; monitor observes a live deployment). "Add a Lite-path shortcut entry" therefore
means bolting a *second, opposite-lifecycle* entry onto each skill:
- `aid-deploy` shortcut = "I want to ship an artifact" → scaffold a G9 lite work; distinct from
  "package these already-Done deliveries."
- `aid-monitor` shortcut = "I want to set up observing a live asset" → scaffold a G10 lite work;
  distinct from "observe + classify + route an existing deployment."
The two skills would each carry two roles with near-opposite inputs. Priority is **Could**
(REQUIREMENTS § 10), i.e. the lowest-stakes family.

### Residual human decision

> **Decision:** How do aid-deploy/aid-monitor host BOTH a post-Execute pipeline role and a
> pre-Execute shortcut-scaffold role — dual-entry inside one skill (branch on invocation
> context), or keep the pipeline skill intact and add the shortcut behavior as a distinct
> mode? And where is aid-monitor's `aid-describe`-lite routing re-pointed after FR-12?
>
> **Tech-lead recommendation:** (1) **Re-point aid-monitor's routing as part of the cutover, not
> A-9:** BUG → `/aid-fix`, Change Request → `/aid-triage` (or `/aid-describe` full). Fix L9/L10 in
> `pipeline-contracts.md` + `aid-monitor/references/state-route.md` in lockstep — this is
> mandatory regardless of the "Could" shortcut and should be tracked under features 013/014.
> (2) **For the shortcut entry, add a thin mode-branch** at the top of each skill: no `work-NNN`
> arg + a free-form description ⇒ shortcut-scaffold path (delegate to the shared engine);
> `work-NNN` arg present ⇒ existing pipeline path (unchanged). This preserves NFR-7/C-6 (pipeline
> role byte-preserved) while satisfying the Could-priority shortcut. Because it is Could, it may
> be deferred to a later delivery without blocking the Must cohort.

---

## Q-cutover — Lite / triage / recipe blast radius (features 002/013/014)

### Code answer — everything below CONFIRMED on disk

**aid-describe TRIAGE + lite states exist (to remove per FR-12).** State machine in
`canonical/skills/aid-describe/SKILL.md` frontmatter: `... -> TRIAGE -> {full: ... | lite:
CONDENSED-INTAKE -> TASK-BREAKDOWN -> LITE-REVIEW -> LITE-DONE}`. Backing reference files under
`canonical/skills/aid-describe/references/`: `state-triage.md`, `state-condensed-intake.md`,
`state-task-breakdown.md`, `state-lite-review.md`, `state-lite-done.md`,
`recipe-to-lite-escalation.md`, `lite-to-full-escalation.md` (plus recipe mentions in
`elicitation-engine.md`, `move-playbook.md`). The **full-path engine to PRESERVE** (C-3) is a
disjoint set: `elicitation-engine.md`, `move-playbook.md`, `calibration.md`, `advisor-stance.md`,
`coherence-check.md`, `state-first-run.md`, `state-q-and-a.md`, `state-continue.md`,
`state-completion.md`, `state-describe-seed.md`.

**parse-recipe.sh + its tests exist (to retire per FR-14/C-4).**
- `canonical/aid/scripts/interview/parse-recipe.sh` (the parser; 69 internal `recipe` refs).
- `tests/canonical/test-parse-recipe.sh` (its harness — grep `SCRIPT=.*parse-recipe.sh`).
- Registered in `tests/README.md` (grep `test-parse-recipe.sh`) — must be de-registered.

**Recipe dir exists (to delete per FR-14).** `canonical/aid/recipes/` = **51 files** (the KB's
"52" in `architecture.md § Doc-vs-Code Discrepancies` / "51" in docs is stale drift; on-disk
count is 51). Deletion flows through the pure-mirror-deletion boundary automatically
(`EMISSION-MANIFEST.md`; render table entry `canonical/aid/recipes/ → recipes/`), satisfying C-4
— no manual profile edits.

**Full reference map — what else touches recipes / LITE- (the true blast radius):**
| Surface | Path (durable anchor) | Action per FR-12/13/14 |
|---|---|---|
| Recipe catalog | `canonical/aid/recipes/*` (51) | delete |
| Recipe parser | `canonical/aid/scripts/interview/parse-recipe.sh` | retire |
| Recipe parser test | `tests/canonical/test-parse-recipe.sh` | retire |
| Test registry | `tests/README.md` (grep `test-parse-recipe`) | de-register |
| Recipe authoring template | `canonical/aid/templates/recipe-template.md` | retire |
| Isolation-test fixtures | `tests/canonical/test-multitool-isolation.sh` (grep `aid/recipes/`) | re-point to a surviving passthrough asset |
| Install smoke check | `tests/canonical/test-install.sh` (grep `recipes/scripts/templates`) | still passes (scripts/templates remain); update comment |
| aid-describe lite/triage refs | the 7 reference files listed above | remove with FR-12 |
| Work-state template orphans | `canonical/aid/templates/work-state-template.md` `## Triage` block (`Recipe:` field, `Path`/`Work Type`/`Sub-path: LITE-*`/`Override`) + `## Escalation Carry` | remove/update per AC-5 |
| Lite work-root SPEC template | `canonical/aid/templates/specs/lite-spec-template.md` (grep `LITE-`) | superseded by feature-001 flattened layout |
| Execute-graph parsers | `canonical/aid/scripts/execute/compute-block-radius.sh`, `complexity-score.sh` (grep `lite/recipe SPEC`, `flat recipe form (- Type:)`) | NOT a delete target — they parse the *task-spec shape* recipes emitted; feature-001 must ensure the flattened work emits a shape these still parse (or update them) |
| Docs (tech-writer follow-up) | `docs/aid-methodology.md`, `docs/glossary.md`, `docs/faq.md`, `docs/install.md`, `docs/repository-structure.md`, `docs/diagram-content-reference.md` | recipe/"51 recipes" prose to update — out of `/aid-specify` code scope |

**TRIAGE→aid-triage extraction reality (FR-13).** `state-triage.md` today does two things: (i)
infer `workType` + path (full vs lite) via the elicitation engine, then (ii) match a *recipe*.
For `/aid-triage`, step (i) is reusable; step (ii) is replaced by suggesting a *shortcut name*
(verb+artifact) instead of a recipe. So FR-13 is a genuine extraction-plus-rewrite, not a pure
copy — the recipe-match half has no target once recipes are gone. LIKELY the reflect-back turn
(`state-triage.md` grep `reflect-back` / `Looks like a {inferred-type}`) is the reusable core.

### Residual human decision

> **Decision:** Two decisions the code does not settle: (a) does the flattened lite work emit the
> **bold `**Type:**`** task-spec shape (from `task-spec-template.md`) or the **flat `- Type:`**
> recipe shape (which `complexity-score.sh` grep `flat recipe form` still parses)? (b) Does
> `/aid-triage` suggest only a *single* best shortcut, or a ranked shortlist + a "use
> `/aid-describe` full" fallback?
>
> **Tech-lead recommendation:** (a) **Emit the bold `**Type:**` `task-spec-template.md` shape** —
> it is the canonical Detail-phase output the executor's primary parser expects; retiring recipes
> means retiring their flat form, so standardize on one shape and (optionally) simplify the
> `complexity-score.sh` flat-form branch in the same delivery. (b) Mirror the existing reflect-back
> UX: propose the **single best-match shortcut** with a numbered menu (`[1] proceed  [2] a
> different shortcut  [3] full path via /aid-describe`), reusing `state-triage.md`'s proven turn
> shape — a shortlist only when confidence is "several plausible."

---

## Synthesis — code-settled vs. needs-user (one line each)

- **A-2 (topology):** *Code-settled:* invocation name == directory, no alias facility ⇒ **69
  skill dirs are mandatory** and shared logic **can** centralize under `canonical/aid/`. *Needs
  user:* how thin each `SKILL.md` is / where the engine lives. **Recommend:** one shared
  `shortcut-engine` under `canonical/aid/` + 69 thin dirs emitted from a `catalog.yml` by a build
  helper (option b).
- **A-6 (task types):** *Code-settled:* the 8-type enum already covers non-code work and the gate
  is KB-command-driven "IF CONFIGURED", not code-hardcoded ⇒ **no new types, no
  pipeline-contract change**. *Needs user:* only the per-verb default-type mapping.
  **Recommend:** prototype→DESIGN, experiment→RESEARCH, report→RESEARCH, show-dashboard→IMPLEMENT;
  do NOT extend the enum.
- **A-7 (gates vs. speed):** *Code-settled:* batched multi-artifact review is already how the
  delivery gate works ⇒ fewer dispatches is mechanically supported. *Needs user:* dispatch
  granularity. **Recommend:** batch REQUIREMENTS+SPEC+PLAN into one review pass and the task
  SPECs into a second (2 vs 4+), gates fully preserved.
- **A-8 (delivery-scoped state):** *Code-settled:* single-delivery = single-writer, so the
  disjoint-write rule that forced a separate `delivery-NNN/STATE.md` no longer applies; enum
  strings must stay byte-identical for the readers. *Needs user:* which file holds the fields +
  branch name. **Recommend:** author `## Delivery Lifecycle` + `## Delivery Gate` verbatim in the
  work-root `STATE.md`; synthesize `delivery-001` for the branch (`aid/{work}-delivery-001`).
- **A-9 (deploy/monitor):** *Code-settled:* both are post-Execute optional skills; aid-monitor's
  routing is hardwired to `aid-describe`-lite, which FR-12 removes. *Needs user:* dual-role
  hosting + re-routing target. **Recommend:** re-point aid-monitor (BUG→`/aid-fix`,
  CR→`/aid-triage`) as **cutover work (features 013/014), not A-9**; add the shortcut as a thin
  invocation-context mode-branch; may be deferred (Could priority).
- **Cutover (002/013/014):** *Code-settled (all CONFIRMED on disk):* the delete/retire set is
  enumerated above — 51 recipe files, `parse-recipe.sh` + its test + `tests/README.md` entry,
  `recipe-template.md`, 7 aid-describe lite/triage reference files, the work-state `## Triage`/
  `## Escalation Carry` blocks, and the `lite-spec-template.md`; deletion auto-mirrors via the
  emission manifest. *Needs user:* the emitted task-spec shape (recommend the bold `**Type:**`
  `task-spec-template.md` form) and the `/aid-triage` suggestion breadth (recommend single
  best-match + full-path fallback, reusing the existing reflect-back turn). **Watch-outs for
  `/aid-specify`:** `test-multitool-isolation.sh` recipe fixtures must be re-pointed;
  `compute-block-radius.sh`/`complexity-score.sh` parse the recipe SPEC shape (align feature-001's
  output with them); aid-monitor L9/L10 routing is a hidden cutover dependency; docs prose ("51
  recipes") is a separate tech-writer follow-up.
