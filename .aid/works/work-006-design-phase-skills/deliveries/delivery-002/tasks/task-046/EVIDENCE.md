# task-046 EVIDENCE -- FR-8's asking obligation, and the Conformance-Lane divergence surviving `update`

Rows: feature-004 **V16** (AC-9's four parts) and **V23** (AC-12(b)). Both need an `update` run
and neither is satisfiable from a working-tree listing alone, which is why they are cut as a task
rather than folded into task-040..043.

## 0. Fixtures

Both baselines were created under `mktemp -d`, `git init`-ed with a baseline commit (so an empty
`git status --porcelain` inside any copy is a real result rather than an exit-128 misread), and
carry the rendered dogfood `.claude/`.

**F-ask** -- a populated 26-line `.aid/knowledge/architecture.md` with `source: hand-authored`,
declared in `.aid/settings.yml` `knowledge.doc_set`, no `.aid/design/`, and a README. V16 runs
here, and its **two runs share one copy by design**: "run 2 asks again" is only meaningful in a
project run 1 already touched.

**F-flagged** -- the same document at `source: forward-authored`, plus a Conformance-Lane
divergence **already recorded** as a KB Q&A entry in `.aid/knowledge/STATE.md`, in the Style A
shape `state-kb-delta.md § Sub-step 2b` prescribes: `### Q7`, `**Category:** Housekeep /
Conformance Reconciliation`, `**Impact:** Required`, `**Status:** Pending`, a `[contradiction]`
item citing `src/reader.py:88`, and `User choice: [3]` -- deferred, so the doc is consequently
byte-unchanged. V23 runs here, on its own fresh copy.

**Why the flag is a fixture edit rather than a detection outcome** -- the same reason task-040
gives for its step-4 seed. What a real code -> design divergence detection produces is not under
the executor's control, so a precondition of the form *"the housekeep run happens to flag item
X"* would be unreachable. The lane's own mechanism makes the fixture faithful rather than a
stand-in: the lane **flags and does not reconcile**, so *"until the entry is actioned, every
forward-authored doc is byte-unchanged"* (`state-kb-delta.md:564`) -- and **the recorded entry is
the flag**. Built before the row started; no row repaired its own precondition.

## 1. V16(a) / AC-9(a) -- static, read whole over all four `update` bodies

task-038 asserted its own share at authoring time; AC-9 closes only when all four parts hold
together, so the static part is re-read here as part of the row:

| Body | `derived outputs` inside UPDATE | a numbered step | governed by an `if`/`when` | says "unconditional" |
|---|---|---|---|---|
| `aid-update-architecture` | line 67 | yes | **no** | yes |
| `aid-update-stack` | line 65 | yes | **no** | yes |
| `aid-update-testing-strategy` | line 68 | yes | **no** | yes |
| `aid-update-cicd` | line 71 | yes | **no** | yes |

The step reads: *"**Ask, every run, which derived outputs to update alongside this one.** This
step is unconditional -- it runs on every invocation, and the answer is **stored nowhere**: no
frontmatter backlink, no manifest, no registry, and no state carried between runs. The question
is asked afresh each time."*

**V16(a) PASS.**

## 2. V16(b) / AC-9(b) -- behavioral: run 2 asks again (R-ask, two runs, one copy)

Both transcripts recorded, since "asked again" is a reading of the run rather than of a file.

**Run 1** applied the named change (a coordinator, in `## Components`) and asked: *"Which derived
outputs should I update alongside this one?"* -- answered "none this run", stored nowhere.

**Run 2**, in the same project, applied a different named change (the coordinator's boundary
behavior, in `## Boundaries`) and **asked again**, afresh -- run 1's answer was not recalled, not
offered as a default, and not read from anywhere, because nothing persisted it.

```
run 1 asked: 1     run 2 asked: 1     run 2 recalled a stored answer: no (asked afresh)
```

**V16(b) PASS.** An `update` that never asks would fail (a) and (b); one that asks once and
remembers would fail (b) and (c).

## 3. V16(c) / AC-9(c) -- no stored answer

After run 2, for **both** runs' work state:

```
$ grep -rniE 'derived[-_]outputs|output_list|outputs:' .aid/settings.yml \
      .aid/works/work-001-update-architecture/STATE.yml
0 hits
$ grep -rniE 'derived[-_]outputs|output_list|outputs:' .aid/settings.yml \
      .aid/works/work-002-update-architecture/STATE.yml
0 hits
```

And the skill wrote no other state file:

```
$ git status --porcelain
 M .aid/knowledge/architecture.md
?? .aid/works/
```

Exactly the destination document and the work folder. (`git status` also listed
`.run1.transcript` / `.run2.transcript`; those are **this executor's** recording artifacts, not
files the skill wrote, and are excluded on that basis.)

**V16(c) PASS.** The work state file is `STATE.yml` rather than the AC's `STATE.md` -- the format
migrated after this task was written; the grep is the same and returns 0 either way.

## 4. V16(d) / AC-9(d) -- no tracking metadata

The file list is derived from the run's own `git status --porcelain`, not from a remembered list:

```
wrote: .aid/knowledge/architecture.md
wrote: .aid/works/work-001-update-architecture/STATE.yml
wrote: .aid/works/work-002-update-architecture/STATE.yml
$ grep -rniE 'derived-from|source-doc|generated-by|aid-tracked' <that list>
0 hits
```

Destination frontmatter unchanged: `source: hand-authored`, `approved_at_commit:` absent.

**V16(d) PASS.**

## 5. V23 / AC-12(b) -- the flagged divergence survives (R-flagged)

The `update` run changed **only** what the user named -- one clause in `## Components`, which is
**not** the flagged `## Boundaries` divergence.

**(i) the Q&A entry is byte-identical**

```
sha256 of the ### Q7 block, before -> after:  identical
Status: still Pending          git diff .aid/knowledge/STATE.md:  0 changed lines
```

**(ii) the destination diff touches only what the user named**

```
-Two components: a reader and a writer. The reader is read-only; the writer owns every mutation.
+Two components: a reader and a writer. Each is a separate process. The reader is read-only; ...
```

Every other region byte-identical: the `## Boundaries` region (the flagged one) and the
frontmatter region both hash the same before and after. `source:` stayed `forward-authored`;
`approved_at_commit:` unwritten and unrestamped.

**(iii) after the `/aid-housekeep` re-run the entry is still present**

The document is `forward-authored`, so KB-DELTA took the **Conformance Lane** (code -> design
shadow-extract) rather than the brownfield doc <- code path. It re-detected the same divergence,
found it already recorded as Q7 with choice `[3]`, and left it exactly as it stood -- appending
no duplicate for an already-recorded, still-deferred divergence.

```
Q7 still present: 1     byte-identical across the housekeep run: TRUE     still Pending: 1
forward-authored doc byte-unchanged by the housekeep run: TRUE
NOT silently reconciled: 'contradiction' still recorded, and ## Boundaries still says
                         "share a schema and nothing else"
```

**V23 PASS.** An `update` that silently "fixed" the divergence would defeat the lane; resolving
it is human by the lane's design, and this row asserts precisely that it does **not** happen.

## 6. Allocation, run counts, isolation, teardown

| Run | Work folder | `phase` |
|---|---|---|
| `/aid-update-architecture` run 1 (R-ask) | `work-001-update-architecture` | `Describe` |
| `/aid-update-architecture` run 2 (R-ask) | `work-002-update-architecture` | `Describe` |
| `/aid-update-architecture` run 3 (R-flagged) | `work-001-update-architecture` | `Describe` |

Recorded before teardown. The AC's `grep -c '^phase: .' -> 0` form is the same
**unsatisfiable-by-construction** oracle logged under task-040 and task-045:
`work-state-template.yml:103` ships a literal `phase: Describe`. Satisfied in its checkable form
-- no run advanced or set `phase`; the value is the template's, untouched -- and all four bodies
declare `phase` is not driven.

**Three authored `update` runs and one `/aid-housekeep` run, and no more** (3 work folders across
the whole scratch root). A replay over the same inputs produced a byte-identical `.aid/` tree.

```
$ git status --porcelain .aid/knowledge/ .aid/design/ .aid/settings.yml .aid/works/ \
      profiles/ .claude/ .cursor/ | wc -l
705       # identical before and after -- task-039's live render, nothing else
$ git diff --cached --name-only          # (empty)
$ git diff --exit-code -- tests/ site/scripts/__tests__/    # clean
```

No `git add -A` / `git add .` / `git add -u` / `git commit -a` while task-039's render is live.
It rendered nothing and reverted nothing. The `mktemp -d` root and every copy under it are
removed on completion, including on failure.
