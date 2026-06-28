# task-025: Seed-authoring state (aid-describe step) -- 5-element model + domain-adaptive shape + gate wiring

**Type:** IMPLEMENT

**Source:** work-001-aid-interview-improvements -> delivery-004

**Depends on:** task-020, task-023, task-024

**Scope:**
- Add the new additive seed-authoring state to the existing `canonical/skills/aid-interview/` skill (C-2
  extend-don't-fork; the `aid-describe` step per D3, executed today by `aid-interview`). It runs AFTER the
  engine (delivery-003) has gathered enough intent and BEFORE `REQUIREMENTS.md` is approved (flow steps
  3-6). Create the state reference doc (e.g. `references/state-describe-seed.md`) and wire it into the
  spine (the `SKILL.md` State Detection / dispatch path and/or the post-elicitation hand-off point) so the
  forward-authoring path routes to it; keep the existing brownfield/lite path byte-unchanged (NFR-2 / AC-10).
- **Step 3 -- materialize the seed (the 5-element model, Data Model table):** author the 4 core docs +
  conditional `decisions.md`, each to its existing KB doc / concern / `kb-category`, each meeting its
  per-element fit criterion:
  1. concept-spine -> `domain-glossary.md` (C4, primary, MANDATORY): every load-bearing term defined as
     THIS project uses it, with relationships + `## Invariants` + a concrete example; C4 stopping bar.
  2. intended architecture -> `architecture.md` (C1, primary, MANDATORY): parts + boundaries +
     relationships + `## Invariants`, sketch altitude (not as-built).
  3. conventions & standards -> `coding-standards.md` (+ `authoring-conventions.md` for methodology
     projects) (C3, primary, DEFERRABLE): declared rules OR explicit "standard for `<stack>`, no
     project-specific deviations yet".
  4. technology stack -> `technology-stack.md` (C0, primary, DEFERRABLE): language/runtime/framework
     named; version MAY be "latest-at-init / TBD-until-scaffolded" and build "TBD".
  5. decisions & rationale -> `decisions.md` (D, extension, CONDITIONAL): present ONLY when
     rationale-bearing choices exist (propose->confirm); each states what + why + rejected alternative;
     not forced when empty.
- Stamp every seed doc with `source: forward-authored` + the full f001 frontmatter (`objective:`,
  `summary:`, `sources:` typically `[]` or the elicited-intent record -- never code, `tags:`, etc.).
- **Domain-adaptive shape (RQ-A4):** invariant core (elements 1-2 + concept-spine ALWAYS; 11-dimension
  spine fixed) + domain-selected extensions surfaced through the same propose->confirm gate aid-discover
  uses (process-heavy -> event/behavior content; data/ML -> intended `schemas.md`; integration-heavy ->
  intended integration-map; non-software -> `domain-doc-matrix.md`-rendered doc names). Adaptivity is in
  doc realization, never in the dimension list.
- **Exclusions (RQ-A2):** do NOT author `module-map.md`, `test-landscape.md`, `schemas.md` (unless
  domain-promoted), `infrastructure.md`, `feature-inventory.md`, `integration-map.md`/
  `pipeline-contracts.md` (unless domain-promoted), `project-structure.md`. The seed carries intent, not
  inventory.
- **Sequence (steps 4-5):** after materializing, INVOKE the coherence check (task-024) -- resolve any
  surfaced conflict [HUMAN GATE] before proceeding -- then invoke the review subsystem with
  `greenfield: true` (task-022/023 wiring) and loop back to step 3 on findings; sufficiency precondition =
  every kept element meets its fit criterion AND the structural cross-check yields zero requirement orphans.
- ASCII-only; targeted additive edits; the brownfield/lite spine behavior is preserved or strictly improved.
- **Out of scope:** the coherence-check doc internals (task-024); the gate expectations/wiring internals
  (task-022/023); the freshness/schema marker (task-019/020); render (task-026); the
  sufficiency/coherence/gate VERIFICATION (task-027).

**Acceptance Criteria:**
- [ ] A new seed-authoring state is added in `canonical/skills/aid-interview/` and wired into the spine so the greenfield forward-authoring path routes to it; the existing brownfield/lite path is byte-unchanged (verify via diff). *(C-2/D3, NFR-2/AC-10; gate criterion 5)*
- [ ] The state materializes the 4 core docs + conditional `decisions.md`, each to its KB doc / concern / `kb-category` with its per-element fit criterion, and stamps `source: forward-authored` + full f001 frontmatter (sources never code). *(FR-1, DoD D2; gate criterion 2/4)*
- [ ] The domain-adaptive shape (invariant core + propose->confirm domain extensions; 11-dimension spine fixed) and the RQ-A2 exclusions (as-built docs NOT authored) are encoded. *(RQ-A2/A4, NFR-4; gate criterion 4)*
- [ ] The state sequences materialize -> coherence check (task-024) [HUMAN GATE] -> greenfield-mode gate (`greenfield: true`, task-022/023) with loop-back on findings; the sufficiency precondition (kept-element fit criteria + zero requirement orphans) is stated. *(flow steps 3-5, RQ-A5; gate criterion 1/3)*
- [ ] ASCII-only; skill is prose-executed (no unit test; IMPLEMENT unit-test default overridden -- behavior is exercised end-to-end at task-027). All REQUIREMENTS.md §6 quality gates pass.
