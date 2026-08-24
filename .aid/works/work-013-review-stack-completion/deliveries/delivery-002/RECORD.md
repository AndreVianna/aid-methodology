# delivery-002 — evidence record

The ten gate criteria and their evidence. Each section is filled by the task that discharges the
criterion. A section left empty at gate time is an unmet criterion, not an oversight.

**Every filled section opens with `**MET.**` or `**UNMET.**` on its own line**, before the
evidence. The gate reads the label; the evidence is what makes the label checkable. A section
carrying evidence but no label is neither — it forces the gate to infer, and an inferred pass is
the failure mode this record exists to prevent.

**Every count carries the command that produced it.** A number that does not reproduce when its
command is re-run is a finding, not a record. Delivery-001 learned this twice over: a count can be
falsified by a later task in the same delivery without anyone touching the section it sits in, and
a command that only runs on the machine that wrote it is not evidence anywhere else. Prefer the
command to the number; where a number is quoted, say which moment it belongs to.

---

## Base commit

This delivery branches from delivery-001's merged state, so it has **its own** base. Measured by
running `git rev-parse HEAD` at the start of task-026, before any task edited a file — not copied
from the SPEC, whose recorded head was already stale at approval.

```
$ git rev-parse HEAD
1412e63d1b8cf5d039778efe2f9c3ad23a9fdbd3
```

**Base = `1412e63d1b8cf5d039778efe2f9c3ad23a9fdbd3`** — `work-013 d001: compute the gate tier
instead of shipping the template default`, 2026-08-24. Every `git diff <base> HEAD` in this record
uses that literal SHA rather than a branch name: delivery-001's record cited `work-003` by branch
and the command failed outright in a fresh checkout, because a local branch exists only where it
was created.

---

## Baselines, measured at task-026

**Every figure in this section is a historical record of the delivery's starting point, and several
have moved since — by design, because the delivery moved them.** The suite count rose from 142 to
145 as three suites were added; the literal ledger-path count fell from 31 to 2 because closing it
was task-034's job. Re-running a command here will not reproduce its number, and should not: what
these figures are for is the comparison the closing criteria make against them.

Figures in the **Gate criteria** section below are current and do reproduce.

Re-measured at task-026 rather than quoted. The SPEC's own why-line provenance figure had already
moved between approval and execution, which is why the acceptance criterion forbids copying one.

### Why-line coverage on a real ledger

The most recent real reviewer ledger at the time of measurement, delivery-001's closing gate:

```
$ awk -F'|' '/^\|[[:space:]]*[0-9]+[[:space:]]*\|/{r++; if (tolower($0) ~ /(so|because|which means|otherwise|leaving|leaves)/) w++} END{print "rows=" r " why-line=" w+0}' .aid/works/work-013-review-stack-completion/deliveries/delivery-001/tasks/task-025/FINDINGS.md
rows=5 why-line=2
```

One line on purpose. The first version of this block was a `python3` heredoc carrying pseudocode and
an elided `...` in the path — it did not run at all, and the gate reviewer caught it. A screen whose
own command cannot be pasted is not evidence of anything, least of all of a coverage measurement.

**2 of 5.** That is the gap feature-003 exists to close, and it is measured on a ledger written by
this very work under the current rules — not on a synthetic sample. The screen's own wording is
task-028's to fix; this figure is only the starting point it will be compared against.

### Suite baseline — count *and* pass/fail

Recorded as both, so a later comparison is against a measured starting point rather than an
assumed clean tree.

```
$ bash tests/run-all.sh
13 of 142 CANONICAL SUITES FAILED
$ ls tests/canonical/*.sh | wc -l
143
```

| Measure | At this base |
|---|---|
| canonical suites failing | 13 of 142 |
| suite files on disk | 143 |
| assertions passed, summed | 7564 |
| assertions failed, summed | 37 |

The 143-versus-142 gap is `select-suites.sh`, a helper rather than a suite. The 13 failures are the
same 13 that were failing when delivery-001 began; none was introduced by it, and none is this
delivery's to fix.

