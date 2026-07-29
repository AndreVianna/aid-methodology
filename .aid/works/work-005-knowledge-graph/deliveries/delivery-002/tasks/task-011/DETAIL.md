# task-011: Derived-identity re-anchoring of the two stale count-claim surfaces

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

**Depends on:** task-010

**Scope:**

- **M1 — `.claude/skills/generate-profile/SKILL.md`.** Two stale claims, both wrong today and both
  unguarded by any test:
  - VALIDATE step 1's "The full taxonomy is **92 skill directories**" plus its
    `ls canonical/skills/ | wc -l   # expect 92` command;
  - the completion-checklist line
    "92 skills (14 classic + aid-triage + aid-ask + 76 shortcuts, one per non-`repurpose` catalog row)".

  Replace both with the **set identity** `gen-reference.mjs` already enforces: the on-disk
  `canonical/skills/` directory set equals the curated skill names ∪ every
  `canonical/aid/templates/shortcut-catalog.yml` row name. A set comparison cannot go stale. The
  checklist line loses the `(14 classic + … + 76 shortcuts)` composition and cites the derived
  command instead.
- **M2 — `site/scripts/gen-reference.mjs` comments only.** The header comment
  "94 skill directories (16 classic + aid-triage + aid-ask + 76 catalog-driven shortcuts)" and the
  comment above `SKILL_GROUPS` reading "16 classic skills" (the array holds 22 after task-010).
  Re-anchor both to state the identity the file *enforces*, so the file that enforces the identity
  also describes it and the two cannot disagree. The code below both comments is already fully
  dynamic and is not touched.
- **Bumping is forbidden.** `92 -> 93` and `94 -> 95` would leave both surfaces wrong and would hide
  pre-existing drift inside this work's diff. The rule applied is tech-debt **L4** measure 2,
  *invariant-anchoring*: "every assertion must compare a derived artifact to the source of truth …
  never to a sibling copy that can drift in lockstep".
- **Why IMPLEMENT and not REFACTOR.** Replacing `expect 92` with a set-identity check changes what
  the assertion accepts and what it rejects — a tree with 92 directories now fails and a tree with
  112 now passes. That is a behaviour change, so REFACTOR's "all tests pass before AND after / no
  behaviour change" bar cannot be met and the type would be wrong.
- Canonical-first note: `.claude/skills/generate-profile/` is hand-authored maintainer tooling
  authored in place. There is no `canonical/skills/generate-profile/` (verified —
  `ls: cannot access`), and `.aid/knowledge/module-map.md` places the renderer at
  `.claude/skills/generate-profile/scripts/` explicitly. Editing it is not a rendered-copy edit.
- **Out of scope:** the `SKILL_GROUPS` array entry and the `CURATED_SKILL_NAMES` mirror (task-010);
  the eleven `${SKILLS}` needles (task-012); `docs/diagram-content-reference.md`'s roster-test
  sentence and its composition arithmetic — feature-012 finding **U7**, which belongs with
  feature-013's roster edits in task-090.

**Acceptance Criteria:**

- [ ] `.claude/skills/generate-profile/SKILL.md` contains no `92` count literal and no
      `14 classic` / `76 shortcuts` composition; its VALIDATE step 1 and its completion checklist
      each state the set identity and cite the derived command rather than a total.
- [ ] `site/scripts/gen-reference.mjs`'s header comment and the comment above `SKILL_GROUPS` contain
      no `94`, `76`, or `16 classic` count claim, and each states the identity the file enforces.
- [ ] A grep for count claims over the two files
      (`grep -nE '\b(92|94|76)\b|16 classic' .claude/skills/generate-profile/SKILL.md site/scripts/gen-reference.mjs`)
      returns no surviving count claim; any residual numeric hit is unrelated to the skill taxonomy
      and is named in review.
- [ ] Running `generate-profile`'s VALIDATE step against the live tree passes at **112** skill
      directories — M1's stated verification — and would also have passed at 111, because the check
      is now an identity rather than a total.
- [ ] `git diff` over `site/scripts/gen-reference.mjs` shows **comment-only** changes; no code path
      is altered (M2's verification is read-back, since no behavioural test applies to a comment).
- [ ] No new hardcoded total is introduced anywhere by this task — every replacement is a derived
      comparison (feature-012's derived-count acceptance criterion; tech-debt L4 measure 2).
- [ ] The type choice is recorded in review: IMPLEMENT rather than REFACTOR, because a set-identity
      assertion accepts and rejects different trees than `expect 92` did.
- [ ] `cd site && node scripts/gen-reference.mjs && npm test` still passes, and all existing
      canonical suites still pass.
- [ ] IMPLEMENT's "unit tests for all new public methods" default is **overridden**: feature-012 L3
      states this feature introduces no new suite, and both surfaces here are prose/comment claims
      whose proof is `test-doc-counts.sh` (task-012) and the existing `site` suite. No TEST task is
      paired with this one, deliberately.
- [ ] The delivery gate's `grade.sh` run over `.aid/.temp/review-pending/` reaches this repository's
      resolved `review.minimum_grade` of **A+** (`.aid/knowledge/quality-gates.md`) — zero findings
      with Status `Pending` or `Recurred`. REQUIREMENTS.md §6 is not a code baseline; it holds only
      the six accessibility NFRs.
