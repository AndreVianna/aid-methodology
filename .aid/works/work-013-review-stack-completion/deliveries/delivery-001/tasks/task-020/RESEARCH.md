# task-020 — bounding the work-artifact corpus

**Question.** Which work-folder artifacts should resolve to a type in the review-criteria registry,
so the durable-anchor and quote criteria can bind them?

**Answer.** None of them, via the registry. The proposed corpus breaks criterion `G-07`, and the
only way to close it sweeps the whole work tree in — a hundred-odd files — to cover seven. Bind the four artifact kinds by per-file
`review-criteria:` frontmatter instead, and leave the registry's corpus where it is.

## The proposed corpus, as a selector

The candidate set is four artifact kinds, not every file a work writes:

```
$ find .aid/works -type f \( -name REQUIREMENTS.md -o -name PLAN.md \
    -o -path '*/features/*/SPEC.md' -o -path '*/deliveries/*/BLUEPRINT.md' \) | wc -l
7
$ find .aid/works -type f -name '*.md' ! -name '.*' | wc -l
111
```

**The candidate count is stable at 7; the total is not, and that is the finding in miniature.** A
work gains one `REQUIREMENTS.md` and one `PLAN.md` and is done, but it gains a `DETAIL.md` per task,
a brief per review cycle and a `FINDINGS.md` per gate. Writing *this document* took the total from
110 to 111 between measuring it and recording it. Any absolute figure below is true at the moment
its command ran and will not be true when you re-run it — so re-run it rather than trusting it.

Everything outside the seven is execution churn: 48 `DETAIL.md`, 34 reviewer briefs, 17
`FINDINGS.md`, plus `RECORD.md`, `ORIGIN.md` and two `CORRECTION.md`.

State files need no exclusion clause. All 51 are `STATE.yml`, and the registry's corpus is markdown,
so they fall outside it on file extension alone:

```
$ find .aid/works -name 'STATE.md' | wc -l
0
$ find .aid/works -name 'STATE.yml' | wc -l
51
```

The `state` row (`path **/STATE.md`) therefore does not need to fire, and the existing exclusion
stands untouched.

## The grammar cannot express this as one row

`Match` clauses join with `AND` only — there is no `OR`:

```
$ sed -n '/THE GRAMMAR/,/^# *$/p' scripts/checks/g07-selector-partition.sh
#   path <glob>              the repo-relative path matches the glob
#   fm <key> == <value>      frontmatter has that key with that scalar value
#   name-in <file>           the parent directory name appears as a `name:` value in <file>
#   ... joined by AND
```

Four alternative paths at three different depths cannot be one selector. The proposal is therefore
four rows, tested as such.

## The oracle result: the proposal breaks the partition

Run against a scratch copy carrying the four rows, with `ROOTS` widened to include `.aid/works`:

| Variant | exit | files resolving to no type | `UNDECIDED` |
|---|---|---|---|
| baseline, corpus unchanged | 0 | 0 | 76 |
| four rows, no catch-all | **1** | **103** | 76 |
| four rows + a `work-other` catch-all | 0 | 0 | 76 |

The 76 `UNDECIDED` are the pre-existing `template-payload` rows in every variant; the work tree adds
none, so the proposal does not disturb them.

**Why it breaks.** `G-07` says *every* in-scope markdown file resolves to exactly one type. Widening
the corpus is all-or-nothing: the moment `.aid/works/` is in scope, every one of its files must
resolve, including the hundred-odd the proposal deliberately excludes. There is no way to admit part
of a directory tree. The 103 violations above are that count at the time the oracle ran.

**Why the catch-all is worse than the problem.** It does close the partition, at a cost of sweeping
every non-candidate work file into the criteria cascade to buy coverage for seven — at the time of
measurement, fifteen files of collateral for every file of intent, and the ratio worsens with every
task executed. Those 103 are reviewer briefs and findings ledgers, and the cascade would then
demand the durable-anchor rule of artifacts whose whole job is to cite a file and a line.

## What the corpus would actually buy

Of the 63 citation-lint violations under a work root, split by whether the candidate set covers
them:

| Where | Violations | In the candidate set? |
|---|---|---|
| `features/*/SPEC.md` | 46 | yes |
| `FINDINGS.md` | 12 | no |
| `briefs/*.md` | 3 | no |
| `CORRECTION.md` | 2 | no |

The four candidate kinds hold **46 of 63**, and every one of the excluded 17 is a review artifact
where `file.ext:LINE` is the correct thing to write — a reviewer citing the line they found. So the
candidate set is well chosen: it captures nearly three-quarters of the signal and excludes precisely
the artifacts the rule should not bind. The problem is not the set. It is that the registry cannot
express a set.

## Recommendation: narrow, do not widen the partition rule

Per this task's own acceptance criterion, the recommendation on a broken partition is to narrow.

1. **Do not widen `G-07`'s corpus.** Leave `ROOTS` at its four canonical roots. `G-07` is valuable
   *because* it is total over a bounded corpus; making it total over a tree that grows a file per
   task would make it either false or vacuous.
2. **Bind the criteria per file instead.** `REQUIREMENTS.md`, `PLAN.md`, `features/*/SPEC.md` and
   `deliveries/*/BLUEPRINT.md` each carry `review-criteria:` frontmatter naming the durable-anchor
   and quote criteria. The cascade already resolves per-file declarations as its most specific
   level, so this needs no registry change, no new type, and no grammar extension.
3. **Leave the work-artifact CI step reporting rather than gating.** It surfaces the count without
   asserting a rule the corpus cannot carry.

This leaves task-021 a narrower job than its title implies: not "give work artifacts a registry
home", but "declare the two criteria on the four artifact kinds, per file". That is a real change in
scope and the owner should see it rather than have it absorbed silently.

## Reproducing this

The scratch test is a copy, so nothing here was written to the registry:

```bash
SC=$(mktemp -d); cp -r scripts .aid canonical "$SC/"; cd "$SC"
# insert the four rows after the `state` row in authoring-conventions.md, then:
sed -i 's#^readonly ROOTS=(.*#readonly ROOTS=("canonical/skills" "canonical/agents" "canonical/aid/templates" ".aid/knowledge" ".aid/works")#' \
  scripts/checks/g07-selector-partition.sh
bash scripts/checks/g07-selector-partition.sh
```