### Literal ledger paths — what task-031 through task-034 will move

```
$ grep -rn 'review-pending/[a-z0-9-]*\.md' canonical/skills --include='*.md' | grep -v '{' | wc -l
31
$ grep -rln 'review-pending/' canonical/skills --include='*.md' | wc -l
37
```

31 hardcoded ledger paths across 37 files that mention one. Six of those files are the per-skill
`reviewer-brief.md` templates.

### COVERS headers — the NFR-1 canaries

```
$ grep -rln 'COVERS' tests/canonical/*.sh
tests/canonical/select-suites.sh
tests/canonical/test-criterion-oracles.sh
tests/canonical/test-review-cost-meter.sh
tests/canonical/test-review-path-audit.sh
tests/canonical/test-scoped-review-cycles.sh
tests/canonical/test-validator-behavior.sh
```

Six files carry one; task-027 adds the two that are missing.

### Cost-meter double count — the before-figure for gate criterion 5

Gate criterion 5 asks for a coverage unit that is not a file, and its SHOULD names a double count
to close. task-026's scope does not list this baseline, but criterion 5 will need a before-figure
and it is cheaper to pin now than to reconstruct at the gate:

```
$ grep -E '^specify-feature-001' .aid/works/work-013-review-stack-completion/review-cost.tsv
specify-feature-001-single-review-path-alignment	1	2dd1eb0e6909106a797cbdc65bf27fd423f51000	42034
specify-feature-001-single-review-path-alignment	2	2dd1eb0e6909106a797cbdc65bf27fd423f51000	84934
```

Cycle 2 is exactly twice cycle 1: `84934 = 2 x 42467`, and `42467` is not `42034`, so the doubling
is not a re-read of the same declared surface. It is one path counted twice within a single cycle.
task-045 and task-047 own closing it; this row exists so they have a measured start.

### Cost-meter extractor — the before-output, in the form the AC asks for

task-046's AC-1 asks for the extractor's before-output showing the same path emitted twice, not
only the summed total. Captured before the change:

Illustrative, not runnable: `brief_artifacts` is a function inside
`tests/review-cost-meter.sh` and does not exist in a shell. For a brief naming `README.md` on both
the VERIFY and HUNT lists, it emitted the path twice —

```
README.md
README.md
```

— and `surface_bytes` summed both, recording **29790** for a 14895-byte file. Reproducible today
through the tool rather than the function, which is what `CM20` in
`tests/canonical/test-review-cost-meter.sh` asserts.

After: the extractor still emits both lines — the brief does name the path twice, and hiding that
would lose the signal — and `surface_bytes` counts the path once, recording 14895.

### Selector partition

```
$ bash scripts/checks/g07-selector-partition.sh >/dev/null 2>&1; echo "exit $?"
exit 0
$ bash scripts/checks/g07-selector-partition.sh 2>&1 | grep -c '^UNDECIDED'
76
```

All 76 are `template-payload` rows whose selectors are not fully expressible. Gate criterion 6 is a
SHOULD requiring this to be unchanged at the end, so it is pinned here.

### NFR-1 subjects, fingerprinted

The sharpest constraint on this delivery is that it edits `reviewer-ledger-schema.md` — the file
delivery-001's feature-001 required unchanged — while leaving `grade.sh` counting logic and the
seven-column shape alone. Both files are fingerprinted so the later diff has something exact to
compare against:

```
$ md5sum canonical/aid/scripts/grade.sh canonical/aid/templates/reviewer-ledger-schema.md
0d87371d1bdbf165fa386f8c5b7286e5  canonical/aid/scripts/grade.sh
4ffd48dcad98a5443cd06f1cce08977d  canonical/aid/templates/reviewer-ledger-schema.md
```

`grade.sh` must still hash to that value at the gate. The schema will not, and must not — the
why-line lives inside its existing seven columns, so the file changes while the column count does
not.

---

## Gate tier

Computed rather than left at the template default, which is the gap delivery-001 shipped with for
its whole run:

