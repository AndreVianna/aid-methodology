# task-091: `test-graph-skill-registration.sh` GR01-GR06

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

**Type:** TEST

**Source:** work-005-knowledge-graph -> delivery-006

**Depends on:** task-086

**Scope:**
- Author `tests/canonical/test-graph-skill-registration.sh` (feature-013 § L1), discovered by the
  `tests/canonical/test-*.sh` glob with **no edit to `tests/run-all.sh`** -- a stated contract of
  the runner. It sources `tests/lib/assert.sh` and uses the `ID + description` assertion-label
  convention of `tests/canonical/test-guardrails-d012.sh`.
- **This suite asserts the tree, not a fixture.** It reads `canonical/` and `profiles/` directly
  rather than building a `mktemp -d` fixture, because the thing under test *is* the rendered
  repository -- a fixture could not observe a missed render. It is deliberately free of any
  `.aid/works/` path, so it satisfies A-6 and keeps working after the work folder is pruned.
- **Every assertion compares each tree to the canonical source, never to a sibling tree.** That is
  tech-debt **L4**'s invariant-anchoring rule and the exact mistake the `io_bounds.py` incident
  was made of: five install manifests plus two installer-test lists all asserted each other and
  passed while every one of them was stale.
- The six assertions:
  - **`GR01`** -- `canonical/skills/aid-graph/SKILL.md` exists and carries all four required
    frontmatter keys: `name`, `description`, `allowed-tools`, `argument-hint`.
  - **`GR02`** -- every one of the five `profiles/<tool>/emission-manifest.jsonl` files contains a
    record whose `dst` ends `skills/aid-graph/SKILL.md`. This is the assertion that would have
    caught L4's bug class, because it compares the manifests to the canonical source of truth
    rather than to each other.
  - **`GR03`** -- the corresponding file exists in each `profiles/<tool>/` tree.
  - **`GR04`** -- `.claude/skills/aid-graph/SKILL.md` exists (dogfood parity).
  - **`GR05`** -- each rendered tree contains both `aid/scripts/graph/coverage-predicate.mjs` and
    `aid/scripts/graph/detect-kb-gaps.mjs`;
    `node --input-type=module -e "import('<tree>/aid/scripts/graph/coverage-predicate.mjs')"`
    resolves with **no `package.json` anywhere above it** in that tree; and the rendered
    `coverage-predicate.mjs` is **byte-identical** to the canonical one -- proving the shared
    predicate is importable where the rendered detector runs and that the render's text transforms
    found nothing to rewrite in it.
  - **`GR06`** -- every `references/state-*.md` file present canonically is present in each
    rendered tree, as a **set** comparison rather than a count, so adding a state file later
    cannot leave the assertion trivially true.
- **Out of scope:** the coverage census and the generated-catalogue read-back (task-092); the full
  canonical-suite run (task-096); the render itself (task-086); and any documentation surface
  (task-090).

**Acceptance Criteria:**
- [ ] Tests are deterministic: the suite reads the repository as it stands and produces the same
      result on every run.
- [ ] Clean setup and teardown: the suite creates no state and leaves no temporary artifact
      behind.
- [ ] All six assertions `GR01` through `GR06` are present, each labelled with its id and
      description per the `test-guardrails-d012.sh` convention.
- [ ] Every assertion's comparison basis is the **canonical source**, not another rendered tree --
      reviewable by reading each assertion in turn.
- [ ] `GR05` asserts all three of its parts: both `.mjs` files present in each tree, the bare
      import resolving with no `package.json` above it, and byte identity between the rendered and
      canonical `coverage-predicate.mjs`.
- [ ] `GR06` is a set comparison over `references/state-*.md`, not a count.
- [ ] The suite contains no `.aid/works/` path and requires no edit to `tests/run-all.sh`.
- [ ] `bash tests/canonical/test-graph-skill-registration.sh` passes on the branch after
      task-086's render.
- [ ] All acceptance criteria from feature-013's registration criterion are covered by this suite.
- [ ] `tests/coverage-parity.sh` records a net addition of executed assertions, never a removal.
- [ ] The reviewer ledger for this task carries no finding with Status `Pending` or `Recurred`, so
      the delivery gate's `grade.sh` run over `.aid/.temp/review-pending/` reaches this
      repository's resolved `A+` (`review.minimum_grade`; `.aid/knowledge/quality-gates.md`
      § Minimum-Grade Thresholds).
