# task-056: Repoint the 8 inbound links from `/reference/skills/` to `/skills/`

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-056. It is the IMMUTABLE DEFINITION for this task.
Shape: 6 sections matching .claude/aid/templates/delivery-plans/task-template.md.
Authored at execution time from `deliveries/delivery-006/BLUEPRINT.md`, per this delivery's
STATE.md Q1.

> **Execution protocol (binding on whoever executes this task -- no
> exceptions):** the moment this task's `State` changes, write it --
> `In Progress` before starting work, `In Review` before dispatching the
> reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. Full mandate:
> `aid-execute/references/state-execute.md § MANDATORY: State-Write Protocol`.

**Type:** IMPLEMENT

**Source:** work-001-skill-explorer -> delivery-006

**Depends on:** task-055

**Scope:**
- Repoint the **8 hand-authored inbound links** that send a reader to `/reference/skills/`
  looking for the roster, so they land on `/skills/` — the derived section with one card per
  skill, which is the better page and the destination work-level Q4 chose:
  - `site/src/content/docs/guides/pipeline.mdx` — **7** `<LinkCard href="/reference/skills">`
    occurrences (lines 101, 126, 142, 158, 176, 198, 249).
  - `site/src/content/docs/reference/overview.md` line 16 — the Skills row's link target.
- Each repointed link's **surrounding text must still be true of its new destination.** The
  `LinkCard` descriptions currently read "Full roster of AID skills with descriptions and
  argument hints" — that describes `/skills/` at least as well as it described the page being
  hollowed out, but the title `Skills reference` names a section the reader is no longer being
  sent to. Titles and descriptions are corrected to match where the link now goes; a repointed
  link with stale surrounding prose is a half-done repoint, not a repoint.
- `reference/overview.md` line 16 is the one file this task shares with task-055, which is why
  the two are sequenced rather than parallel: task-055 rewrote that line's prose, this task
  changes its link target. Preserve task-055's corrected triple exactly.
- **Out of scope:** the `astro.config.mjs` sidebar entry for `reference/skills` (the page still
  exists after task-057, so the entry stays valid — its *label* is task-057's concern), and the
  generated divergence note in `skills/index.md` (also task-057, because its premise only dies
  once the roster is actually shed).

**Acceptance Criteria:**
- [ ] All 7 `pipeline.mdx` link targets and the `overview.md` line-16 target point at `/skills/`.
- [ ] No hand-authored page under `site/src/content/docs/` still links a reader to
      `/reference/skills/` **as the place to find the roster** — verified by grep over the source.
- [ ] The same grep is run over the **built output** (`site/dist/`) and confirms the repointing
      survived the build, per the BLUEPRINT's gate criterion that this be verified in both.
- [ ] Every repointed link's title and description are true of `/skills/`.
- [ ] `reference/overview.md` line 16 still carries task-055's derived `111 / 19 / 64` triple —
      this task changed the target, not the numbers.
- [ ] `/skills/` resolves for every repointed link (no 404 introduced), and the links use the
      trailing-slash form the rest of the site uses.
- [ ] `skill-counts.test.mjs` still passes; the full site suite passes; the build is clean.
- [ ] All section-6 quality gates pass.