Scored per `state-delivery-gate.md § Tier Selection` over delivery-002's execution graph. Not a
single command — the score is derived from the graph, the task types and the thresholds together:

```
tasks=23  depth=6  risk=21  consults=0   ->  complexity score 50
thresholds: Small <= 6, Large >= 14
```

Risk is 12 `IMPLEMENT` and 9 `TEST` at +1 each. **Tier: Large.**

*The commit that first set this field quoted `depth 9, risk 15, score 47` — numbers written before
the computation was run rather than after. The figures above are the computed ones. Recorded here
because the wrong ones are in the git history and a reader comparing the two deserves to know which
is which.*

---

## An out-of-enum state value, and why the writer did not stop it

`delivery_state` sat at `In Progress` for four waves. That is not one of the six values the
template declares:

```
$ sed -n '50,51p' canonical/aid/templates/delivery-state-template.yml
# [W] Pending-Spec | Specified | Executing | Gated | Done | Blocked
delivery_state: Pending-Spec
```

Corrected to `Executing`. The cause is the part worth keeping: `writeback-state.sh` has **no mode
for this field**, so it was written by editing the file directly — and a direct edit bypasses the
enum validation the writer applies to every field it does own. The writer refuses an out-of-enum
value with exit 4 before writing a byte; nothing refuses a `python` one-liner.

Found by the wave-5 gate reviewer, logged as an out-of-scope observation rather than a finding,
which was the right call — it belonged to no task in that wave. Recorded here because the delivery
record is where a reader looks for the state of the delivery, and the field that names it was wrong
the whole time.

## Gate criteria

### 1. Why-line coverage on this delivery's own ledger

**MET, and the measurement corrected itself.**

The screen, run over every delivery-002 ledger written after the contract landed in wave 3:

```
  post-contract rows        : 6
  fully compliant           : 5
  MALFORMED (unescaped pipe): 1  -- execute-d002-wave4.md row 4 (12 fields, want 9)
  well-formed, no why-line  : 0
  well-formed, no token     : 0
```

Both residue lists are empty. Every well-formed row carries a why-line and a provenance token.

**The first run of this screen said the opposite, and that is the finding worth keeping.** Written
without masking the schema's `\|` escape, it reported *5 of 6 rows failing*, and each flagged row
was about to be filed against the reviewer that wrote it. Reading them — which is the substance
half this criterion demands, and the only reason the error surfaced — showed three of the four
contained an unescaped or escaped pipe inside a cell, so the split shifted and the screen was
reading the Doc column where it expected Evidence.

That is precisely the defect `WL04` in `test-severity-why-line.sh` exists to catch, committed by the
screen written to enforce the rule. The coverage check is a grep and proves a shape; the substance
check is reading and is what proves the grep was pointed at the right cell. This criterion asks for
both because either alone would have been wrong here.

**The one real defect it did find**: `execute-d002-wave4.md` row 4 contains an unescaped `|`, giving
12 fields where the schema's seven columns give 9. The row is malformed rather than
non-compliant — its content may well carry a why-line — and no screen can read it until it is
escaped. Recorded rather than silently repaired, because a ledger is append-only history.

### 2. Three recorded attempts to reach a prior cycle's ledger

**MET.** Recorded by task-035 in its `ATTEMPTS.md`, with exit codes, against
`execute-d002-wave1.md` — a ledger an earlier cycle of this delivery actually wrote, so a
successful read would be a genuine leak rather than a tautology.

| Attempt | Result |
|---|---|
| 1. name it directly from a FIX state | 0 matches — no instruction names a prior ledger |
| 2. resolve it through the parameter | 0 matches — `{{LEDGER}}` resolves per scope |
| 3. preflight against a seeded leftover | **exit 1**, naming the file |

`test-ledger-isolation.sh` asserts all three plus the mirror case, and the gate reviewer confirmed
the mutation goes red. The record states plainly that the design closes the **naming**, not the
filesystem, and that the structural claim rests on the CI hygiene step rather than on `.gitignore` —
an ignore rule is a default, and a default is what `git add -f` overrides.

### 3. Recall report, per criterion scope and overall

