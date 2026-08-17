# Delivery Record — delivery-001: The Single, Watched Stack

> **Work:** work-013-review-stack-completion
> **Delivery:** delivery-001
> **Branch:** `aid/work-013-review-stack-completion-delivery-001`

This is the delivery's evidence file. Every gate criterion pastes its command **and that
command's output** here. A conclusion without its command is not evidence, and a number that
does not reproduce when the command is re-run is a finding rather than a record.

---

## Base commit

Measured by running `git rev-parse HEAD` at the start of task-001, before any task edited a
file. It is not copied from any document — the SPECs' recorded heads were already stale by the
time this delivery started.

```
$ git rev-parse HEAD
97aff69dd889de5c7e49391764465470cb3a2d08
```

**Base = `97aff69dd889de5c7e49391764465470cb3a2d08`.**

Every criterion that diffs against a base uses this sha, never `master`. `master` moves, and a
criterion whose base is a moving branch silently re-scopes itself whenever someone else merges —
which is how an inherited change becomes indistinguishable from this delivery's own.

The check those criteria run:

```bash
git diff 97aff69dd889de5c7e49391764465470cb3a2d08 HEAD \
  -- canonical/aid/scripts/grade.sh canonical/aid/templates/reviewer-ledger-schema.md
```

The reading is: **the diff touches neither counting logic nor column shape.** An empty diff is
sufficient but not required.

---

## Criterion-id allocation ledger

### The rule: never reuse a catalog id

A check migrated out of the abandoned rubric catalog takes a **new** id. It never keeps the id it
had there. The two namespaces collide by coincidence, not by meaning — the catalog's `KB-01` and
the current `KB-01` are different rules, so reusing the number would make a ledger row cite a
criterion that says something else. Every migrated row therefore gets the next free number in its
scope prefix, and the allocation is recorded in the table below as it is made.

### The namespace as measured at the base commit

```bash
awk -F'|' '/^\| ID \| Applies to/,/^$/ {gsub(/ /,"",$2); if ($2 ~ /^[A-Z]+-[0-9]{2}$/) print $2}' \
  .aid/knowledge/authoring-conventions.md
```

Output — **18 ids**:

```
G-01  G-02  G-03  G-04  G-05  G-06  G-07  G-08
KB-01 KB-02 KB-03 KB-04
SK-01 SK-02
SR-01
AG-01
TO-01
TP-01
```

### Next free number per prefix

| Prefix | Applies to | Highest in use | Next free |
|---|---|---|---|
| `G` | global, every in-scope file | `G-08` | **`G-09`** |
| `KB` | KB documents | `KB-04` | **`KB-05`** |
| `SK` | skill files | `SK-02` | **`SK-03`** |
| `SR` | skill references and template payloads | `SR-01` | **`SR-02`** |
| `AG` | agent files | `AG-01` | **`AG-02`** |
| `TO` | template own-content | `TO-01` | **`TO-02`** |
| `TP` | template payloads | `TP-01` | **`TP-02`** |

> **A measurement trap, recorded because the first attempt hit it.** Extracting ids with a bare
> `grep -oE '[A-Z]+-[0-9]{2}'` over the table returns a spurious `FR` prefix with a next-free of
> `FR-11`. There is no `FR` criterion namespace: the match comes from the words "FR-10 backstop"
> inside `G-07`'s `why` cell. Any id extraction must be **anchored to the ID column** — the
> `awk -F'|'` form above — not run across whole rows. A prefix invented from prose would be
> allocated to a real criterion and would resolve nowhere.

### Allocations made by this delivery

