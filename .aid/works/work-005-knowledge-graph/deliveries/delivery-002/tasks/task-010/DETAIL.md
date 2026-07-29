# task-010: Site skill-catalogue roster pair

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

**Type:** IMPLEMENT

**Source:** work-005-knowledge-graph -> delivery-002

**Depends on:** task-007

**Scope:**

- Two edits that are **one inseparable change** (feature-012 D1 Class C, M3):
  1. `site/scripts/gen-reference.mjs` — add `{ name: 'aid-graph', phase: '…' }` to the
     **Knowledge Base Maintenance** group of `SKILL_GROUPS`, beside `aid-summarize`.
  2. `site/scripts/__tests__/gen-reference.test.mjs` — add `'aid-graph'` to
     `CURATED_SKILL_NAMES`, moving it **21 -> 22** (21 verified on the branch).
- They cannot be split. `generateSkillsPage()` computes `expected = curatedNames ∪ allCatalogNames`
  and throws `[gen-reference] skills drift` when that set differs from `onDisk`, so landing the test
  mirror alone breaks the generator; and `expect(sections).toHaveLength(CURATED_SKILL_NAMES.length)`
  compares the rendered `### \`aid-…\`` section count against the hand-mirrored roster, so landing
  the generator entry alone breaks the suite. Both are hard failures, which is exactly why the pair
  is one task.
- Regenerate the site reference and run its suite:
  `cd site && node scripts/gen-reference.mjs && npm test`.
- Depends on task-007 because the identity is checked against `onDisk` — the
  `canonical/skills/aid-graph/` directory must exist before the generator can agree with the roster.
- **Out of scope: every comment in `gen-reference.mjs`.** The stale header comment
  ("94 skill directories (16 classic + … + 76 catalog-driven shortcuts)") and the stale comment above
  `SKILL_GROUPS` ("16 classic skills") are task-011's, which re-anchors them to a derived identity
  rather than bumping them. This task changes a roster entry and nothing else.
- **Out of scope:** the eleven `${SKILLS}` documentation surfaces (task-012); the
  `generate-profile` VALIDATE claims (task-011).
- Note on canonical-first: `site/` is not a rendered tree and neither file has a `canonical/`
  original, so editing them in place is correct.

**Acceptance Criteria:**

- [ ] `SKILL_GROUPS`'s **Knowledge Base Maintenance** group contains an `aid-graph` entry with a
      `phase` string, placed beside `aid-summarize`.
- [ ] `CURATED_SKILL_NAMES` in `site/scripts/__tests__/gen-reference.test.mjs` contains `'aid-graph'`
      and holds 22 names (21 before, verified on the branch).
- [ ] `cd site && node scripts/gen-reference.mjs` completes without throwing
      `[gen-reference] skills drift`.
- [ ] `cd site && npm test` passes, including
      `expect(sections).toHaveLength(CURATED_SKILL_NAMES.length)` at 22 rendered
      `### \`aid-…\`` sections.
- [ ] The regenerated `site/src/content/docs/reference/skills.md` gains an `aid-graph` section, and
      its intro count moves to 112 **without any literal being edited** — the number comes from
      `onDisk.length` (feature-012 D1 Class A).
- [ ] No comment anywhere in `site/scripts/gen-reference.mjs` is changed by this task
      (`git diff` shows only the `SKILL_GROUPS` array entry).
- [ ] No new hardcoded total is introduced by either edit; the change is a roster name, and both
      guards that consume it are set comparisons (feature-012's derived-count criterion;
      tech-debt L4 measure 2).
- [ ] All existing canonical suites still pass. IMPLEMENT's "unit tests for all new public methods"
      default is **overridden**: feature-012 L3 states this feature introduces no new suite because
      its proof is existing machinery, and the existing `site` suite fires hard on either half of the
      pair being missing — no separate TEST task is warranted or created.
- [ ] The delivery gate's `grade.sh` run over `.aid/.temp/review-pending/` reaches this repository's
      resolved `review.minimum_grade` of **A+** (`.aid/knowledge/quality-gates.md`;
      `.aid/knowledge/coding-standards.md` § JavaScript / Node Conventions for the two files' style)
      — zero findings with Status `Pending` or `Recurred`. REQUIREMENTS.md §6 is not a code baseline;
      it holds only the six accessibility NFRs.