**MET.**

```
$ bash tests/review-recall.sh report --ledger tests/canonical/fixtures/recall-corpus/seed-ledger.md
scope                      seeded    found
------------------------ -------- --------
G                               9        1
KB                              4        0
SK                              2        0
TO                              5        0
------------------------ -------- --------
TOTAL                          20        1
```

Raw counts per scope and a total, never a stored ratio — `3/6` and `30/60` print the same and mean
very different things about a corpus. A group with nothing seeded prints `missing`, because an
empty denominator is not a perfect score.

### 4. A FIX commit carries Sweep-class, Sweep-command and Sweep-residue

**MET.** The three trailers and the re-run rule are in `state-fix.md` § F1, and `SW01`-`SW04` in
`test-scoped-review-cycles.sh` prove the record is checkable: a ledger row names the first instance
only, the recorded command finds both, fixing one leaves a residue of **one**, and fixing both
leaves zero.

The residue-of-one step is the load-bearing one. A sweep that finds nothing looks identical to a
sweep that ran and had nothing to find, and only a non-zero residue distinguishes them. The source
corpus is asserted byte-identical afterwards; only a temp copy is mutated.

### 5. A coverage unit that is not a file — SHOULD

**MET.** Seven cycle-2 briefs in this work name a region unit (`path § Heading`) rather than a
path:

```
$ grep -l '§' .aid/works/work-013-review-stack-completion/briefs/*cycle-2*.md | wc -l
7
```

The trigger was measured, not asserted: cycle 2 of `specify-feature-001` declared exactly twice
cycle 1 at a re-read ratio of 2.02, and half of it was not the cycle-1 surface — so a path was on
both lists and counted once for each. task-046 closed the double count and made a region attribute
to its file instead of being dropped to zero, which is what makes the smaller figure mean what it
says.

### 6. Selector partition unchanged — SHOULD

**MET.**

```
$ bash scripts/checks/g07-selector-partition.sh >/dev/null 2>&1; echo "exit $?"
exit 0
$ bash scripts/checks/g07-selector-partition.sh 2>&1 | grep -c '^UNDECIDED'
76
```

Identical to the 76 recorded at this delivery's base. All are `template-payload` rows whose
selectors are not fully expressible; the delivery added none.

The same run also discharges the observe-only boundary: **zero `VIOLATION` lines, therefore zero
ledger rows from an oracle run** — recorded as zero rather than assumed. The 76 `UNDECIDED` lines
are not findings and produce no rows either, which is the distinction task-043's clauses draw.

### 7. review-recall.sh cites its measured re-derivation

**MET — satisfied, not discharged as a non-merge.**

task-036 fixed the floor *in advance*: at least 20 seeded defects against at least 90 real ledger
rows. Measured at merge:

```
$ grep -cE '^\| D[0-9]+ \|' tests/canonical/fixtures/recall-corpus/CATALOGUE.md
20
$ find .aid/works -name FINDINGS.md -exec grep -chE '^\|[[:space:]]*[0-9]+[[:space:]]*\|' {} \; | awk '{s+=$1} END{print s}'
153
```

Both cleared, so the script ships. The re-derivation its header cites is not labour but a
default-wrong answer: the naive row count and the status-aware count disagree on **17 of 21** real
ledgers, and not one non-empty ledger agrees. They disagree in the direction that flatters,
reporting closed findings as caught.

`record` was **not** built. task-039 is `Canceled` on its own AC-1: no gate criterion requires it,
task-036's measurement is silent on it, and `Q10` leaves its consumer undefined.

### 8. NFR-1: grade.sh unchanged, column shape unchanged

**MET.**

```
$ git diff 1412e63d1b8cf5d039778efe2f9c3ad23a9fdbd3 HEAD -- canonical/aid/scripts/grade.sh | wc -l
0
$ md5sum canonical/aid/scripts/grade.sh
0d87371d1bdbf165fa386f8c5b7286e5
```

Empty, and identical to the fingerprint task-026 took before any edit. Stricter than the criterion
requires and correct for a file this delivery had no reason to open.

