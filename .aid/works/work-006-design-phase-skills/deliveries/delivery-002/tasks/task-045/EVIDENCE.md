# task-045 EVIDENCE -- absent destinations created, registered in the same run, left forward-authored

Closes the **CC-2** half of BLUEPRINT criterion 7. Rows: feature-004 **V14 / AC-16**, **V20**,
**§8 / §8c** for the gate document, and **V17**'s `forward-authored` half.

## 0. Why scratch projects, and the fixtures

Not only hygiene: **this repository has no absent foundation destination.** All five --
`architecture.md`, `technology-stack.md`, `test-landscape.md`, `quality-gates.md`,
`infrastructure.md` -- are present and declared members of `.aid/settings.yml`
`knowledge.doc_set`, so the creation path is *unreachable here by construction* and needs a
project that lacks the document.

Both baselines were created under `mktemp -d`, `git init`-ed with a baseline commit (so the
`git diff` / `git status --porcelain` assertions return a real result rather than exit 128), and
carry the rendered dogfood `.claude/`.

**F-noC8** -- domain `methodology-tooling`, declared on the `- **Domain:**` line of
`.aid/knowledge/README.md` (where this repository declares its own) and **not** in
`.aid/settings.yml`, which carries `knowledge.doc_set` but no domain key. The C8 doc's absence
is **legitimate** rather than a broken fixture:

```
$ sed -n '352p' canonical/aid/templates/kb-authoring/domain-doc-matrix.md
| `infrastructure.md` | C8 | `aid-researcher-quality` | conditional:the tooling ships/runs as a deployed artifact |
```

and the shipped skill agrees, naming this exact case: *"Destination absent, this skill owning the
whole document -> create it, then register it. This arises on a `methodology-tooling` project."*
It has no `infrastructure.md`, no `infrastructure.md` doc-set entry, a README with a Completeness
table and `**Doc-set:** 5 documents`, and a **ready** `.aid/design/cicd.md`
(`## Open questions` -> `None`). `lint-frontmatter.sh` green at baseline.

**F-noGate** -- built as **`software-cli`**, not as a copy of F-noC8's domain. The DETAIL says
"the same shape", but under `methodology-tooling` the matrix marks `quality-gates.md`
**required** (`:348`), so omitting it there would be broken by construction -- the exact failure
F-noC8's own domain choice was reasoned to avoid. Under `software-cli` (`:153`) it is
`conditional:project enforces merge-blocking quality gates`, so its absence is legitimate. Owner
and concern are identical in both tables, so **no assertion changes**. Logged as a `[LOW]`
fixture-construction note. It carries no `quality-gates.md` and no doc-set entry for it, a
present populated `test-landscape.md`, and a ready `.aid/design/testing-strategy.md` whose
`## Destination` names **both** C6 halves.

**F-fwd** -- a `cp -a` snapshot of F-noC8 taken **immediately after** its `create` run *and its
commit*, so its C8 document carries a `source: forward-authored` this feature's `create`
actually produced, rather than one hand-written to look like it.

**The owner field is the doc's matrix row slot, never a blanket `skill-self`**:
`infrastructure.md` -> `aid-researcher-quality`, `quality-gates.md` -> `aid-researcher-quality`.
Writing `skill-self` for either would silently remove that document's researcher discovery
dispatches.

## 1. V14 / AC-16 -- creation registers, in the same run (R-create, a fresh copy of F-noC8)

The single `/aid-create-cicd` run was the **only** action between the baseline commit and the
diffs below; no manual edit to `.aid/settings.yml` or `.aid/knowledge/README.md` was made
(**CC-2**).

**(a) the document now exists** -- `test -f .aid/knowledge/infrastructure.md` -> TRUE

**(b) `git diff .aid/settings.yml`** -- exactly one added line, no removals:

```
$ git diff -U0 .aid/settings.yml
+    - infrastructure.md|aid-researcher-quality|required
$ git diff -U0 .aid/settings.yml | grep -c '^-[^-]'
0                       # appended INSIDE the existing doc_set list, block not rewritten (R13)
```

Presence `required` per **CC-1**; owner from the matrix row. `term_exclusions` untouched -- the
whole block from `term_exclusions:` to EOF is byte-identical before and after.

**(c) + (d) `git diff .aid/knowledge/README.md`** -- one Completeness row, and the count moves:

```
-- **Doc-set:** 5 documents
+- **Doc-set:** 6 documents
+| infrastructure.md | C8 | aid-researcher-quality | Complete (forward-authored) |
```

`Concern` is the doc's spine dimension **C8**; `Owner` is the same owner as (b). Exactly one
added row (`grep -cE '^\+\| infrastructure\.md \| C8 \| aid-researcher-quality \|'` -> 1) and
`+1` on the `**Doc-set:** N documents` line.

**V14 PASS**, all four conjuncts.

## 2. V20 -- the created document's provenance

```
$ grep -m1 '^source:'  .aid/knowledge/infrastructure.md   -> source: forward-authored
$ grep -m1 '^sources:' .aid/knowledge/infrastructure.md   -> sources: []
$ grep -c '^approved_at_commit:' .aid/knowledge/infrastructure.md   -> 0
$ bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge   -> green
```

**V20 PASS.** A non-empty `sources:` would fail -- listing code files as sources for a
forward-authored doc is forbidden.

