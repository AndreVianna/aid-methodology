# task-020 -- EVIDENCE

Durable record of the seed-immobility and registration audit. Every oracle this task's
`DETAIL.md § Scope` names appears below with **the command that produced it** and **its
observed output, verbatim**. Nothing is reported as covered without its oracle and result,
and nothing is summarized in place of its returned value.

This task authored no test script and minted no assertion id -- both are out of scope per
§ Scope, and detecting a violation of that is the reason this task exists (feature-001 AC-3).
It edited no skill, template, SPEC or Knowledge Base document. Drivers and captured stdout
live under `.aid/.temp/task-020/` (gitignored); this file is the durable record.

**Execution environment.** All bash oracles ran under **Git Bash**
(`C:\Program Files\Git\bin\bash.exe`, `MINGW64_NT-10.0-26200`), not WSL bash: WSL cannot
resolve this worktree's gitdir and returns `fatal: not a git repository` (the already-filed
`W1-10` in `.aid/knowledge/tech-debt.md`). Node `v24.19.0` / npm `11.6.2`; `site/node_modules`
was absent, so `npm ci --no-audit --no-fund` ran first (`rc=0`, 603 packages, 29s) --
`site/node_modules/` is gitignored (`site/.gitignore:1`) and leaves no residue.

**One oracle correction applied, and stated as applied.** AC-2's `find` oracle is used in the
**narrowed** form scoped to the template tree (cross-phase Q8, already resolved into the
SPEC's own Change Log row of 2026-08-10):
`find canonical/aid/templates -type f \( -iname '*roadmap*' -o -iname '*backlog*' -o -iname '*release-tracking*' \)`.
The broad form is retired because `-iname` matches basenames anywhere and now returns the six
`canonical/skills/aid-*-{roadmap,backlog}` directories feature-003 legitimately creates. §2
below records **both** forms so the correction is verifiable rather than asserted.

---

## 1. Headline result

| | |
|---|---|
| Oracles run | 6 of 6 (five bash suites + one vitest spec), plus AC-2/AC-4/AC-10/AC-12/AC-5 and V18/V20 |
| Green | **5 of 6.** All five bash suites pass unmodified, at 405 assertions total, 0 failed |
| Red | **1 of 6.** `npx vitest run gen-reference` -> `1 failed | 37 passed (38)`. The single failure is the **idempotency drift-check**, not a count-bearing assertion |
| Seed immobility | **UNMOVED.** `TEMPLATE_COUNT == 14`, 14 files under `canonical/aid/templates/knowledge-base/`, that subtree byte-identical to `master`, all five `toHaveLength` values unmoved, ownership map free of all three documents |
| Registration | **All three documents registered as conditional, none as seeded** -- verified on all four CC-4 surfaces |
| Tree | **Clean before and after** (`git status --porcelain` = 0 lines both times) |
| Unsatisfiable criterion | AC-3's whole-spec-green conjunct, at this scheduling point. `IMPEDIMENT.md` filed beside this file |

---

## 2. Acceptance criterion -> oracle -> observed output -> verdict

### AC-3 conjunct 1 -- the five bash suites, green **unmodified**

Counts read from **each script's own summary line**, never from a grep over stdout
(the DETAIL's second criterion). Each suite run **individually** with no timeout, which is
the measurement `W4-3` in `tech-debt.md` distinguishes from the contended `run-all.sh` figure.

| Suite | Named assertions | `rc` | Summary line | Elapsed | Verdict |
|---|---|---|---|---|---|
| `tests/canonical/test-kb-template-authoring-standard.sh` | AS06 (`TEMPLATE_COUNT == 14`) | 0 | `Tests passed: 134` / `Tests failed: 0` | 24s | PASS |
| `tests/canonical/test-doc-set-read.sh` | T02 | 0 | `Tests passed: 48` / `Tests failed: 0` | 15s | PASS |
| `tests/canonical/test-doc-set-mapping.sh` | T02 | 0 | `Tests passed: 21` / `Tests failed: 0` | 9s | PASS |
| `tests/canonical/test-domain-doc-matrix.sh` | MT01, MT02, MT06, MT17 | 0 | `Tests passed: 37` / `Tests failed: 0` | 23s | PASS |
| `tests/canonical/test-spine-depth-coverage.sh` | SD04, SD05, SD07 | 0 | `Tests passed: 165` / `Tests failed: 0` | 34s | PASS |

Total **405 passed, 0 failed**. Verbatim tail of each capture (all five are 7 lines; the
suites print failures only, so a green run is summary-only):

```
== test-kb-template-authoring-standard.sh ==

=== Summary ===
  Tests passed: 134
  Tests failed: 0

All tests passed.
```

**`Tests failed: 0` is sufficient to cover each named assertion id, and that was verified
rather than assumed:** none of the five suites has any SKIP mechanism --
`grep -c SKIP` over all five returns `0`, `0`, `0`, `0`, `0`. There is therefore no path by
which a named id is neither passed nor failed. Each id was also confirmed present and live:

```
test-kb-template-authoring-standard.sh:56  assert_eq "$TEMPLATE_COUNT" "14" \
test-kb-template-authoring-standard.sh:57    "AS06 exactly 14 knowledge-base template files present (synth_default_seed count)"
test-doc-set-read.sh:192      assert_eq "$seed_count" "$template_count" "T02 default seed row-count matches template count ($template_count)"
test-doc-set-mapping.sh:220     "T02 declared count is default($default_count) - 1 = $expected_count after omission"
test-domain-doc-matrix.sh:157   "MT01 software-cli required doc count == seed count ($SEED_COUNT)"
test-domain-doc-matrix.sh:161    "MT01 software-cli required docs == synth_default_seed filenames (byte-exact)"
test-domain-doc-matrix.sh:169   "MT02 software-web required doc count == seed count ($SEED_COUNT)"
test-domain-doc-matrix.sh:173    "MT02 software-web required docs == synth_default_seed filenames (byte-exact)"
test-domain-doc-matrix.sh:217    "MT06 Seed-consistency table has exactly 14 numbered rows"
test-domain-doc-matrix.sh:285    "MT17 Seed-consistency section mentions decisions.md"
test-domain-doc-matrix.sh:288    "MT17 Seed-consistency section states decisions.md is NOT part of the seed"
test-spine-depth-coverage.sh:169   pass "SD04 ${fname} -> ${dim}: dimension block present"
test-spine-depth-coverage.sh:176   pass "SD05 ${fname} -> ${dim}: dimension block non-empty"
test-spine-depth-coverage.sh:209   pass "SD07 matrix emittable doc count is ${EMITTABLE_COUNT} (>= 58)"
```

**Verdict: PASS.**

### AC-3 conjunct 2 -- the vitest spec, green **unmodified**

Oracle: `npx vitest run gen-reference` from `site/`.

```
 RUN  v4.1.8 C:/Projects/Personal/AID/.claude/worktrees/work-006-design-phase-skills/site

 ❯ scripts/__tests__/gen-reference.test.mjs (38 tests | 1 failed) 434ms
     × running gen:reference again produces no diff on the owned files 406ms

 FAIL  scripts/__tests__/gen-reference.test.mjs > gen-reference: idempotency (drift-check) > running gen:reference again produces no diff on the owned files
Error: Drift detected after re-running gen:reference. Diff output:
diff --git a/site/src/content/docs/reference/settings.md ...
-| `knowledge.doc_set` | ... README.md|skill-self|required` | Installed AI host tools |
+| `knowledge.doc_set` | ... README.md|skill-self|required, roadmap.md|skill-self|required, backlog.md|skill-self|required` | Installed AI host tools |
diff --git a/site/src/content/docs/reference/skills.md ...
-The full roster — all **76** skills ...
+The full roster — all **85** skills ...
-... one non-`repurpose` row of shortcut-catalog.yml (58 rows total; the other 24 are `repurpose: true` ...
+... one non-`repurpose` row of shortcut-catalog.yml (67 rows total; the other 33 are `repurpose: true` ...

 Test Files  1 failed (1)
      Tests  1 failed | 37 passed (38)
```

`rc=1`. **Verdict: FAIL** -- recorded as a finding, not weakened. Analysis in §6; the
criterion is unsatisfiable at this scheduling point, so `IMPEDIMENT.md` is filed.

**What the failure is NOT.** The spec was **not edited** (`git diff --quiet master --
site/scripts/__tests__/gen-reference.test.mjs` -> EMPTY, and the working-tree clean-diff below
is rc=0), and no count-bearing assertion in it moved. The one failing test is an
idempotency/drift check over **generated site content**; the seed assertion in the same file
(`kb.md: exactly 14 KB doc-type rows matching canonical/aid/templates/knowledge-base/`,
`:257-266`, carrying two of the five `toHaveLength` calls) is among the 37 that passed.

### AC-3 conjunct 3 -- `git diff --exit-code -- tests/canonical/ site/scripts/__tests__/`

```
$ git diff --exit-code -- tests/canonical/ site/scripts/__tests__/
rc=0
```

Clean. Scoped to the suite scripts, never the files under test -- `domain-doc-matrix.md` and
`document-expectations.md` are inputs those suites read and are edited by this delivery, so a
diff assertion over their files would be unsatisfiable by construction (AC-3 says so itself).

Strengthened with a second, independent form -- **each of the six oracle files against
`master`**, which the working-tree diff cannot see:

```
EMPTY  tests/canonical/test-kb-template-authoring-standard.sh
EMPTY  tests/canonical/test-doc-set-read.sh
EMPTY  tests/canonical/test-doc-set-mapping.sh
EMPTY  tests/canonical/test-domain-doc-matrix.sh
EMPTY  tests/canonical/test-spine-depth-coverage.sh
EMPTY  site/scripts/__tests__/gen-reference.test.mjs
```

(`master` = `75039593`; it is **not** an ancestor of `HEAD` -- merge-base `9260fc88` -- so the
five other files `git diff --stat master -- tests/canonical/` reports are master-side commits
this branch has not merged, not edits by this work. None of them is one of the six.)

**Verdict: PASS.**

### The `toHaveLength` criterion -- none of the three quantities moves

Oracle: read all five calls, and diff the file against `master`.

```
site/scripts/__tests__/gen-reference.test.mjs:250:    expect(agentDirs).toHaveLength(9);
site/scripts/__tests__/gen-reference.test.mjs:254:    expect(sections).toHaveLength(9);
site/scripts/__tests__/gen-reference.test.mjs:260:    expect(kbFiles).toHaveLength(14);
site/scripts/__tests__/gen-reference.test.mjs:265:    expect(rows).toHaveLength(14);
site/scripts/__tests__/gen-reference.test.mjs:363:    expect(manifest.entries).toHaveLength(4);
```

Values `9, 9, 14, 14, 4`; file EMPTY against `master`; the KB-doc-template test that carries
`toHaveLength(14)` at `:260` passed. **Verdict: PASS.**

### AC-2 -- conditional admission, all three documents

**Oracle 1 (narrowed, per the Q8 correction):**

```
$ find canonical/aid/templates -type f \( -iname '*roadmap*' -o -iname '*backlog*' -o -iname '*release-tracking*' \)
[0 hits -- no output]
```

**The broad form, run for contrast, to show why the narrowing is the correct oracle and not a
weakening:**

```
$ find canonical -iname '*roadmap*' -o -iname '*backlog*' -o -iname '*release-tracking*'
canonical/skills/aid-create-backlog
canonical/skills/aid-create-roadmap
canonical/skills/aid-design-backlog
canonical/skills/aid-design-roadmap
canonical/skills/aid-update-backlog
canonical/skills/aid-update-roadmap
[6 hits]
```

Exactly the six skill **directories** feature-003 legitimately creates -- not a file, not a
template, and not under `canonical/aid/templates/`. The criterion text is *"None has a file
anywhere under `canonical/aid/templates/`"*, which the narrowed form asserts and the broad
form contradicts.

**Oracle 2 -- 8 matrix rows per document:**

```
roadmap.md          8
backlog.md          8
release-tracking.md 8
```

(`awk '/^### Domain:/{d=1} d' canonical/aid/templates/kb-authoring/domain-doc-matrix.md | grep -c '^| \`<doc>\`'`)

**Verdict: PASS.**

### AC-4 -- none of the three enters `synth_default_seed`'s ownership map

Oracle (anchor-scoped `awk` over the two ownership-map regions of
`canonical/skills/aid-discover/references/doc-set-resolve.md`, then `grep -cE`):

```
roadmap.md|backlog.md|release-tracking.md  ->  0
```

Positive control, same command with `tech-debt.md` -- proving the extractor selects **both**
copies rather than returning 0 because it selected nothing:

```
tech-debt.md  ->  2
```

**Verdict: PASS.** This is the row (feature-001 §5 row 7) discharged here.

### AC-10 -- the filename->dimension map resolves all three, in both twins

Oracle: extract `_dim_of_filename` from each twin and evaluate it (the function is not
exported, the twins use different output globals, and both scripts invoke `_main` at load).

```
kb-actback-task roadmap.md -> D
kb-actback-task backlog.md -> C7
kb-actback-task release-tracking.md -> C8
kb-dual-intent-probes roadmap.md -> D
kb-dual-intent-probes backlog.md -> C7
kb-dual-intent-probes release-tracking.md -> C8
```

Six lines, `D` / `C7` / `C8`, identical across the two twins, no empty dimension.
**Verdict: PASS.**

### AC-12 -- the matrix's own conditional tallies still describe the matrix

Oracle 1 -- counted conditional rows in the `software-cli` domain:

```
4
```

The four rows themselves, recorded because the count alone cannot show that the
`decisions.md` bullet was **added beside** rather than replaced:

```
| `decisions.md` | D | `aid-researcher-architecture` | conditional:project has recorded rationale-bearing decisions |
| `roadmap.md` | D | `skill-self` | conditional:project maintains a forward plan |
| `backlog.md` | C7 | `skill-self` | conditional:project maintains a defined-and-prioritized backlog |
| `release-tracking.md` | C8 | `skill-self` | conditional:project cuts versioned releases and records what shipped in each |
```

Oracle 2 -- the prose tally agrees and names all four:

```
$ grep -n '4 conditional' canonical/aid/templates/kb-authoring/domain-doc-matrix.md
154:14 required docs (the seed) + 4 conditional (`decisions.md`, `roadmap.md`, `backlog.md`,
```

The SPEC cites this tally at `:148`; it now sits at `:154` because the edit added lines above
it. The line's **content** is what the criterion asserts, and it holds. MT17 green (above) is
the independent check that the Seed-consistency section still carries both `decisions.md` and
`NOT`. **Verdict: PASS.**

### AC-5 -- C-3 compliance of the two new instances

Oracle: `grep -cE '^## (Change Log|Revision History)|^changelog:|work-[0-9]{3}'`

```
.aid/knowledge/roadmap.md:0
.aid/knowledge/backlog.md:0
```

`release-tracking.md` is out of this criterion's scope by the SPEC (§4c: it legitimately
carries work references as release history). **Verdict: PASS.**

---

## 3. feature-003 V18 and V20 -- the item-uniqueness rows

### The promotion question, answered from disk

`task-021/STATE.md`'s `notes:` frontmatter is `--`, so the promotion outcome its own
acceptance criteria required was **not recorded there**. It was therefore established from
git, which answers the question the DETAIL asks (*"whether this repository's own `backlog.md`
carries no promoted row"*) directly:

```
$ git log --oneline -S"W5-20" -- .aid/knowledge/tech-debt.md .aid/knowledge/backlog.md .aid/knowledge/release-tracking.md
7c284ecc docs(work-006): file W5-20 -- refused and routed runs leave an allocated work folder and worktree

$ git log --oneline -S"W5-21" -- .aid/knowledge/tech-debt.md .aid/knowledge/backlog.md .aid/knowledge/release-tracking.md
3a1c6077 docs(work-006 task-018): retire ## Unreleased, moving its item into backlog.md

$ git show 9260fc88:.aid/knowledge/tech-debt.md | grep -c "W5-20"   ->  0
```

**Neither of `backlog.md`'s two ids is a promotion from `tech-debt.md`.** `W5-20` was filed
directly into `backlog.md`; `W5-21` arrived from `release-tracking.md`'s `## Unreleased` via
task-018's migration. So **this repository carries no promoted row**, and per § Scope a
fixture in which one promotion has been performed was constructed and both rows run against
it as well.

### Live run -- against the KB in its final state

Extractor (`ids`): column 1 of the inventory tables --
`grep -oE '^\| \*\*[A-Za-z0-9._-]+\*\* \|' | sed -E 's/^\| \*\*//; s/\*\* \|$//' | sort -u`.

| Row | Oracle | Observed | Verdict |
|---|---|---|---|
| **V18** | `comm -12 <(ids tech-debt.md) <(ids backlog.md)` | **empty** (0 shared ids) | PASS |
| V18 set sizes | `ids \| wc -l` | `tech-debt.md` = **33**, `backlog.md` = **2** -- both non-empty | PASS |
| **V20** | `grep -Fc "<id>" .aid/knowledge/roadmap.md` for every id in the union | **0 for all 35 ids** | PASS |
| V20 set size | union `\| wc -l` | **35** -- non-empty | PASS |

The 33 `tech-debt.md` ids:
`L4 W1-1 W1-10 W1-11 W1-12 W1-13 W1-14 W1-15 W1-17 W1-2 W1-3 W1-5 W1-6 W1-7 W1-8 W1-9 W4-3
W4-5 W5-1 W5-10 W5-12 W5-13 W5-14 W5-16 W5-19 W5-2 W5-22 W5-23 W5-3 W5-4 W5-5 W5-6 W5-7`.
The 2 `backlog.md` ids: `W5-20 W5-21`. Union = 35 (disjoint, which is V18's result).

**Both rows read the KB after task-018's migration and task-019's regeneration** -- the final
state -- and beside no concurrent writer: this task writes nothing under `.aid/knowledge/`, and
`git status --porcelain` was 0 lines throughout. Ordering confirmed in git:
`3a1c6077` (task-018) and `8f7a378a` (task-019) both precede `HEAD`.

### Fixture run -- so that neither row is trivially green

Driver: `.aid/.temp/task-020/v18-v20-fixture.sh`. Fixture root created with `mktemp -d` and
removed by a `trap ... EXIT INT TERM` (so also on failure), then confirmed absent.
One promotion performed: `W5-19` **moved** from `tech-debt.md` into `backlog.md`, id unchanged.

```
fixture root: /tmp/tmp.vHw9enCJcr
promoting id: W5-19

=========== F-promoted (correct MOVE -- both rows must PASS) ===========
--- V18 [F-promoted] ---
tech-debt id set size: 32
backlog   id set size: 3
comm -12: EMPTY
--- V20 [F-promoted] ---
union id set size: 35
every id: grep -Fc roadmap.md -> 0

=========== F-copied (negative controls -- both rows must FAIL) ===========
--- V18 [F-copied] ---
tech-debt id set size: 33
backlog   id set size: 3
comm -12: W5-19
--- V20 [F-copied] ---
union id set size: 35
NON-ZERO: W5-1=1 W5-19=1

=========== teardown ===========
fixture removed: /tmp/tmp.vHw9enCJcr absent
```

`F-copied` is the defect each row exists to catch -- the promoted row left in **both**
documents, and its id leaked into `roadmap.md`. Both rows go red against it, so neither is
vacuously green against the live KB. **V18: PASS. V20: PASS.**

---

## 4. feature-001 §5 -- all fifteen rows accounted for

Every row is evaluated here, evaluated in an earlier task named by number, or deferred to a
delivery named by number. **Exactly three conjuncts are deferred, all to delivery-003.**
Rows 3, 11 and 12 are **not** deferred -- each has an owning task inside delivery-001.

| Row | Check | AC | Where discharged |
|---|---|---|---|
| 1 | No test script moved | AC-3 | **HERE** -- §2, conjuncts 1-3 |
| 2 | Doctrine amended -- canonical | AC-1 | task-006 |
| 3 | Doctrine amended -- dogfood | AC-1 | task-006 -- **not deferred** |
| 4 | Matrix rows + concern-model entries | AC-2 | task-007; **re-run HERE** (§2 AC-2) |
| 5 | Expectations blocks | AC-11 | task-017 |
| 6 | Dimension map resolves | AC-10 | task-008; **re-run HERE** (§2 AC-10) |
| 7 | Not in the ownership map | AC-4 | **HERE** -- §2 AC-4 |
| 8 | Matrix self-tallies | AC-12 | task-007; **re-run HERE** (§2 AC-12) |
| 9 | C-3 compliance of the two instances | AC-5 | task-015 + task-021; **re-run HERE** (§2 AC-5) |
| 10 | `## Unreleased` gone, everywhere it was described | AC-6 | hand-edited conjunct task-018; script-regenerated conjuncts task-019. **`kb.html` conjunct DEFERRED -> delivery-003** (task-071, the single `/aid-summarize` re-run) |
| 11 | Release flow rewired | AC-7 | task-009 -- **not deferred** |
| 12 | Dead Change Log instruction gone | AC-8 | task-009 -- **not deferred** |
| 13 | Manual drain documented where adopters get it | AC-9 | canonical half task-017. **five-render half DEFERRED -> delivery-003** |
| 14 | Index regenerated | AC-6 | task-019 |
| 15 | Render parity | -- | **DEFERRED -> delivery-003** |

Deferral count: **3** (row 10's `kb.html` conjunct, row 13's five-render half, row 15), all to
**delivery-003**. Ownership verified rather than assumed -- feature-006 is delivery-003's
single feature (`PLAN.md:95`), the `kb.html` regeneration is task-071
(`delivery-003/tasks/task-067/DETAIL.md:62`), and delivery-003's cross-cutting risk 5
(`PLAN.md:107`) names it *"inside delivery-003"*. **Verdict: PASS.**

---

## 5. BLUEPRINT gate criterion 5 -- the four conjuncts

*"The seed does not move: no test script under `tests/canonical/` or
`site/scripts/__tests__/` is edited, none of the three documents enters `synth_default_seed`'s
ownership map, no file is added under `canonical/aid/templates/`'s `knowledge-base/` subtree,
and every named seed-count assertion is green **unmodified**."*

| Conjunct | Oracle | Observed | Verdict |
|---|---|---|---|
| No test script edited | `git diff --exit-code -- tests/canonical/ site/scripts/__tests__/`; plus each of the six vs `master` | `rc=0`; all six `EMPTY` | PASS |
| Not in the ownership map | AC-4's anchor-scoped `awk` + `grep -c` | `0` (control `tech-debt.md` = `2`) | PASS |
| No file added under `knowledge-base/` | `find canonical/aid/templates/knowledge-base -type f \| wc -l`; `git diff --name-status master -- canonical/aid/templates/knowledge-base/` | `14`; **0 lines** -- the subtree is byte-identical to `master` | PASS |
| Every named seed-count assertion green unmodified | AS06, both T02s, MT01/MT02/MT06/MT17, SD04/SD05/SD07, `toHaveLength(14)` | all green, 405 bash assertions + the KB-doc-template vitest test | PASS |

**Criterion 5's substance holds in full.** The one red assertion in the work is not a
seed-count assertion; see §6.

---

## 6. The one FAIL, and why no correct delivery-001 implementation can clear it

The failing test is `gen-reference: idempotency (drift-check) > running gen:reference again
produces no diff on the owned files`. It re-runs `npm run gen:reference` and diffs the
regenerated pages against the committed ones. Two committed pages are stale:

| Page | Stale value | Regenerated value | Cause |
|---|---|---|---|
| `site/src/content/docs/reference/settings.md` | `knowledge.doc_set` without `roadmap.md` / `backlog.md` | with both | `.aid/settings.yml` gained the two entries (tasks 015 / 021, per CC-2) |
| `site/src/content/docs/reference/skills.md` | `76` skills; `58 rows total; the other 24 are repurpose` | `85`; `67 rows total; the other 33` | `canonical/skills/` 76 -> 85 dirs and `shortcut-catalog.yml` +72 lines / +9 rows (feature-003, tasks 010-014) |

Attribution, established rather than inferred:

```
$ git diff master -- .aid/settings.yml | grep -E '^[+-].*(roadmap|backlog)'
+    - roadmap.md|skill-self|required
+    - backlog.md|skill-self|required

$ git ls-tree -d --name-only master canonical/skills/ | wc -l   ->  76
$ git ls-tree -d --name-only HEAD   canonical/skills/ | wc -l   ->  85

$ git diff --stat master -- canonical/aid/templates/shortcut-catalog.yml
 canonical/aid/templates/shortcut-catalog.yml | 72 ++++++++++++++++++++++++++++

$ git diff --stat master -- site/src/content/docs/reference/settings.md site/src/content/docs/reference/skills.md
[empty -- both pages are byte-identical to master]
```

So every input moved in this work and **neither generated page did**. The regeneration is owned
by **delivery-003 task-064**, whose write set is exactly these files
(`PLAN.md:544`), and `PLAN.md:606` states it outright: *"deliveries 001 and 002 neither read
nor wrote either tree, and delivery-003 is the first to do both."* Confirmed against disk --
`grep -rln 'site/src/content' .aid/works/.../deliveries/delivery-001/` returns **nothing**.

**Therefore feature-001 AC-3's literal *"the one vitest spec green"* conjunct cannot be
satisfied by any correct delivery-001 implementation** at the point this task runs: § Scope
schedules it *"where every feature-001 and feature-003 edit has landed"*, and it is exactly
feature-003's landed edits that make the drift-check red, while the PLAN forbids delivery-001
from writing the files that would clear it. The criterion is not weakened here and no file was
regenerated to make it green; `IMPEDIMENT.md` is filed beside this file with options.

Note that **delivery-003 task-062 re-asserts the same oracle** (`task-062/DETAIL.md:118`) and
is ordered **before** task-064, so the same red is scheduled to recur there unless the
impediment is resolved.

---

## 7. Determinism, residue and the clean tree

**Determinism.** Every oracle was run twice.

| Oracle set | Pass 1 | Pass 2 | Identical? |
|---|---|---|---|
| Five bash suites | 134 / 48 / 21 / 37 / 165 passed, 0 failed | 134 / 48 / 21 / 37 / 165 passed, 0 failed | **yes** -- `diff -q` over each captured stdout reports no difference |
| vitest `gen-reference` | `1 failed \| 37 passed (38)` | `1 failed \| 37 passed (38)` | **yes** -- the drift hunks are byte-identical between the two runs, so the failure is a genuine drift, not flake |
| AC-2 / AC-4 / AC-10 / AC-12 / AC-5, V18, V20 | as recorded above | pure reads over committed content, re-evaluated with the same result | yes |

**Residue -- one, from an oracle rather than from this task, and it was reverted.** The vitest
idempotency test **writes**: it runs `gen:reference`, which rewrites the two tracked pages, and
because the drift is real it leaves them modified. After each of the two runs:

```
$ git status --porcelain
 M site/src/content/docs/reference/settings.md
 M site/src/content/docs/reference/skills.md

$ git checkout -- site/src/content/docs/reference/settings.md site/src/content/docs/reference/skills.md
$ git status --porcelain
[empty]
```

Restored both times. Nothing was committed from it -- regenerating those pages is task-064's,
not this task's. The V18/V20 fixture lived entirely under `mktemp -d` with a `trap` teardown and
was confirmed absent; all drivers and captures are under `.aid/.temp/` (gitignored,
`.gitignore:69`), and `site/node_modules/` is gitignored (`site/.gitignore:1`).

**Clean tree.**

| Oracle | Before the run | After the run | Verdict |
|---|---|---|---|
| `git status --porcelain` | **0 lines** | **0 lines** | identical -- PASS |
| `git status --porcelain profiles/ .claude/ .cursor/` | 0 lines | **0 lines** | PASS -- delivery-003 owns the committed render (C-5) |
| `git diff --exit-code -- tests/canonical/ site/scripts/__tests__/` | -- | `rc=0` | PASS |

---

## 8. Observations (recorded, not blocking, and not this task's to edit)

1. **`test-kb-template-authoring-standard.sh:54`'s comment contradicts the assertion two lines
   below it.** The comment reads `# AS06: exactly 15 template files present`; `:56-57` asserts
   `14`. The assertion is correct (14 files on disk, green) -- only the comment is stale, and it
   is the same 15-vs-14 drift feature-001 §2c routes to `/aid-housekeep`. Editing it here would
   violate AC-3's clean-diff.
2. **V20's oracle aliases on prefix ids.** `grep -Fc "<id>"` has no word boundary, so the
   negative-control fixture flagged `W5-1=1` purely because the injected id was `W5-19`. It does
   not affect the live verdict (all 35 counts are `0`), but any future non-zero result must be
   read as *"this id or a longer id having it as a prefix"*. A `grep -cE "\b<id>\b"` form would
   be tighter; changing it is feature-003's, not this task's.
3. **task-021's promotion outcome was never written to its `STATE.md` `notes:`** (it reads
   `--`), although task-021's own acceptance criteria required it *"so task-020 can tell whether
   V18 and V20 are able to fail"*. §3 establishes the same fact from git instead, so this task
   is not blocked; recorded because the criterion is unmet upstream.
