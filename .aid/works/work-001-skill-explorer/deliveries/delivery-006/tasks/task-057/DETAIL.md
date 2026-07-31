# task-057: Hollow out `reference/skills.md` — keep the narrative, shed the roster (closes KI-009)

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-057. It is the IMMUTABLE DEFINITION for this task.
Shape: 6 sections matching .claude/aid/templates/delivery-plans/task-template.md.
Authored at execution time from `deliveries/delivery-006/BLUEPRINT.md`, per this delivery's
STATE.md Q1. The consequential-edits scope below (§ Consequential edits) was **discovered by
measurement during this delivery** and is recorded in this delivery's STATE.md as Q5 — the
BLUEPRINT's task line did not name it.

> **Execution protocol (binding on whoever executes this task -- no
> exceptions):** the moment this task's `State` changes, write it --
> `In Progress` before starting work, `In Review` before dispatching the
> reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. Full mandate:
> `aid-execute/references/state-execute.md § MANDATORY: State-Write Protocol`.

**Type:** IMPLEMENT

**Source:** work-001-skill-explorer -> delivery-006

**Depends on:** task-056

**Scope:**
- Change `site/scripts/gen-reference.mjs`'s `generateSkillsPage()` so `reference/skills.md` is
  **hollowed out, not deleted**: it sheds the duplicated per-skill roster and the per-family
  roster table, and keeps the shortcut-engine narrative — the
  `INTAKE → CAPTURE → SPEC → PLAN → DETAIL → GATE → APPROVAL-HALT` sequence and its
  explanation, which is the **only** place on the site that narrative lives. The page also
  gains a prominent pointer to `/skills/` for readers who arrive looking for the roster.
- Hollowing out is what **closes KI-009 by deletion**. The two broken renderings —
  `` `aid-test` + 3 typed forms (security, performance, data-quality) = 0 `` at
  `reference/skills.md`:185 and `` `aid-document` + -1 typed forms `` at :187 — come from
  `gen-reference.mjs`:245 and :255, where both templates assume the family has non-`repurpose`
  catalog rows and then interpolate `rows.filter(...).length` and `rows.length - 1` against an
  empty array. Both templates die with the roster table, so there is no arithmetic to repair.
  Do **not** fix the arithmetic and keep the table — that is the wrong close.

**Consequential edits (required for the delivery's own no-false-claims criterion):**
- `site/scripts/skills/render-index.mjs`:139–146 generates a divergence note into
  `skills/index.md` whose every clause dies with the roster: it calls `/reference/skills/` a
  "terse family **summary**", says it "groups `aid-triage`, `aid-deploy`, and `aid-monitor` under
  *Definition*", and explains the divergence as existing "because the older generator is
  frozen". After this task there is no competing grouping to diverge from, and Q4 unfroze that
  generator. Retire or rewrite the note so the generated page states nothing false, and update
  `skills-render-index.test.mjs`'s **AC-7** assertions (lines ~202–204) to match — the current
  test requires the note to link to `/reference/skills/`, so leaving it unchanged would pin a
  claim this task falsifies.
- The intro sentence carries an **unbalanced closing parenthesis** in reader-facing output —
  `…all hand-authored with their own directories).` closes a group that `(24 canonical + 6 alias)`
  already closed. A pre-existing typo, found during task-054's review and deliberately left
  there because task-054 promises this page byte-unchanged. This task rewrites the sentence, so
  fix it here. (`gen-reference.mjs` carries a `NOTE:` comment at that site pointing to this task.)
- `site/astro.config.mjs`:158 lists `{ label: 'Skills', slug: 'reference/skills' }` in the
  **Reference** sidebar group. The page survives, so the entry stays — but the label must no
  longer read as a second roster competing with the top-level `Skills` tab. Relabel it to name
  what the page now is (the shortcut engine).

**Acceptance Criteria:**
- [ ] The shortcut-engine narrative survives on `reference/skills.md`, asserted **by content**
      (the `INTAKE → CAPTURE → SPEC → PLAN → DETAIL → GATE → APPROVAL-HALT` sequence and its
      explanatory prose are present) and not merely by the file existing.
- [ ] The duplicated roster is gone: no per-skill section list and no per-family table on
      `reference/skills.md`.
- [ ] **KI-009 is closed by deletion:** neither `= 0` nor `-1 typed forms` — nor any other
      arithmetic artefact of the shed templates — appears anywhere in the generated page. The
      two source sites at `gen-reference.mjs`:245 and :255 no longer emit.
- [ ] The page carries a visible pointer to `/skills/` for a reader who came for the roster.
- [ ] `skills/index.md`'s generated note states nothing false about `/reference/skills/`, and
      `skills-render-index.test.mjs` asserts the **new** contract rather than the retired one.
- [ ] The `Reference → Skills` sidebar label names the shortcut-engine page, not a roster.
- [ ] **§7's amendment stays bounded:** `reference/agents.md`, `reference/kb.md` and
      `reference/settings.md` are **byte-unchanged**, and `gen-reference.mjs` remains idempotent
      (a second run rewrites identical bytes).
- [ ] The 111 generated skill detail pages and their sidecars are byte-unchanged.
- [ ] `gen-reference.test.mjs` and `skill-counts.test.mjs` both pass — including
      `skill-counts.test.mjs`'s "agrees with the count the reference page renders" case, which is
      written to tolerate the hollowed-out page.
- [ ] Deliveries 001–005 still hold: the full site suite passes and the build is clean.
- [ ] All section-6 quality gates pass.
