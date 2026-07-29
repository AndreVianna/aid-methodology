# task-001: Relation-instance evidence base and screened candidate pair set

> **Execution protocol (binding on whoever executes this task -- no
> exceptions):** the moment this task's `State` changes, write it --
> `In Progress` before starting work, `In Review` before dispatching the
> reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally
> whether the main/orchestrator agent executes this task directly or
> dispatches it to a sub-agent; neither may skip, batch, or defer these
> writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- it is never
> self-written by the task being executed.) Full mandate:
> `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** RESEARCH

**Source:** work-005-knowledge-graph -> delivery-001

**Depends on:** -- (none)

**Scope:**
- Execute feature-001's Feature Flow **Steps 1-4** and write the findings to
  `.aid/works/work-005-knowledge-graph/deliveries/delivery-001/research/relation-vocabulary-evidence.md`.
  That path is this task's RESEARCH output path per `task-type-rules.md` § RESEARCH ("Write findings
  to the path specified in task Scope").
- **Step 1 -- fix the frame.** Read REQUIREMENTS.md §5.1 (the three relationship sources), §5.2 (the
  eight-column table), §5.3 (the three id prefixes), §5.4 (FR-4-FR-6) and §5.8 (which pass may emit
  what). Then `.aid/knowledge/artifact-schemas.md`, `.aid/knowledge/authoring-conventions.md`
  § "Frontmatter Rules", and `.aid/knowledge/domain-glossary.md` so no relation name collides with a
  Concept Spine term.
- **Step 2 -- harvest real relationship instances.** Re-verify on disk each of the ten evidence
  carriers named in feature-001's Step 2 table: KB frontmatter `see_also:`, `sources:` and `tags:`
  concern ids; inline `CONFIRMED <path> (search: "...")` citations; the
  `canonical/aid/templates/generated-files.txt` registry lines; the `src`/`dst` records in
  `profiles/<tool>/emission-manifest.jsonl`; a script reading a data file
  (`canonical/aid/scripts/kb/harvest-coined-terms.sh` -> `coined-term-denylist.txt`); a script
  invoking scripts (`tests/run-all.sh` globbing `tests/canonical/test-*.sh`); the five-manifest
  install lockstep set from `.aid/knowledge/infrastructure.md` § "Install Bootstrap and Manifests";
  and `.aid/knowledge/external-sources.md` § "Sources". Build the evidence base *before* naming
  anything.
- **Step 3 -- cluster and name.** Group the harvested instances, choose the category axis under
  feature-001 § Data Model § The category set constraints, and name each cluster's pair in the fixed
  lexical form (lowercase, hyphen-separated, active-voice verb phrase). Naming is per-pair, never
  per-direction -- a relation is never proposed without its inverse in the same entry.
- **Step 4 -- screen candidates.** Admit a proposed type only if **both** hold: (1) it traces to a
  Step-2 harvested instance or to a §5.1 source class this repository cannot instance (the `ext:`
  case); and (2) no already-admitted type's `definition` covers the same assertion -- where two
  candidates overlap, merge them or sharpen both definitions until an author cannot reasonably pick
  either.
- **This task writes no product code.** Per `task-type-rules.md` § RESEARCH and delivery-001's gate
  criterion, it changes nothing under `canonical/`, `profiles/`, `tests/` or `.aid/knowledge/`. Its
  sole output is the report in the transient work folder. The one exception in this delivery is
  task-002, which authors `canonical/aid/templates/graph/relation-vocabulary.yml`; that exception
  does not extend to this task.
- Out of scope: authoring the vocabulary file, the property self-test and the three worked rows
  (task-002); the shipped loader `rel_load_vocabulary` (task-015); the `V3`/`V4`/`V12` validators
  (task-016); selecting and enumerating the `coverage_bearing` subset (task-045).

**Acceptance Criteria:**
- [ ] The report exists at `.../deliveries/delivery-001/research/relation-vocabulary-evidence.md` and
      records all ten Step-2 evidence carriers, each with the on-disk location it was re-verified at.
- [ ] The `ext:` row is recorded with its limitation stated: `.aid/knowledge/external-sources.md` has
      zero registered entries, so the `ext:` class is fitted against the Q4 self-built synthetic
      fixture (A-6) and not against this repository.
- [ ] At least two category axes are compared -- §5.1's relationship-source axis and the
      relation-nature axis (structural containment, dependency/invocation, generation/derivation,
      documentation/evidence, mutual-obligation), or a blend -- and the chosen axis is named.
- [ ] The chosen axis is justified against all three § Data Model category constraints: total and
      single-valued, each category carrying a one-line meaning, and small enough that grouping by
      category is a *reduction* for FR-13's Overview lens rather than a relabelling.
- [ ] Whether a documentation/evidence-shaped category is proposed is stated explicitly with its
      reason, because feature-006 D2 may adopt such a category as `coverage_bearing` outright.
      Selecting that subset remains task-045's, and the report says so rather than pre-empting it.
- [ ] Every candidate pair is recorded with both directions named in the same entry, and with the
      harvested instance -- or the named §5.1 class -- it traces to. No candidate is admitted on
      speculation alone.
- [ ] The symmetric candidate is identified: the five-manifest install lockstep set is a mutual
      obligation with no natural direction, and the report states whether it is admitted as a
      `symmetry: symmetric` entry (`relation == inverse`) and why.
- [ ] Screen part 2 is evidenced: for every pair of candidates judged close in meaning, the report
      records either the merge performed or the sharpened definitions that make them
      non-interchangeable.
- [ ] No proposed relation name collides with a `.aid/knowledge/domain-glossary.md` Concept Spine
      term; the check is recorded with the terms compared.
- [ ] Sources cited (RESEARCH default): every claim carries the repository path or KB section it was
      read from, so a reviewer can re-run the check.
- [ ] Trade-offs documented explicitly (RESEARCH default), including the FR-5 tension --
      comprehensiveness beats brevity for *adding*, but the bar against a duplicate-meaning type is
      absolute.
- [ ] Actionable recommendation (RESEARCH default): task-002 can author `relation-vocabulary.yml`
      from this report without re-deriving the pair set, the category set, or the screen.
- [ ] `git status --porcelain` shows no change outside
      `.aid/works/work-005-knowledge-graph/` -- delivery-001's gate asserts that neither research
      feature changed product code, wrote to the Knowledge Base, or committed a spike harness.
- [ ] Quality gate: this task's reviewer ledger grades **A+** under `grade.sh` -- the resolved
      `review.minimum_grade` (`.aid/settings.yml`, and this work's `STATE.md` `minimum_grade: "A+"`)
      -- i.e. zero rows with Status `Pending` or `Recurred`. The code baseline is
      `.aid/knowledge/coding-standards.md` and the gate is `.aid/knowledge/quality-gates.md`;
      REQUIREMENTS.md §6 holds only the six accessibility NFRs and is **not** a code or lint baseline.
