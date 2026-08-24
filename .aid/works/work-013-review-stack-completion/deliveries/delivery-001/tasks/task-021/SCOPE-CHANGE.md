# task-021 — built narrower than written, on the owner's decision

## What the task said, and what was built

Its scope line reads:

> Add the registry row and criteria so work artifacts resolve to a type and inherit citation and
> quote-accuracy criteria, using ids drawn from the ledger.

No registry row was added and work artifacts still resolve to no type. The two criteria were bound
to them a different way. The owner chose this on 2026-08-24, presented with three options, after
task-020's research showed the written scope was not implementable without harm.

## Why the written scope was abandoned

task-020 measured it. Adding the four rows leaves the oracle at exit 1 with every non-candidate work
file resolving to no type; adding a catch-all to close the partition sweeps the entire work tree
into the criteria cascade to cover seven files, which would demand durable-anchor citations from
reviewer briefs and findings ledgers whose whole purpose is to cite a file and a line. The full
measurement is in `../task-020/RESEARCH.md`.

## What was built instead, and a correction to the research

task-020 recommended per-file `review-criteria:` frontmatter on the four artifact kinds. **That
recommendation was wrong on a point of fact, and was not followed.** None of the four artifacts
carries frontmatter, and `spec-template.md` states the absence as a deliberate design decision:

```
$ grep -n 'carries no frontmatter' canonical/aid/templates/specs/spec-template.md
    line 9:  ... This is a SPEC body line, not frontmatter -- SPEC.md carries no frontmatter block.
```

Per-file declaration needs a file that can hold a declaration. These cannot. A work folder is also
transient, so a per-file block would have to be rewritten into every future work rather than being
stated once.

The mechanism actually used was already in the conventions doc, and its stated rationale is the
same one task-020 arrived at independently:

> a **file class named by the criterion itself** scopes a criterion to a set of files that is not a
> document type. Each such row is deliberately not a registry type: the files it covers are not
> in-scope authored artifacts at all, so giving them a type would put them inside `G-07`'s "every
> in-scope file resolves to exactly one type" and make the registry claim something false.

`G-05` (`agent-context`) and `G-06` (`rendered`) already use it, and `G-05`'s own `why` names the
same blocker work artifacts have: those files "carry no frontmatter to declare this on".

So `G-14` and `G-15` are file-class rows naming `work-artifact`, each stating its own membership
test — `REQUIREMENTS.md`, `PLAN.md`, `features/*/SPEC.md`, `deliveries/*/BLUEPRINT.md` under
`.aid/works/`.

**One honest extension.** Both pre-existing file-class rows are `kind: exclude`; these two are
`kind: validate`. The form is described in the conventions doc as scoping "a global exclusion", so
using it to *include* files outside the corpus is new. The preamble now says the form works in both
directions and why, rather than leaving a reader to infer that a validate row is legitimate.

## The wiring, which is the part that could have been missed

Declaring the rows is inert unless a reviewer resolves them. The resolution procedure had four
steps — type, global, type-level, file-level — and no step for the file-class form, so `G-05` and
`G-06` were already unreachable by the documented procedure and `G-14`/`G-15` would have been too.
Worse, step 1 asserted the registry "always resolves" and called a no-type file a finding, which
would have made a reviewer file a spurious finding against every work artifact it saw.

Four files changed to close that:

| File | Change |
|---|---|
| `kb-authoring/review-rubric.md` | step 1 scoped to the in-scope corpus and a no-type file stated as correct; new step 4 for file-class; collision order now file over file-class over type over global |
| `canonical/agents/aid-reviewer/AGENT.md` | the same, in the agent's own short form |
| the six `canonical/skills/*/references/reviewer-brief.md` | the union sentence names the file-class level |
| `.aid/knowledge/authoring-conventions.md` | `G-14`, `G-15`, and the preamble generalised to both directions |

## Evidence

The partition is untouched, which is the whole point of not adding a registry row:

```
$ bash scripts/checks/g07-selector-partition.sh   # after
exit 0, VIOLATION 0, UNDECIDED 76
$ git stash push .aid/knowledge/authoring-conventions.md && \
  bash scripts/checks/g07-selector-partition.sh   # before
exit 0, VIOLATION 0, UNDECIDED 76
```

Byte-identical output before and after.

Ids collide with nothing: the namespace went from 37 to 39 with no duplicates, checked by
extracting every id from the criteria table and running `sort | uniq -d`, which prints nothing.

## What this leaves open

`G-14` and `G-15` are criteria a reviewer applies, not gates a script runs. The 46 citation
violations in this work's own feature SPECs are now nameable in a review, but nothing fails a build
over them. The CI step task-019 added stays reporting-only, which remains correct: its corpus is the
whole work tree, whereas `G-14`'s membership is four artifact kinds.
