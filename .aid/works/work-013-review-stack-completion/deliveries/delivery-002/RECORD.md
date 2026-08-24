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

## Baselines, measured now

Re-measured at task-026 rather than quoted. The SPEC's own why-line provenance figure had already
moved between approval and execution, which is why the acceptance criterion forbids copying one.

### Why-line coverage on a real ledger

The most recent real reviewer ledger at the time of measurement, delivery-001's closing gate:

```
$ python3 - .aid/works/.../delivery-001/tasks/task-025/FINDINGS.md <<'EOF'
  rows   = lines matching ^\|\s*\d+\s*\|
  whyline = those also matching \b(so|because|which means|otherwise|leaving|leaves)\b
EOF
rows=5 why-line=2
```

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

## Gate criteria

### 1. Why-line coverage on this delivery's own ledger
_Pending — task-028, task-029._

### 2. Three recorded attempts to reach a prior cycle's ledger
_Pending — task-035._

### 3. Recall report, per criterion scope and overall
_Pending — task-038, task-039._

### 4. A FIX commit carries Sweep-class, Sweep-command and Sweep-residue
_Pending — task-041, task-042._

### 5. A coverage unit that is not a file — SHOULD
_Pending — task-045._

### 6. Selector partition unchanged — SHOULD
_Pending — task-048, against the 76 UNDECIDED recorded above._

### 7. review-recall.sh cites its measured re-derivation
_Pending — task-036, task-038._

### 8. NFR-1: grade.sh unchanged, column shape unchanged
_Pending — task-030, task-048, against the base and fingerprints recorded above._

### 9. Every count carries its command and reproduces
_Pending — task-048._

### 10. All section-6 quality gates pass
_Pending — task-048._
