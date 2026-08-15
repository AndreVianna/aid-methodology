# task-049 EVIDENCE -- static and greppable verification sweep over the finished twenty-seven

The delivery's leaf, run **after** task-048 so that it audits a clean tree
(`git status --porcelain` over the ten audited paths: **0 entries** at the start). It writes
nothing. Closes BLUEPRINT criteria 1, 2, 6's static half, 8, 9, 10 and 11.

## 0. A correction that changes six results: the local `master` ref was 100 commits stale

Many rows here are phrased `git diff master -- <path>`, which is measured against **whatever
`master` points to locally**. In this worktree it pointed 100 commits behind:

```
local master:   75039593  (2026-08-13)
origin/master:  a70316c6  (2026-08-14)
$ git rev-list master..origin/master --count      -> 100
$ git rev-list HEAD..origin/master --count        -> 0     # HEAD fully contains origin/master
```

Run against the stale ref, six assertions read as **failures that are actually clean** -- the
engine showed `+130/-81` across 22 hunks instead of its true `+9/-0` across 2, and
`git diff master -- tests/` showed 33153 lines instead of **0**. Every diff row below is
therefore stated against **`origin/master`**, and the gate should re-run them the same way.
Logged `[MEDIUM]`.

## 1. BLUEPRINT criterion 1 -- twenty-seven directories and twenty-seven complete rows

```
$ ls -d canonical/skills/aid-design-{api,ui,...,dashboard} canonical/skills/aid-brainstorm \
        canonical/skills/aid-design-{architecture,stack,testing-strategy,cicd} \
        canonical/skills/aid-{create,update}-{architecture,stack,testing-strategy,cicd}
27 lines, exit 0                                          # feature-004 V1, feature-005 V1
```

| Row-count oracle | Expected | Got |
|---|---|---|
| `^  - name: aid-(design\|create\|update)-(architecture\|stack\|testing-strategy\|cicd)$` | 12 | **12** (feature-004 V2) |
| `^  - name: (aid-brainstorm\|aid-design-(api\|...\|dashboard))$` | 15 | **15** |
| total | 27 | **27** |

For all twenty-seven, **frontmatter `name:` == directory name == row `name`** -- checked per
directory, zero mismatches.

## 2. Catalog field invariants, stated count-free

**`alias_of: null` on every row** (feature-005 V4):

```
$ [ "$(grep -c '^    alias_of: null$' "$C")" = "$(grep -c '^  - name:' "$C")" ]
94 == 94   PASS
```

It holds at any row count, and fails if any row omits, misspells or aliases the field.
`test-catalog-dirs-parity.sh` is deliberately **not** used as the oracle here (`alias_of` is dead
input there, parsed and never asserted), and `DMR31`/`DMR32` are count-bearing and are
delivery-003's.

**`repurpose: true` on all twenty-seven, asserted so the emitting count cannot move.** The
count-free form of *"the `shortcuts` (emitting) quantity does not move"*:

```
rows carrying NO repurpose key:  HEAD = 34,  origin/master = 34
$ comm -3 <sorted HEAD list> <sorted origin/master list>     -> 0 lines
all 27 new rows carry `repurpose: true`                      -> 27/27
```

Every row this work adds is hand-authored, so a row that lost the key would surface in that
diff. No expected integer is stated -- the integers are delivery-003's.

## 3. BLUEPRINT criterion 2 / feature-005 V2, V17 -- the grid selection is exactly the paired set

feature-005 §2's derivation, run against the pinned pre-work catalog:

```
$ git show origin/master:canonical/aid/templates/shortcut-catalog.yml > /tmp/master-catalog.yml
   rows: 58                                        # the SPEC pins it at 58 -- confirmed
$ <§2's python derivation> /tmp/master-catalog.yml
api cli config dashboard data-model data-pipeline document infra integration job messaging
test theme ui                                      # 14
$ comm -3 <that, sorted> <this work's 14 design GRID artifacts, sorted>
                                                   # empty, BOTH directions -- PASS
```