| New id | Replaces (catalog row) | Applies to | Severity | Allocated by |
|---|---|---|---|---|
| G-09  | NAR-03 (task-004) + DEF-06 (task-005) — merged: same check at `*` | `*` | MEDIUM | task-006 |
| G-10  | AID-01 (task-005) | `*` | HIGH | task-006 |
| G-11  | AID-02 (task-005) | `*` | HIGH | task-006 |
| G-12  | AID-03 (task-005) | `*` | HIGH | task-006 |
| G-13  | AID-04 (task-005) | `*` | HIGH | task-006 |
| KB-05 | KB-05 (task-003) | `kb-doc` | LOW | task-006 |
| KB-06 | KB-06 (task-003) | `kb-doc` | LOW | task-006 |
| KB-07 | KB-07 (task-003) | `kb-doc` | LOW | task-006 |
| KB-08 | KB-08 (task-003) + NAR-06 (task-004) — merged: dual-audience subsumes prose readability | `kb-doc` | MEDIUM | task-006 |
| KB-09 | KB-20 (task-003) + NAR-05 (task-004) — merged: all contradiction types in one row | `kb-doc` | HIGH | task-006 |
| KB-10 | KB-21 (task-003) | `kb-doc` | MEDIUM | task-006 |
| KB-11 | KB-22 (task-003) | `kb-doc` | HIGH | task-006 |
| KB-12 | KB-23 (task-003) | `kb-doc` | HIGH | task-006 |
| KB-13 | KB-24 (task-003) | `kb-doc` | HIGH | task-006 |
| KB-14 | KB-25 (task-003) | `kb-doc` | HIGH | task-006 |
| KB-15 | KB-26 (task-003) | `kb-doc` | LOW | task-006 |
| KB-16 | NAR-01 (task-004) | `kb-doc` | MEDIUM | task-006 |
| KB-17 | NAR-04 (task-004) | `kb-doc` | LOW | task-006 |
| KB-18 | NAR-11 (task-004) | `kb-doc` | MINOR | task-006 |

### Oracle discharge — FR-A3

`G-09` (citation resolution) is mechanically decidable via
`canonical/aid/scripts/kb/kb-citation-lint.sh`, which already runs against KB docs. The
criteria table has no `oracle:` column and widening it is out of scope for this delivery.
The oracle is therefore noted here rather than in the table cell. This constitutes the
*stated* discharge of FR-A3 for this delivery: one admitted row has a known oracle;
recording it in the table is deferred to a future column-widening delivery.

---

## Recorded outputs — the twelve gate criteria

Each section is filled by the task that discharges the criterion. A section left empty at gate
time is an unmet criterion, not an oversight.

**Every filled section opens with `**MET.**` or `**UNMET.**` on its own line**, before the
evidence. The gate reads the label; the evidence is what makes the label checkable. A section
carrying evidence but no label is neither — it forces the gate to infer, and an inferred pass is
the failure mode this record exists to prevent.

### 1. Single review path — audit passes, both globs return one

**MET.** Recorded by task-009.

```
$ bash scripts/checks/review-path-audit.sh
L1 SINGLETON   review-skill-dirs=1 (expect 1)  reviewer-agent-dirs=1 (expect 1)
L2 LEXICON     review-family names outside {aid-review, aid-reviewer}=0 (expect 0)
L3 SLASH-REFS  distinct=91  review-family=1  dangling(review-family)=0 (expect 0)  dangling(other)=1
L4 AGENT-REFS  named-and-resolving=9  reviewer-agent-present=yes
NOTE /aid-graph names no skill under canonical/skills/ (not review-family)
RESULT PASS
$ echo $?
0
```

Every layer prints its measurement beside its expectation. The one `NOTE` is a dangling
`/aid-graph` reference that is not review-family, so it is reported and does not fail the audit —
it is routed to tech debt rather than fixed here.

The two globs, kept as a cheap regression check and **not** as the test (Q7):

```
$ ls -d canonical/skills/*review*/
canonical/skills/aid-review/
$ ls -d canonical/agents/*review*/
canonical/agents/aid-reviewer/
```

Why they are not the test: a rival named `aid-screener` satisfies both globs while being exactly
what FR-A1 forbids. The audit's L2 lexicon layer is the real guard, and `test-review-path-audit.sh`
case PA03 pins that — it fails on an `aid-screener` agent that the globs wave through.

### 2. Rival PR closed; doc law holds

**MET.** Both halves. The doc law was met by task-002 and task-006; the pull request was closed by
the owner on 2026-08-17, which was the only part no task could discharge.

Doc law, all met:

```
$ grep -rn 'rubric catalog' canonical tests scripts docs .aid/knowledge | wc -l
0
$ grep -rn 'review-rubrics' canonical tests scripts docs .aid/knowledge | wc -l
0
$ grep -c "Resolve the artifact's review criteria first" canonical/agents/aid-reviewer/AGENT.md
1
```

