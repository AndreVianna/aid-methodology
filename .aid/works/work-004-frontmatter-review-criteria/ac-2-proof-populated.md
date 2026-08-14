# AC-2 proof — a POPULATED file, run in a disposable worktree

**Result: PASS.** delivery-001's `ac-2-proof.md` proved the mechanism on a file whose criterion
was planted for the occasion. This one proves it on a file **this delivery actually populated**,
which is the harder and more useful claim: the declaration under test is one task-010 authored,
not one written to be found.

## Harness

`git worktree add --detach <tmp> HEAD`, plant, review, `git worktree remove --force`. Nothing
committed, the work branch's files never edited (**NFR-1**), teardown verified: the plant is
absent from the tracked tree and `git worktree list` shows only the main tree. No maintained
test file added.

Unlike delivery-001's proof, **no render step was needed**. That proof had to install the
writer instruction into the worktree's root context file because task-005's edit lives in
`canonical/` and `profiles/`. Here the subject is a KB doc read directly from
`.aid/knowledge/`, which is not a rendered surface, so the tree at `HEAD` was already the tree
under test.

## The plant

`.aid/knowledge/decisions.md` carries a declaration task-010 authored:

```yaml
review-criteria:
  - id: F-01
    kind: validate
    criterion: >
      Every `## Dn` decision section has a matching row in the Summary Table, and no id is used
      twice.
```

The plant adds a `## D27 — Ledger rows are appended, never renumbered` section to the body and
**does not** add its Summary Table row — precisely what `F-01` forbids. Verified before
dispatch: 27 `## Dn` sections on disk, and `D27` appearing exactly once in the file, so it has
no table row. Self-announcing per NFR-1 layer 3: the plant class is what the mechanism detects.

## The dispatch

`aid-reviewer`, pointed at the worktree, asked only to review `.aid/knowledge/decisions.md`
"for internal correctness and consistency". **The prompt named no criterion, no criterion id,
and no `review-criteria:`.**

## Outcome — the finding came back citing `F-01`

Row 1 of the ledger it wrote cites `F-01` and states the violation exactly: the `## D27`
section exists in the body while the Summary Table lists D1 through D26 only. Asked what it
read to decide what the file must be true against, it named **the file's own `review-criteria:`
frontmatter first**, then `authoring-conventions.md` for the global and `kb-doc` levels — it
resolved the cascade rather than being handed it.

It also noticed the plant's placement (between D1 and D2 rather than after D26) and inferred
that the section had been appended without the table being updated. That is the reviewer
reasoning about the criterion, not pattern-matching a string.

## What the probe found about the real tree, and what was done

The review surfaced three findings that are **not** the plant. One was a class defect and is
fixed; the rest are recorded.

1. **Fixed — a dangling `## Change Log` Contents anchor in 17 KB docs.** delivery-001's gate
   caught this in `authoring-conventions.md` and it was fixed there. This probe found the same
   defect in a sibling doc — which is exactly the "a finding is a CLASS, not the line it was
   reported on" failure the FIX contract's `F1` exists to prevent. So the class was swept: every
   `.aid/knowledge/*.md` whose Contents listed `- [Change Log](#change-log)` while carrying no
   such section had the dangling entry removed, 17 in total.

   The source of the class was checked rather than assumed: the `knowledge-base/` doc templates
   carry no such Contents line, so newly seeded docs do not inherit it — this is historical
   residue from before the no-history rule. Three `canonical/skills/aid-describe/references/*.md`
   files also list the anchor, and they were **left alone**: each genuinely has the section, the
   anchors resolve, and the no-history rule binds `.aid/knowledge/` alone.

2. **Recorded — two `G-01` count drifts in `decisions.md`**: D20's frozen historical shortcut
   counts, and D4's "14 short markdown docs" stated in the present tense against 17 hand-authored
   docs on disk. Both are real. Both are content corrections outside this delivery's scope, so
   they go to the delivery issue log rather than being fixed here.

3. **Recorded — a genuine gap in the criteria table.** The reviewer wanted to report a surviving
   legacy `intent:` block in `decisions.md`, which `authoring-conventions.md § Frontmatter Rules`
   says to delete, and **could not**: no criterion id covers legacy-field removal, and under the
   rule task-004 installed, a finding citing no id is itself a defect. So it reported it outside
   the ledger instead.

   This is the mechanism working as designed and reporting its own blind spot: the rule that
   findings must cite a criterion is what turned an un-citable observation into a visible gap
   rather than a silent omission. Whether to add that criterion is a scope decision, not a
   defect, so it is logged for the gate.