The fourteen include **no** row for `architecture`, `stack`, `testing-strategy` or `cicd` --
those are feature-004's four.

**Every number the SPEC predicts is confirmed exactly**, which is what makes the selection
checkable rather than trusted:

| SPEC claim | Confirmed |
|---|---|
| pre-work catalog is 58 rows | 58 |
| the derivation over it returns 14 | 14 |
| the *unfiltered* intersection returns 15, the extra being the empty string | 15 |
| re-running over the **finished** catalog returns 21, not 14 | **21** |
| total `aid-design` rows = 1 bare + 14 grid + 3 planning + 4 foundation | **22 = 22** |

The 21 is worth stating plainly: it is not a defect, it is CC-7's figure. Features 003 and 004
add three and four `create`/`update` pairs respectively, so the uniformity claim ("every
artifact with a `create`/`update` pair has a `design` stage") is true of the **work**, while
*this feature* owns exactly fourteen of the rows that make it true.

**CC-8 -- no exclusion rule is asserted anywhere:**

```
$ grep -rniE 'unpaired' canonical/skills/ canonical/aid/templates/     -> 0 hits
```

The selection is stated positively wherever it is stated at all.

**feature-005 V18 -- `kb` and the ticket skills stay outside the catalog:**

```
$ grep -cE '^  - name: (aid-update-kb|aid-(read|create|update)-ticket)$' "$C"   -> 0
```

Anchored on the row form on purpose: the catalog does mention `aid-update-kb` in a comment
(1 hit), which an unanchored grep would wrongly catch.

## 4. feature-005 V3 -- the parity suite is green, unmodified

```
$ bash tests/canonical/test-catalog-dirs-parity.sh                     PASS
$ git diff origin/master -- tests/canonical/test-catalog-dirs-parity.sh   0 lines
```

It is count-agnostic by design (holds no expected total), so it extends by data with no edit,
and it asserts `CDP{i}a` / `CDP{i}c` / `CDP{i}d` for every row.

## 5. feature-005 V5, V6 / BLUEPRINT criterion 10 / feature-002 G1 -- bare `/aid-design`

```
$ grep -c 'architecture sketch' canonical/skills/aid-design/SKILL.md    -> 0
   (in the description: 0; in the argument-hint: 0 -- both sites, as §7a requires)
$ git diff origin/master -- canonical/skills/aid-design/SKILL.md
   2 hunks, starting at lines 4 and 14
   frontmatter block: lines 1-17          -> both hunks confined to it
   DESIGN.md sites:  66, 77, 89, 108      -> no hunk touches any of them
```

A whole-file `--exit-code` diff would be the wrong shape and unsatisfiable by construction; the
scoped hunk read is the right one, and it is re-asserted here rather than trusted from task-028
because this is the delivery's one shipped-behavior claim that a wrong edit would silently break.

It now reads as a **catch-all** that routes away from itself, quoted:

> Produce a KEPT design artifact NOW **for a subject with no dedicated `design` row** [...]
> **This is the catch-all: when a dedicated `/aid-design-<artifact>` row exists for the subject,
> use that row instead.**

## 6. feature-005 V7, V8, V9 -- the three pairs this feature owns are mutual

Every hit inside the file's frontmatter `description:` block:

| Pair | Forward | Back |
|---|---|---|
| `aid-research` <-> `aid-brainstorm` | 1 | 1 |
| `aid-prototype-ui` <-> `aid-design-ui` | 1 | 1 |
| `aid-design-document` -> `aid-document` + `aid-create-document` | 1 + 1 | 1 and 1 |

And V8's kept-versus-throwaway distinction is stated on **both** sides, not just asserted:

- `aid-design-ui`: *"For a **THROWAWAY** low-fidelity mock that merely validates a UX direction
  rather than a kept design, use `/aid-prototype-ui` instead."*
- `aid-prototype-ui`: *"For a **KEPT** UI design meant to inform the real build rather than a
  throwaway to validate a direction, use `/aid-design-ui` instead."*

## 7. BLUEPRINT criterion 9 / feature-005 V10 + feature-004 V15 -- both directions, every side

**Forward** -- every neighbour the assignment tables assign appears in that skill's
`description:`. All 32 sides this delivery wrote:

| Group | Sides | Missing |
|---|---|---|
| feature-004 §10, the twelve foundation sides | 12 | **none** |
| feature-005 §7c, all 14 `design` rows -> `/aid-create-<artifact>` | 14 | **none** |
| §7c's additional routes (`design-ui`, `design-test`, `design-config`, `design-infra`, `design-document`, `brainstorm`) | 6 | **none** |
| §7b's five shipped edits (`aid-design` bare, `aid-research`, `aid-prototype-ui`, `aid-document`, `aid-create-document`) | 5 | **none** |

**Reverse** -- no description names a neighbour its table does *not* assign. Every `/aid-*` token
in each of the twelve foundation descriptions and each of the fourteen `design` descriptions was
extracted and diffed against that skill's assigned set: **zero unassigned neighbours anywhere**.
The whole-set pair check across all thirty-six is delivery-003's (feature-006 §8a), not this
task's.

## 8. feature-004 V22 and V24

**V22 -- lane disclosure**, hit inside the frontmatter `description:` block:

| Body | `Conformance Lane` |
|---|---|
| `aid-create-architecture` | 1 |
| `aid-create-stack` | 1 |
| `aid-create-testing-strategy` | 1 |
| `aid-create-cicd` | 1 |

**V24 -- `testing-strategy` and `test` are two artifacts:** rows with `artifact: testing-strategy`
-> 3, rows with `artifact: test` -> 3, `grep -c 'artifact: test-strategy'` -> **0**, and
`canonical/skills/aid-create-test/` and `canonical/skills/aid-create-testing-strategy/` are
distinct directories.

## 9. feature-004 V12 -- `quality-gates.md` on all four CC-4 surfaces, together

| Surface | Oracle | Result |
|---|---|---|
| 1. `domain-doc-matrix.md` | rows + concern id | 3 rows, **all C6** |
| 2. `concern-model.md` | hit + concern id | 1, **C6** |
| 3. `document-expectations.md` (**no-edit**) | `grep -c '^### quality-gates.md'` | **1** |
| 4a. `kb-actback-task.sh` (**no-edit**) | `grep -c` >= 1 | 1 |
| 4b. `kb-dual-intent-probes.sh` (**no-edit**) | `grep -c` >= 1 | 1 |

`git diff origin/master -- tests/canonical/test-domain-doc-matrix.sh` -> **0 lines** (unmodified).
The suite itself does **not** run green in this environment -- see §11.

## 10. feature-004 V13 / BLUEPRINT criterion 8 -- no seed-count assertion moved

```
$ ls canonical/aid/templates/knowledge-base/*.md | wc -l      -> 14
```

`git diff origin/master --` is **0 lines** on every named file:
`test-kb-template-authoring-standard.sh`, `test-doc-set-read.sh`, `test-doc-set-mapping.sh`,
`test-domain-doc-matrix.sh`, `test-spine-depth-coverage.sh`, and
`aid-discover/references/doc-set-resolve.md`. No file was added under
`canonical/aid/templates/knowledge-base/`.

**feature-004 V25's static half.** The AC names `work-state-template.md`, which **no longer
exists** -- it migrated to `work-state-template.yml` upstream. Read against the file that
actually exists: `git diff origin/master -- canonical/aid/templates/work-state-template.yml` ->
**0 lines**. The row's substance (this work did not touch the work-state template) holds; the
path in the oracle is stale. Logged `[LOW]`. The behavioral half was recorded per run by
task-040 through task-047.

## 11. The two suites that do not run green here -- environment, not this work

`test-domain-doc-matrix.sh` (MT01/MT02) and `test-doc-set-mapping.sh` (T15) fail. Diagnosed
rather than assumed:

```
$ awk -W version                 -> mawk 1.3.4 20240123
$ command -v gawk                -> not installed
   failure text: "awk: line 14: syntax error at or near ,"
```

And confirmed **pre-existing** by running both in a detached worktree at `master`: *both fail
there with the identical failure*. Both are byte-unmodified by this work (0 diff lines). This is
the `[MEDIUM]` environment finding already logged for delivery-002; V13's "all five green"
conjunct is unsatisfiable in this VM for two of the five, for a reason outside the delivery.
The other three -- `test-kb-template-authoring-standard`, `test-doc-set-read`,
`test-spine-depth-coverage` -- **PASS**.

## 12. BLUEPRINT criterion 11 -- the twenty-seven bind the contract rather than forking it

**(a) feature-005 V15** -- `grep -L 'canonical/aid/templates/design-lifecycle.md'` over all
twenty-seven `SKILL.md` files produces **empty** output: every one binds the shared contract.

**(b) feature-005 V16** -- no body restates the contract's rules: bodies re-listing the seed
headings **0**, re-listing the allocation steps **0**, redefining verify depth **0**.

**(c)** each of the eighteen `design` bodies scopes its write to the seed and disclaims the rest
-- *"The seed it writes is `.aid/design/<artifact>.md`"* **18/18** (each naming its own path),
and *"Never writes `.aid/knowledge/`"* **18/18** (the four foundation bodies use a comma where
the grid bodies use "and"; both say it). Bodies driving a `phase:` value: **0**; bodies
declaring `phase` is not driven: **27/27**.

**(d)** each of the four `update` bodies carries the derived-outputs prompt as an unconditional
step storing no answer -- **4/4** (asserted in depth by task-046 §1).

## 13. feature-005 V12, V13 -- the engine read, statically

```
$ grep -c '\.aid/design/{artifact}\.md' canonical/aid/templates/shortcut-engine.md   -> 1
$ grep -l '\.aid/design/document\.md' <the two document bodies>                      -> both
$ git diff --numstat origin/master -- canonical/aid/templates/shortcut-engine.md
   +9 / -0        hunks: 2
```

**0 deletions, additions in exactly two hunks** -- exactly as V13 specifies. This is the row the
stale `master` ref corrupted worst (`+130/-81`, 22 hunks); against `origin/master` it passes
precisely.

## 14. feature-005 V19 -- the `brainstorm` family renders, as a reading

`aid-brainstorm` is **absent** from `CURATED_GROUPS` in `site/scripts/skills/groups.mjs`, its
catalog row is present (1), and that file derives families by walking `catalog.rows` in file
order (3 references). So a one-card section appears with **no code change**. The run-time oracle
is delivery-003's site guard, not this task's.

## 15. The three instruments -- deliberately NOT run and NOT edited

| Instrument | Why not run here | Diff vs `origin/master` |
|---|---|---|
| `test-deploy-monitor-repurpose.sh` | `DMR30`/`DMR31`/`DMR32`/`DMR33` are aggregates (`TOTAL_ROWS`/`CANONICAL_ROWS == 58`, `REPURPOSE_ROWS == 24`) over the finished thirty-six | **0 lines** |
| `check-skill-counts.mjs` | repo-wide count guard; **retired upstream** -- absent on `origin/master` too | **0 lines** |
| `tests/coverage-baseline.tsv` | gains 144 rows; CI-only re-bootstrap | **0 lines** |

Each would report a **correct** mid-work state as a failure, and editing any of them here would
move a ratchet delivery-003 owns. Decisively confirmed in one line:

```
$ git diff origin/master -- tests/      -> 0 lines
```

This work changed **nothing** under `tests/`, which satisfies both this criterion and
feature-001 AC-3 (no test script authored, no bash assertion id added).

## 16. This task wrote nothing

```
$ git status --porcelain canonical/ .aid/knowledge/ .aid/design/ .aid/settings.yml \
      .aid/works/ profiles/ .claude/ .cursor/ tests/ site/scripts/__tests__/
0 entries          # identical before and after
$ git diff --cached --name-only     # (empty)
```

Every row is a grep, a diff, a `comm` or a named suite over committed content, so two executions
produce identical outcomes and there is nothing to tear down.