The three-spelling 7-column grep, `2` in each of the six per-skill briefs and `1` in `/aid-review`.
Produced by:

```bash
for f in canonical/skills/aid-*/references/reviewer-brief.md; do
  printf '%s %s\n' "$(basename "$(dirname "$(dirname "$f")")")" \
                    "$(grep -ciE '7-column|7 columns|seven columns' "$f")"
done
grep -ciE '7-column|7 columns|seven columns' canonical/skills/aid-review/SKILL.md
```


| brief | count |
|---|---|
| aid-define, aid-detail, aid-discover, aid-execute, aid-plan, aid-specify | 2 each |
| `canonical/skills/aid-review/SKILL.md` | 1 |

> **Use all three spellings.** `grep -c '7-column'` alone returns `0` on those same briefs, because
> they say "(7 columns, no new column)" and "Seven columns, unchanged". A single-spelling grep here
> reports drift that does not exist.

The migration source survives, so nothing this delivery migrated is orphaned:

```
$ git rev-parse work-003
8b9e62021e0ed02d10ecfdcbbe4f07af72bba799
```

**The pull request, now closed:**

```
$ gh pr view 185 --json state,title --jq '.state + " -- " + .title'
CLOSED -- work-003: rebuild the review subsystem — severity becomes judgment, scripts become tooling
```

This was the one part of the criterion no task could discharge — nothing in this delivery performs
a pull-request write — so it stood recorded as failing until the owner acted, rather than being
quietly rounded up.

Closing it rather than merging it was the point. `work-003` still carries the rival mechanisms this
delivery replaced, and merging it would have landed them alongside their own replacement:

```
$ git grep -l -i 'review-rubrics' origin/work-003 -- canonical .aid | wc -l
38
$ git grep -l -i 'aid-screener'   origin/work-003 -- canonical .aid | wc -l
17
```

Both are `0` on `master`.

### 3. Migrated catalog checks under new ids

**MET.** Recorded by task-006.

19 rows written to `.aid/knowledge/authoring-conventions.md § Review Criteria — Criteria by Level`.
Namespace before: 18 ids. Namespace after: 37 ids. No duplicate ids.

```bash
$ awk -F'|' '/^\| ID \| Applies to/,/^$/ {gsub(/ /,"",$2); if ($2 ~ /^[A-Z]+-[0-9]{2}$/) print $2}' \
    .aid/knowledge/authoring-conventions.md | wc -l
37
```

Lint: `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge` — **PASS** (18 docs checked, 0 findings).

`grep -rn 'review-rubrics' canonical tests scripts docs .aid/knowledge` — **0 matches**.

Oracle discharge (FR-A3): G-09 is mechanically decidable via `kb-citation-lint.sh`. Oracle column
not added (out of scope). Discharge recorded in the allocation ledger above.

### 4. A real dispatch after the last feature-001 task is Done
_Pending — recorded by task-025; ordering enforced by the execution graph._

### 5. VERIFY/HUNT labelled lists from cycle 2
_Pending — task-025._

### 6. The five coverage gates each fire
_Pending — tasks 010–021._

### 7. No artifact authors a history section
_Pending — task-022, task-023, task-025._

### 8. Single grading backend — SHOULD
_Pending — recorded by task-025 as **declined by owner decision** (Q5), with its two measured
reasons. task-024 corrects the two false capability claims that the decline does not excuse._

### 9. Each new script cites its measured re-derivation

_Partly recorded — task-011 still to come._

**`kb-html-claims-check.sh` (task-016).** The candidate to extend was
`canonical/aid/scripts/summarize/spot-check-facts.sh`, which also reads `kb.html` and cross-checks
it against the KB. Measured against today's tour rather than assumed:

```
$ bash canonical/aid/scripts/summarize/spot-check-facts.sh .aid/knowledge/kb.html --limit 40
Found 17 claim(s) to check (limit 40).
[MISS] 1 files                             | not found in KB
[MISS] 10 skills                           | not found in KB
...
# Summary: 11 OK, 6 MISS (of 17 claims checked)
$ echo $?
0
```

