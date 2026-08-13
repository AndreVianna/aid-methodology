# AC-2 proof — both directions, run in a disposable worktree

**Result: PASS in both directions.** Recorded here rather than added to the test suite: per
task-007's scope, no maintained test file is committed, and per **NFR-1** the plant never
existed anywhere but a throwaway tree.

## Harness

`git worktree add --detach <tmp> HEAD` (plain git, not `worktree-lifecycle.sh`, which has no
`destroy` verb and would have returned the *existing* work-004 worktree rather than a throwaway),
then `git worktree remove --force`. Nothing was committed from it and the work branch's files were
never edited — verified after each direction with `git status` on the tracked tree.

One setup step was needed and is worth naming, because it is the mid-work staleness **PLAN.md risk
1** predicts: the writer instruction added by task-005 lives in `canonical/` and in
`profiles/<tool>/{CLAUDE,AGENTS}.md`, and the *rendered* surfaces an agent actually reads are not
refreshed until delivery-003's single render. So inside the worktree, the `AID:BEGIN`/`AID:END`
region of the root context files was replaced with the region from the profile sources — exactly
what `_copy_root_agent_file` does at install time. Without that the proof would have tested a stale
render and proved nothing.

## Direction 1 — writer (FR-9): does an agent resolve the criteria unprompted?

**Dispatch:** `aid-developer`, pointed at the worktree, asked to add a subsection to
`.aid/knowledge/quality-gates.md` stating *"exactly where in the grading script the severity and
status columns are picked out of a ledger row, so they can go look at it themselves"* — phrasing
chosen to invite a bare `grade.sh:LINE` citation, which `G-02` forbids. It was also asked to state
a count, which `G-01` constrains.

**The prompt named no criterion**, no criterion id, no `review-criteria:`, no
`authoring-conventions.md`, and never used the words "durable anchor". It said only: this is your
project root, follow that project's own instructions.

**Outcome — complied, and could say why.** It wrote:

> In `canonical/aid/scripts/grade.sh`, find the awk block introduced by the comment
> `# Schema-table parsing path (new default)`. The two assignments `severity = trim(cols[3])` and
> `status = trim(cols[4])` are where the columns are picked from each pipe-split row.

- No bare `file:LINE` citation anywhere in the edit — `rg 'grade\.sh:[0-9]+'` returns nothing.
- Both cited anchors are real and grep-recoverable: each matches exactly once in `grade.sh`.
- Asked what shaped it, it named **`G-02`** in `.aid/knowledge/authoring-conventions.md` and quoted
  its reason (line numbers move on the next edit above them), and separately justified its count
  against **`G-01`** as load-bearing rather than cosmetic — the closed Status enum, which cannot
  drift without the enum itself changing.

It resolved the criteria from the tree and applied them **before** writing, which is the load-bearing
half of FR-2/FR-9.

## Direction 2 — reviewer (FR-2): does a planted contradiction come back citing the id?

**The plant** (worktree only), in `canonical/aid/templates/reviewer-ledger-schema.md`: a file-level
declaration asserting `F-01 — "Every ledger example in this document has exactly 7 columns"`
(`severity: HIGH`), and a body example given an 8th column, contradicting it. Self-announcing by
construction per NFR-1 layer 3 — the plant class is the very thing the mechanism detects.

**Dispatch:** `aid-reviewer`, pointed at the worktree, asked to review that one file "for internal
correctness and consistency". **The prompt named no criterion and no id.**

**Outcome — the finding came back citing `F-01`:**

```
| 1 | [HIGH] | Pending | canonical/aid/templates/reviewer-ledger-schema.md | 37 | F-01 — example row 1
has 8 data columns, not 7 ... | pipe count: ... row 1 = 9 pipes (8 cols) confirmed by tr -cd '|' | wc -c |
```

The id is a `Description`-cell prefix, the ledger is 7 columns, and the severity is the one the
criterion declared. Asked what it read to decide what the file must be true against, it named the
file's own `review-criteria:` frontmatter plus `.aid/knowledge/authoring-conventions.md` — it
resolved the cascade rather than being handed it.

## Findings the proof surfaced about the real tree

These are not the proof's subject; they are things the two probes found in passing, on the tracked
tree, and they are logged so they are not lost.

1. **The deferred HIGH is arguably CRITICAL.** Independently of task-002's quick-check, the reviewer
   found `kb-authoring/review-rubric.md § Temp ledger format` and rated it `[CRITICAL]`, with a
   sharper argument than the original: a reviewer who follows that section emits a ledger whose
   `cols[3]`/`cols[4]` are `Doc` and `Line`, so `grade.sh` finds no bracketed severity and **returns
   `A+` for every ledger written in the old shape**. Carried into `delivery-001-issues.md`; the gate
   should decide the severity.
2. **delivery-002's data pass must convert shape, not just rename the key.** Only the first entry of
   the plant's target was converted to an object, and the reviewer immediately flagged the remaining
   five bare strings as malformed against the schema. The same five strings exist in the tracked tree
   under `contracts:`. So the "mechanical key rename" of the field-bearing carriers is not
   mechanical: a bare-string entry has no `id`, and per the rule task-004 installed, a finding citing
   an id that resolves nowhere is itself a defect.
3. **Two pre-existing internal inconsistencies in `reviewer-ledger-schema.md`**, both out of
   delivery-001's scope: three passages disagree on whether an `Accepted`/`Invalid` rationale belongs
   in `Description`, in `Evidence`, or in both; and the Workflow section grants no reviewer path for
   marking a prior finding `Invalid`, though the Status table says the reviewer may.

## Teardown

`git worktree remove --force` executed; `git worktree list` shows only the main tree. The plant does
not appear in the tracked tree (`rg 'G-02 \|$'` on the real
`canonical/aid/templates/reviewer-ledger-schema.md` returns nothing), and no file under
`tests/canonical/` was added.
