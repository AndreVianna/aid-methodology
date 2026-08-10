# task-053: Nine curated on-demand descriptions, including the only two at or over the cap

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-053/STATE.md.
Shape: 6 sections matching .claude/aid/templates/delivery-plans/task-template.md.

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

**Type:** DOCUMENT

**Source:** work-006-design-phase-skills -> delivery-003

**Depends on:** task-052

**Scope:**
- Source: REQUIREMENTS **AC-12**, whose check **1** names both of this slice's outliers explicitly.
  The five checks are cited, not restated.
- **Slice 2 of 7.** The **nine curated on-demand skills**: `aid-graph`, `aid-housekeep`,
  `aid-summarize`, `aid-update-kb`, `aid-set-connector`, `aid-unset-connector`, `aid-read-ticket`,
  `aid-create-ticket`, `aid-update-ticket`.
- **This slice holds the entire cap problem.** `aid-update-ticket` breaches the 1024-character hard
  cap outright and `aid-create-ticket` sits a handful of characters under it; `aid-read-ticket` is
  the third-longest of the three and shares their pattern -- a grammar line, a resolution ladder, a
  per-part behaviour table and a confirm-gate narrative all inside the description. It is **one fix
  applied three times**, not three unrelated edits: the grammar and the mechanics belong in the body
  (where each of the three already restates them), and the description keeps the outcome plus the
  trigger. Every figure here is re-measured at execution time rather than trusted from this file.
- **The one description-anchored assertion in the ticket suite, named so a shortening pass does not
  silently break it.** `tests/canonical/test-ticket-skills-structural.sh` runs 58 content
  assertions over the three files with `assert_wrapped_contains`/`assert_file_contains`, which match
  the **whole file**. Most read body text, but **T54** (`:209`) matches the literal
  ``closed enum `description | comment | status` `` and that exact substring occurs **only** in
  `aid-update-ticket`'s description (`SKILL.md:6`) -- the body's own statement at `:57` puts
  `**closed enum**` emphasis markers between the noun and the backtick, so it does not match. Either
  keep the literal in the description or introduce a matching form in the body; do not edit the
  suite. `T02`, `T08` and `T14` additionally require each of the three to keep a folded
  `description: >` scalar, so the shortening must not collapse it to a plain scalar.
- **`aid-graph`, `aid-housekeep` and `aid-update-kb` carry state-machine transition sequences.**
  Relocate each into the `SKILL.md` body rather than deleting it; the sequences are real contracts
  and `docs/glossary.md` quotes them. No suite pins these three the way
  `test-describe-full-only.sh` pins `aid-describe`, but relocation is used uniformly so the sweep
  has one rule rather than a per-skill judgement.
- **Relocating a state-machine line into a body has a downstream effect that is this delivery's, not
  a later one's.** `site/scripts/lib/flow-graph/extract-residual.mjs` rung R1 (`:222-234`) scans the
  **body** for a `^State machine:` line and, when it finds one, builds that skill's flow chart from
  it. These three bodies carry no such line today (`grep -c` returns `1` per file and the hit is in
  the frontmatter), so relocation will newly fire R1 and change
  `site/src/data/skill-flows/<name>.flow.json`. That is expected, and it is why the site
  regeneration (task-064) is a descendant of every slice rather than a sibling.
- **What a rewrite may not silently drop:** any neighbour name carried as a negative route under
  FR-11 **CC-9**. Compare each description's set of `/aid-` names before and after.
- Out of scope: `SKILL.md` body size, `argument-hint` placement and self-containment (REQUIREMENTS
  §4's AC-12 bullet); the other six slices; the site regeneration (task-064); and the whole-roster
  verification (task-072).

**Acceptance Criteria:**
- [ ] **AC-12 check 1 -- every one of the nine is within budget, and the two outliers are named in
      the record with their before and after lengths.** The extracted `description:` block is
      **<= 1024** characters for all nine, measured with the same extraction the reviewer can re-run,
      and `aid-update-ticket` and `aid-create-ticket` are both reported with their measured
      pre-change and post-change character counts
- [ ] **AC-12 checks 2 and 4 over the nine.** No description contains `Direct-entry Lite-path
      shortcut`, `VERB=`, `ARTIFACT=` or an arrow-separated state transition sequence, and each names
      the user-facing outcome before any AID-internal vocabulary (a reviewer read, all nine quoted)
- [ ] **Every one of the nine states when to use the skill**, in AC-12's imperative form, recorded
      per skill with the clause quoted
- [ ] **The ticket suite is green, unmodified.**
      `bash tests/canonical/test-ticket-skills-structural.sh` passes -- with `T02`, `T08`, `T14` and
      `T54` individually reported `PASS` -- and
      `git diff master -- tests/canonical/test-ticket-skills-structural.sh` is **empty**. Naming
      `T54` does not narrow the criterion: the whole suite must be green, which is what catches a
      description-anchored assertion this Scope did not find
- [ ] **The three relocated state-machine lines are relocated, not deleted.** For each of
      `aid-graph`, `aid-housekeep` and `aid-update-kb`,
      `grep -c 'State machine:' canonical/skills/<name>/SKILL.md` captured to a variable is `1` and
      that occurrence is **below** the frontmatter's closing `---`. Any skill in this slice whose
      description carried no such line is reported as carrying none, rather than being silently
      absent from the list
- [ ] **No negative route was lost.** For each of the nine, the sorted set of `/aid-`-prefixed names
      in the description is compared with the same set from
      `git show master:canonical/skills/<name>/SKILL.md`; every difference is an addition or a
      removal recorded with its reason
- [ ] **Only the nine moved.** `git diff --name-only master -- canonical/skills/` lists exactly the
      nine `SKILL.md` files this slice owns plus the files earlier slices already committed, and
      `git diff --name-only HEAD -- canonical/skills/` at the end of this task lists only the nine
- [ ] **Frontmatter shape is intact on all nine**, `tests/canonical/test-frontmatter-lint.sh`,
      `tests/canonical/test-graph-skill-registration.sh` and
      `tests/canonical/test-connector-skills-structural.sh` are green, and each of the three
      connector and two KB skills still declares all four frontmatter keys
- [ ] Accuracy verified against the current codebase: every line number and assertion id in this
      task's record is re-resolved against the file as it stands
- [ ] Nothing outside the declared writes moves:
      `git diff --exit-code -- tests/ site/ canonical/aid/templates/ docs/ .aid/knowledge/` is
      clean, and `git status --porcelain profiles/ .claude/ .cursor/` is unchanged from its state at
      the start of this task
- [ ] All section-6 quality gates pass
