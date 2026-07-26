# task-014: Index page renderer

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-014. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-014/STATE.md.
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

**Type:** IMPLEMENT

**Source:** work-001-skill-explorer -> delivery-002 (feature-002-grouped-skill-index)

**Depends on:** task-007, task-011

**Scope:**
- Create `site/scripts/skills/render-index.mjs`: assemble `src/content/docs/skills/index.md` -- frontmatter (`title: 'All Skills'`, the fixed `description`, the two-source `generatedFrom`, and the nested `sidebar: hidden: true` block), the generated marker, the intro paragraph with counts interpolated from the live scan, the divergence note, then the group and family sections.
- A "card" is **one markdown list item**, `- [`name`](/skills/<dir>/) — intent`, not a Starlight `LinkCard`: 70 of the 111 descriptions contain an authored inline code span that `LinkCard`'s plain-text `description` would print as literal backticks, and 15 contain a `"`, 6 a `<` plus letter or `/`, and one a `{...}` group that JSX-attribute escaping would turn into a build-breaking contract over machine-generated text.
- Emit exactly **two heading levels**: H2 per curated group, H3 per verb family as a bare code span (`` ### `create` ``), so `tableOfContents: { minHeadingLevel: 2, maxHeadingLevel: 3 }` renders the whole taxonomy and only the taxonomy. The full-path block carries a **bold lead-in line and no heading**, so it does not enter the TOC as a peer of the verb families.
- Card intent comes from `skillSummary` imported from `summary.mjs` (task-007), escaped by the same code-span-aware rule task-006 implements. The link target is `record.route` verbatim.
- The divergence note sits immediately below the intro and above the first `## ` heading (so it is not a TOC entry), names `aid-triage`, `aid-deploy` and `aid-monitor` as the three skills `reference/skills.md` groups differently, declares this page authoritative for grouping, and links to `/reference/skills/`. The three names are a curatorial statement tied to FR-5, not derived -- deriving them would mean importing the frozen generator's `SKILL_GROUPS`.
- Frontmatter is serialized in the siblings' single-quoted `''`-escaped style; because that serializer emits flat scalar pairs only, the nested `sidebar:` key is appended by this module as a literal two-line block after the scalar pairs.

**Acceptance Criteria:**
- [ ] The emitted page matches all three index-grammar regexes -- group `` /^## (.+)$/ ``, family ``/^### `([a-z][a-z-]*)`$/``, card ``/^- \[`([a-z0-9-]+)`\]\((\/skills\/[a-z0-9-]+\/)\) — (.+)$/`` -- and **nothing else in the page matches any of them**.
- [ ] Exactly two heading levels are emitted: H2 for the four curated groups, H3 for verb families, each family heading holding a bare code span and nothing else.
- [ ] The full-path block carries a bold lead-in and **no heading**, so it creates no family for a parser and no TOC peer for a reader.
- [ ] Card intent equals `skillSummary(record)` for every card, escaped by the same code-span-aware rule as the detail header; the module does not reimplement either rule.
- [ ] The generated marker is byte-identical to the sentence the existing generated pages carry, em-dash included.
- [ ] `title` is `'All Skills'` -- distinct from `reference/skills.md`'s *Skills* -- and the nested `sidebar: hidden: true` block is present and correctly indented.
- [ ] The divergence note is present, sits after the intro and before the first `## `, names the three skills, and links to `/reference/skills/`.
- [ ] **No count literal appears** in the module or in the page template; every count that reaches the page is interpolated from `records.length` or the catalog row set.
- [ ] Unit tests exist for the exported function, including a grammar round-trip that parses the rendered output; all existing tests still pass; the build passes.
- [ ] All section-6 quality gates pass
