# task-001: Landed `.aid/design/` folder and its canonical README template

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-001/STATE.md.
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

**Source:** work-006-design-phase-skills -> delivery-001

**Depends on:** -- (none)

**Scope:**
- Source spec: `features/feature-002-design-lifecycle-machinery/SPEC.md` §1b, §1c, §2a-§2c,
  §2e, §2f (AC-1, AC-12). **This is the first task of the delivery**: feature-002's commits
  are ordered first so that the commit range gate criterion 2 evaluates over is a clean
  feature-002-only block (BLUEPRINT § Gate Criteria, criterion 2; task-005 closes it).
- Author `canonical/aid/templates/design-folder-readme.md` -- the corrected README text,
  authored **once**, of which `.aid/design/README.md` is the byte-identical instantiation
  (§2a). Apply all **five** corrections in §2b's table: `/aid-interview` -> `/aid-describe`;
  the two-step deletion fence replaced by §2c's four-entry lifecycle block; the unqualified
  *"Delete the seed when the work ships"* body rule qualified per entry; the closing
  *"is deleted once it **is**"* clause qualified the same way while keeping the governing
  what-**is** / what-**should-be** distinction; and the "conventions and gates" row of the
  "What belongs here" table re-routed from `quality-gates.md` (no template under
  `canonical/aid/templates/knowledge-base/`, so an adopter would be sent to a document AID
  never installs) to `coding-standards.md`.
- Write §2c's lifecycle block with all four entries -- A hand-written, B skill-authored
  design artifacts (7), C skill-authored code artifacts (14, seed persists, manual
  deletion), D exploratory (`/aid-brainstorm`, no `create` counterpart). Deletion is stated
  **per entry**, never universally.
- Drop the branch README's closing "Why this file exists" section in both locations (§2a) --
  it is AID's own folder history and git holds it.
- Land `.aid/design/README.md` as that template byte-identical, and
  `.aid/design/knowledge-graph-redesign.md` byte-identical to
  `git show docs/graph-redesign-seed:.aid/design/knowledge-graph-redesign.md` (§1b, §2e).
- Add one line to `.aid/knowledge/project-structure.md`'s `.aid/` tree. The line must carry
  **three** things the SPEC's own quotation does not all show, so it is spelled out here in
  the exact form the tree takes rather than copied from §1c: the **four-space indent** every
  child of the `.aid/` node carries, the **box-drawing prefix**, and the **parenthetical**.
  On disk the node is `└── .aid/` and its children read
  `    ├── knowledge/            # the Knowledge Base (KB docs + INDEX + STATE + kb.html)`,
  so the new line is:

  ```
      ├── design/               # design seeds under construction (.aid/design/README.md defines the convention)
  ```

  feature-002 §1c quotes the same line **unindented**, which is a presentational artifact of
  the spec's prose, not the shape the tree takes; an executor copying that quotation
  literally places `design/` at repository-tree level. Placed after the `knowledge/` line and
  above the *"CONFIRMED by direct `find` traversal of each subtree"* claim the tree stands
  under, with the comment column padded to match its siblings (§1c, AC-12).
- Out of scope: `.gitignore` (§2f -- `.aid/design/` is tracked **by absence** from the
  installer's hardcoded six-entry list); both installer libraries (§2d rejects the
  install-time seed); and the `design-seed.md` / `design-lifecycle.md` templates
  (task-002, task-003).

**Acceptance Criteria:**
- [ ] §7 A1: `diff canonical/aid/templates/design-folder-readme.md .aid/design/README.md`
      is empty
- [ ] §7 A2: `! grep -q 'aid-interview' .aid/design/README.md`
- [ ] §7 A3: **both** `! grep -qF 'Delete the seed when the work ships'` and
      `! grep -qF 'is deleted once it'` hold -- the two sentences that taught universal
      deletion in two places
- [ ] §7 A4: `grep -c '^Entry [A-D] —' .aid/design/README.md` captured to a variable -> `4`
- [ ] §7 A5: `! grep -q 'quality-gates.md' .aid/design/README.md`, with the re-routed row
      naming `coding-standards.md` instead
- [ ] §7 A6:
      `git show docs/graph-redesign-seed:.aid/design/knowledge-graph-redesign.md | diff - .aid/design/knowledge-graph-redesign.md`
      is empty
- [ ] §7 K1, with both anchors pinned to a single line each, because neither is unique on a
      loose pattern. Capture three line numbers:
      `A = grep -n '^└── \.aid/'` (the tree node itself -- a loose `grep -c '\.aid/'` returns
      **16** matching lines in this file, 18 occurrences by `grep -o`, and the unescaped
      `grep -c '.aid/'` returns **28**; all three start well above the tree, which is why the
      anchored form is used. The anchored grep returns the single line `:131`);
      `B = grep -n '^    ├── design/'` (the new line);
      `C`, the **first** `grep -n '^CONFIRMED by direct'` hit (that string occurs **twice**,
      and taking the second would admit a `design/` line placed anywhere in the ~130 lines
      between them -- outside the tree the criterion exists to protect).
      Assert `A < B < C`
- [ ] Position pinned exactly, not merely bounded: the new line **immediately follows** the
      `    ├── knowledge/` line -- `grep -n '^    ├── knowledge/'` returns `B - 1`. That is
      the placement §1c specifies, and it makes the criterion single-valued rather than a
      range check
- [ ] The added line carries all three of the indent, the prefix and the parenthetical:
      `grep -cE '^    ├── design/ +# design seeds under construction \(\.aid/design/README\.md defines the convention\)'`
      over `.aid/knowledge/project-structure.md` -> `1`. The `^    ├── ` anchor is the part
      that fails on a line pasted at zero indentation, which is how the SPEC quotes it
- [ ] The template carries none of `{project_context_file}`, `{reviewer_output_file}`,
      `{open_questions_file}` and no `canonical/...` path, so neither `substitute_filenames`
      nor `rewrite_install_paths` fires on it and A1's byte-identity survives the render
      (§2a -- a standing constraint on the template's content, not a one-time check)
- [ ] `git check-ignore -v .aid/design/README.md` returns no match and
      `git diff --exit-code -- .gitignore` is clean (§2f)
- [ ] Accuracy verified against the current codebase (DOCUMENT type default)
- [ ] All section-6 quality gates pass
