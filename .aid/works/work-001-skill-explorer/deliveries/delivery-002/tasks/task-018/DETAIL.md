# task-018: `gen-skills-index.test.mjs` -- the 15-assertion AC-8 suite

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-018. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-018/STATE.md.
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

**Type:** TEST

**Source:** work-001-skill-explorer -> delivery-002 (feature-002-grouped-skill-index)

**Depends on:** task-015

**Scope:**
- Author `site/scripts/__tests__/gen-skills-index.test.mjs` -- a **separate file** from `gen-skills.test.mjs`, each suite owning one artifact, mirroring feature-001's decision to keep its suite separate from `gen-reference.test.mjs`.
- Implement feature-002's fifteen numbered assertions verbatim, parsing the rendered `index.md` through the three index-grammar regexes so AC-8 is a **parse rather than a substring hunt**: card set equals the on-disk directory set in both directions with no duplicate; the four `## ` headings in fixed order; curated placement agreeing with `groups.mjs`; catalog agreement for every non-curated card; the full-path block by exact array equality; the exemption **derived** via `byName.has(n) === false`; `aid-deploy` and `aid-monitor` by name; the clamp; family heading order equal to catalog first-appearance order restricted to non-curated rows; no dead cards; card intent equal to `skillSummary(record)` and to the target page's `description`; no unescaped `<` outside a code span; marker, manifest row and `generatedPaths` with still no `generatedAt`; index byte-identical across two runs; and the divergence note present, before the first `## `, linking to `/reference/skills/`.
- The suite builds its own expectations from `canonical/skills/` and `shortcut-catalog.yml` and **never reads anything under `.aid/works/`**, per the transient-work-folder rule.

**Acceptance Criteria:**
- [ ] All fifteen assertions are present, each deriving its expectation from `canonical/skills/`, `shortcut-catalog.yml`, `groups.mjs`, `summary.mjs`, the rendered pages or the manifest.
- [ ] **No assertion compares anything to a numeric literal** anywhere in the file -- the defect class that produced KI-005.
- [ ] Assertion 5 pins the full-path block by **exact array equality** on `['aid-describe','aid-define','aid-specify','aid-plan','aid-detail']`, so order and membership are both fixed without a length literal.
- [ ] Assertion 6 **derives** the family exemption (`byName.has(n) === false` for each of the five), so if the corpus ever gains a catalog row for one of them the test fails rather than the exemption silently becoming a lie.
- [ ] Assertions 3 and 7 name `aid-triage` -> `Support`, `aid-deploy` -> `` `deploy` `` and `aid-monitor` -> `` `monitor` `` explicitly, and assert neither of the latter two appears in the full-path block.
- [ ] Assertion 8 (the clamp) checks both directions: every directory is curated or catalog-backed, and every curated name has a directory.
- [ ] Assertion 10 resolves every card route to an existing `site/src/content/docs/skills/<name>.md` -- no dead cards.
- [ ] Assertion 11 asserts, for every skill, that the card's intent equals `skillSummary(record)` **and** that the unescaped summary equals the target page's `description` frontmatter, pinning the two modules together.
- [ ] Assertion 14 is a byte comparison of `index.md` across two generator runs, not a `git diff`.
- [ ] Tests are deterministic, use clean setup/teardown, build their own expectations, and read nothing under `.aid/works/`.
- [ ] AC-8 is fully covered, including the catalog-agreement scoping and the full-path exemption REQUIREMENTS section 9 spells out.
- [ ] All section-6 quality gates pass