**V21 / AC-11** -- the `## Contents` set-comparison returns empty in **both** directions
(`comm -3` of the heading set minus `Contents` against the link-text set -> 0 lines).

Boundary check on the created C8 document: no framework version
(`grep -cE '[0-9]+\.[0-9]+\.[0-9]+'` -> 0) and it **cites** `quality-gates.md` twice rather than
restating its policy. The one `grep -i 'waiver|threshold'` hit is the boundary disclaimer itself
-- *"what the gate blocks on, and any waiver rule, is the C6 gate document's policy ... Neither
is restated here."* -- which names the boundary without stating a policy.

## 3. §8 / §8c -- the gate document, created and registered in one run (R-gate, fresh F-noGate)

A single `/aid-create-testing-strategy` run:

| Assertion | Result |
|---|---|
| `.aid/knowledge/quality-gates.md` created | TRUE |
| doc-set entries added / removed | **+1 / -0**, matching `quality-gates.md\|aid-researcher-quality\|required` |
| README Completeness rows added, concern **C6**, matrix owner | exactly **1** |
| `**Doc-set:** N documents` | **5 -> 6** |
| created doc `source:` / `sources:` / `approved_at_commit:` | `forward-authored` / `[]` / absent |
| `lint-frontmatter.sh --root .aid/knowledge` | green |
| the **same run** also wrote `test-landscape.md` | 12 changed lines |

This is *"a project that runs it gets the document **and** the registration in the same run"*
(§8c), for the gate document.

**§4 boundary, over both C6 documents' diffs:**

| Document | framework versions in added lines | pipeline stage / trigger / environment / promotion |
|---|---|---|
| `quality-gates.md` | 0 | 0 |
| `test-landscape.md` | 0 | 0 |

Both documents' `## Contents` set-comparisons return 0 diffs. The gate doc records *what blocks
a merge* and the waiver rule and cites `test-landscape.md` for lane membership; the landscape doc
records the lane mapping. Neither restates the other, and neither reaches into C0 or C8.

## 4. V17, the `forward-authored` half (R-update, a fresh copy of F-fwd)

`/aid-update-cicd` revised committed C8 content (a rollback clause on the release flow):

```
source: line before -> after:   'source: forward-authored' -> 'source: forward-authored'
$ git diff .aid/knowledge/infrastructure.md | grep -cE '^[+-]source:'
0                                  # the source: line appears NOWHERE in the diff
$ git diff --numstat .aid/knowledge/infrastructure.md | cut -f1
2                                  # a real run, not a no-op
$ grep -c '^approved_at_commit:' .aid/knowledge/infrastructure.md   -> 0  (not restamped)
$ lint-frontmatter.sh --root .aid/knowledge   -> green
```

**V17 PASS for `forward-authored`.** `update` never rewrites a destination's production mode.
The `hand-authored` half was task-040's, so **V17 is closed for both values only with both
tasks** -- neither alone closes it.

## 5. Allocation, and the `phase` criterion in its satisfiable form

Recorded **before** teardown, as the AC requires. Three authored runs, each allocating inside its
own scratch project:

| Run | Work folder | `phase` |
|---|---|---|
| `/aid-create-cicd` (R-create) | `work-001-create-cicd` | `Describe` |
| `/aid-create-testing-strategy` (R-gate) | `work-001-create-testing-strategy` | `Describe` |
| `/aid-update-cicd` (R-update) | `work-002-update-cicd` | `Describe` |

The AC asks for `grep -c '^phase: .'` -> **0**. That is **unsatisfiable by construction**:

```
$ grep -n '^phase:' canonical/aid/templates/work-state-template.yml
103:phase: Describe
```

The shipped template hardcodes a phase value, so allocation makes the count 1 and **no
conforming skill can make it 0**. This is a **recurrence of task-040's finding in a second
wording**, which is what makes it a class defect in how "phase is not driven" was specified
rather than a one-off typo -- logged `[MEDIUM]` for the gate, which should retire the grep form.

Satisfied here in its checkable form, both halves:

- **Nothing drove it** -- all three runs left `phase` **byte-identical to the template default**;
  no run advanced or set it.
- **The contract says so** -- all four bodies (`aid-create-cicd`,
  `aid-create-testing-strategy`, `aid-update-cicd`, `aid-update-testing-strategy`) declare
  `phase` is not driven, and **none** routes to `/aid-execute` (0 occurrences each).

## 6. Isolation, determinism, teardown

```
$ git status --porcelain .aid/knowledge/ .aid/design/ .aid/settings.yml .aid/works/ \
      profiles/ .claude/ .cursor/ | wc -l
705       # identical before and after -- task-039's live render, and nothing else
$ git diff --cached --name-only          # (empty)
$ git diff --exit-code -- tests/ site/scripts/__tests__/    # clean
```

No `git add -A` / `git add .` / `git add -u` / `git commit -a` was used while task-039's render
is live. It rendered nothing and reverted nothing.

**Determinism.** A replay of the create-and-register mutation over the same inputs (`R-create2`)
produced a byte-identical `.aid/` tree (`diff -r` clean). `R-create2` is a **replay**, not a
fourth authored run: it allocated no work folder and ran no verify loop, which is precisely the
distinction the task draws between an authored run and a non-realizing one. **Three authored
runs and no fourth.**

The `mktemp -d` root and all six directories under it are removed on completion, including on
failure.