Three measured facts made extension the wrong call. It extracts only numeric and version claims
(`N noun`, `vX.Y.Z`) — **none of the 17 is a file path**, so the renamed-artifact defect is outside
what it can see at all. It **exits 0 while reporting 6 MISS**, by design: its own header says it
"does NOT affect grading". And its MISS list is advisory-noisy — `1 files` and `10 skills` are not
real defects — which is fine for a report a human reads and disqualifying for a gate. Turning it
into a gate would also change its contract for its existing caller, the K2 manual-checklist step.

So the new script is a gate placed beside that report, not a flag bolted onto it.

Its own value, measured on the live tour:

```
$ bash canonical/aid/scripts/summarize/kb-html-claims-check.sh .aid/knowledge/kb.html
== Claim class 1: artifact names ==
[FAIL] kb.html names STATE.md (16x) and never STATE.yml
       the current artifact is STATE.yml, per canonical/aid/templates/*state-template.yml — the tour did not follow the rename
claims checked: 3   findings: 1
$ echo $?
1
```

### 10. Base diff, render parity

_Pending — task-025, against the base recorded above. One operational note recorded here while it
is fresh._

**The root install trees are not covered by the generator, and `rsync` is not on this box.**
`run_generator.py` emits to `profiles/<tool>/…` only. The repo's own dogfooded trees, `.claude/`
and `.cursor/`, are byte-copies of those renders plus a few repo-local extras
(`.cursor/rules`, `.claude/output-styles`, `.claude/settings.json`, and the two maintainer-only
skills). Nothing syncs them automatically, so a `canonical/` edit leaves them stale until they are
copied by hand.

In wave 5 that cost a task its "generator re-run in the same commit" criterion. The first sync
attempt used `rsync … 2>/dev/null`, `rsync` is not installed here, and redirecting stderr turned a
missing binary into a silent no-op that reported success. The four affected files were caught by a
`diff -rq` a step later and landed in the following commit instead of their own. Final parity is
correct and both commits sit in the same pull request, but the constraint was split.

Two rules follow, and both are cheap:

```bash
# 1. Never redirect stderr on a sync. A missing tool must be loud.
# 2. Verify parity by diff, not by the sync command's exit status:
diff -rq .cursor profiles/cursor/.cursor | grep '^Files'          # must be empty
diff -rq .claude profiles/claude-code/.claude | grep '^Files'     # must be empty
```

### 11. Every count carries its command and reproduces
_Pending — task-025._

### 12. All section-6 quality gates pass
_Pending — task-025._

---

## Operational hazard found during execution — exported `AID_*` state-file overrides

`writeback-state.sh` and its siblings accept `AID_STATE_FILE`, `AID_TASK_STATE_FILE` and
`AID_DELIVERY_STATE_FILE` as absolute-path overrides that skip path resolution. Exporting one into
a **shell that later runs the test suite** makes several suites write to that real file instead of
their own temp fixtures.

Measured, at wave 3: with three such variables exported, `tests/run-all.sh` reported **17 of 140**
suites failing. With `env -u` clearing them, the same tree reported **13 of 140** — and the four
"failures" were `test-writeback-state`, `test-task-state-transitions`, `test-disjoint-merge` and
`test-delivery-gate-aggregate`, every one of them a state-writer suite.

The damage was not only a false red. Those suites **wrote their fixture values into a real task
state file**: `task-001/STATE.yml` came back reading `state: 'In Progress'`, `review: B`,
`elapsed: '8m'`, `display_name: 'Custom Flat Title'` — a task that was `Done` and gated. It was
restored from the last commit, which is the only reason the corruption was recoverable.

**The rule this delivery follows from here:** never `export` an `AID_*` state-file override. Pass it
per command (`AID_TASK_STATE_FILE=… bash writeback-state.sh …`) so it dies with the process, and run
the suite with `env -u AID_STATE_FILE -u AID_TASK_STATE_FILE -u AID_DELIVERY_STATE_FILE` when in
doubt. A suite result measured in a polluted shell is not evidence.

**Suite baseline for this delivery** — measured clean at wave 3, and the number every later task
compares against: **13 of 140 canonical suites failing**, all pre-existing. The delivery-001
baseline recorded at task-001 was 15 of 139; two of those (`test-doc-set-mapping`,
`test-doc-set-propose-confirm`) now pass, and one suite was added by task-008.