The schema's diff is **not** empty and must not be — the contract is what changed. Against the
prohibited set, with the commands rather than the assertions, since this record's own standard is
that a count carries the command that produced it:

```
$ grep -c '^| # | Severity | Status | Doc | Line | Description | Evidence |' canonical/aid/templates/reviewer-ledger-schema.md
1
$ S=canonical/aid/templates/reviewer-ledger-schema.md; B=1412e63d1b8cf5d039778efe2f9c3ad23a9fdbd3
$ for pat in 'CRITICAL.*HIGH.*MEDIUM.*LOW.*MINOR' 'Pending.*Fixed.*Recurred.*Accepted.*OOS.*Invalid' '^\| `(Pending|Fixed|Recurred|Accepted|OOS|Invalid)`'; do echo "base=$(git show $B:$S | grep -cE "$pat")  now=$(grep -cE "$pat" $S)"; done
base=4  now=4
base=2  now=2
base=6  now=6
```

What changed is two column *descriptions* and one added citation form. No column was added,
removed, renamed or reordered.

### 9. Every count carries its command and reproduces

**MET.** Every `$ command` block in the **gate-criteria section below** was re-run at close and all
nine reproduce.

The **historical baselines section** is deliberately different, and there are **five** figures there
that no longer reproduce — not one, as an earlier draft of this paragraph said:

| Command | Recorded at task-026 | Now | Moved by |
|---|---|---|---|
| `git rev-parse HEAD` | the base SHA | a later SHA | time |
| `bash tests/run-all.sh` | 13 of 142 | 13 of 145 | three suites added |
| `ls tests/canonical/*.sh \| wc -l` | 143 | 146 | the same three |
| literal ledger paths | 31 | 2 | task-034 |
| `COVERS` headers | 6 | 9 | tasks 029, 040 and 035, each adding a new suite |


Every one is a figure this delivery was *supposed* to move, which is why the section is labelled
historical rather than corrected. Calling it "the one deliberate exception" understated it by four,
and the gate reviewer counted them.

*The `COVERS` row first named task-027, which is wrong in an instructive way. task-027 added a
`COVERS` line to two files that already had one, so the count of files carrying a header did not
move at all. What moved it was three new suites — `test-severity-why-line.sh` (task-029),
`test-review-recall.sh` (task-040) and `test-ledger-isolation.sh` (task-035). The task that worked
on `COVERS` headers was not the task that changed how many files have one, and attributing by
subject rather than by effect is how a plausible wrong answer gets written down.*

*A second precision, found while checking the first: `6 → 9` belongs to the baseline's own
unanchored `grep -rln 'COVERS'`. An anchored `grep -rl '^# COVERS:'` gives `5 → 8`, because two
files mention the word outside a header line. Both are true of different questions, and a figure
without its pattern invites a reader to reproduce it with the other one and conclude the record is
wrong. Verifying this nearly led to "correcting" a number that was right.*

Delivery-001 learned this twice and both lessons held here: a command that ran only on the machine
that wrote it is not evidence anywhere else, and a count recorded as evidence is a claim about a
moment that a later task in the same delivery can falsify without touching the section it sits in.
Where a figure moves — the ledger-row total is now 153, was 114 at task-026 — the command is given
rather than the number defended.

### 10. All section-6 quality gates pass

**MET.**

```
$ bash tests/run-all.sh
13 of 145 CANONICAL SUITES FAILED
```

The same thirteen that were failing at this delivery's base. The suite count rose from 142 to 145 —
`test-severity-why-line.sh`, `test-review-recall.sh` and `test-ledger-isolation.sh` — and all three
pass.

| Gate | Result |
|---|---|
| `verify_deterministic.py` | PASS; re-running the generator emits 1775 files and changes none |
| render parity | `diff -rq` empty for both root install trees against their profile renders |
| `kb-citation-lint.sh` | clean |
| `lint-frontmatter.sh` | PASS |
| `g07-selector-partition.sh` | exit 0, 0 violations |
| `review-path-audit.sh` | PASS |
