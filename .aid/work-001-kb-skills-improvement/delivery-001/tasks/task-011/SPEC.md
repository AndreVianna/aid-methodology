# task-011: GENERATE/closure wiring -- Step 0e + Step 5b + state-closure.md + agent prompts

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-001

**Depends on:** task-006, task-008, task-010

**Scope:**
- Edit `canonical/skills/aid-discover/references/state-generate.md`:
  - Add **Step 0e** (run `harvest-coined-terms.sh` AFTER the project index / doc-set confirm,
    BEFORE the researcher fan-out; print the `[0e]` progress lines; degrade-gracefully to an empty
    list on empty-repo/no-git).
  - Add `.aid/generated/candidate-concepts.md` to the REFERENCE DOCUMENTS block under
    `.aid/generated/`, AND fix the latent `project-index.md` path drift in that block (it must read
    `.aid/generated/project-index.md`, not `.aid/knowledge/`).
  - Add **Step 5b (SYNTHESIS + CLOSURE)** after the deep dives, chaining to the new closure reference;
    route ungroundable terms into `.aid/knowledge/.scout-questions.tmp` (Step 6b unchanged).
- Author the new `canonical/skills/aid-discover/references/state-closure.md` (thin-router pattern):
  the loop body SYNTHESIZE (the conceptual-synthesis channel `[cited-span-or-reject]`, merging
  `synthesis`-tagged rows into `candidate-concepts.md`) -> EXPLAIN -> DETECT (`closure-check.sh`
  output (a) is the termination oracle) -> INVESTIGATE (batched-parallel grounding sub-agents) ->
  REPEAT until CLOSED or the cap trips.
  - **`spine-todo.md` "to ground" seed-checklist (f004 SPEC L486-499, the "no candidate silently
    dropped" guarantee).** state-closure.md must also author the seed-checklist mechanism: after
    Step 0e, SEED a transient `.aid/generated/spine-todo.md` derived 1:1 from
    `candidate-concepts.md` (EVERY candidate -- both `harvest` and `synthesis` rows), so each
    candidate is a row the loop MUST drive to a terminal state -- either (a) GROUNDED into a
    concept entry in the spine (`domain-glossary.md`) with definition-as-used-here, relates-to,
    and `sources:`, or (b) explicitly DISMISSED as not-a-concept (generated-identifier dump,
    vendored token) with a one-line reason. No candidate is silently dropped. New native terms
    discovered DURING grounding (understanding is recursive, f004 SS1.4) are appended to the
    spine and re-fed into `spine-todo.md`, which is the work-list the loop iterates on. This is
    DISTINCT from `closure-check.sh` output (a): output (a) is the used-but-undefined termination
    oracle (fires on terms USED in a doc), whereas the `spine-todo.md` seed-list enumerates ALL
    harvested+synthesis candidates whether or not they are yet used anywhere. Define/own the per-run cap-override argument interface
  (`--max-clean-passes N --max-rounds N --token-budget N`) reading defaults from the
  `discovery.closure` settings block (NOT via `read-setting.sh`, which is 2-level only); on cap-trip
  before CLOSED, escalate remaining ungrounded terms as Step-6b human Q&A (FR-32).
- Edit `canonical/skills/aid-discover/references/agent-prompts.md`: add the spine-grounding +
  can't-explain tripwire mandate to the Integrator + all four deep-dive prompts; add a Grounding
  prompt section for the closure sub-agents; add the conceptual-synthesis mandate to `aid-architect`
  (propose tokenless load-bearing concepts, each with a MANDATORY cited source span; uncited ->
  reject). No new script.
- Edit canonical only; re-run `run_generator.py`; commit regenerated `profiles/`.

**Acceptance Criteria:**
- [ ] `state-generate.md` has Step 0e (harvest before fan-out, degrade-graceful) and Step 5b
  (SYNTHESIS + CLOSURE chaining to `state-closure.md`); ungroundable terms route to
  `.scout-questions.tmp` with Step 6b unchanged.
- [ ] The REFERENCE DOCUMENTS block lists `.aid/generated/candidate-concepts.md` and the
  `project-index.md` path is corrected to `.aid/generated/project-index.md`.
- [ ] `state-closure.md` implements SYNTHESIZE (cited-span-or-reject) -> EXPLAIN -> DETECT (output
  (a) termination) -> INVESTIGATE (batched-parallel) -> REPEAT, with the cap-override argument
  interface reading `discovery.closure` defaults and the FR-32 cap-trip escalation.
- [ ] `agent-prompts.md` carries the spine-grounding + tripwire mandate on the Integrator + all four
  deep-dive prompts, a Grounding prompt section, and the `aid-architect` conceptual-synthesis mandate
  (cited-span-or-reject).
- [ ] `state-closure.md` SEEDS a transient `.aid/generated/spine-todo.md` 1:1 from
  `candidate-concepts.md` (every `harvest` AND `synthesis` candidate enumerated) and drives each
  to a terminal state -- GROUNDED into a spine concept entry OR DISMISSED-with-one-line-reason --
  with the "no candidate silently dropped" guarantee, and re-feeds native terms discovered during
  grounding back into the checklist (f004 SPEC L486-499). This seed-list grounding is distinct
  from output (a)'s used-but-undefined detection.
- [ ] No new script is added (wiring only); the loop's DETECT consumes `closure-check.sh` output (a).
- [ ] `run_generator.py` re-run; regenerated `profiles/` committed (render-drift green).
- [ ] All section-6 quality gates pass.
