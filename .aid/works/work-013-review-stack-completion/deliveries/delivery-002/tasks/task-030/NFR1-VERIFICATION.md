# task-030 — NFR-1 verified at the point the edit landed

NFR-1 says: do not change `grade.sh`'s counting logic and do not change the seven-column shape.
This delivery edits `reviewer-ledger-schema.md`, the file delivery-001 required unchanged, so the
constraint is at its sharpest here.

Run **now**, immediately after task-028's edit, rather than at the delivery gate. A verification
run at the end tells you something broke; a verification run at the edit tells you what broke it.

Base: `1412e63d1b8cf5d039778efe2f9c3ad23a9fdbd3`, recorded by task-026.

## 1. The grading script — empty diff

```
$ git diff 1412e63d1b8cf5d039778efe2f9c3ad23a9fdbd3 HEAD -- canonical/aid/scripts/grade.sh | wc -l
0
```

**Empty, not merely safe.** The acceptance criterion asks only that counting logic and column shape
be untouched; an empty diff is stricter and is the right bar for a file this delivery has no reason
to open at all. The why-line and the provenance tokens live in columns `grade.sh` never reads.

## 2. The header row — exactly one match

```
$ grep -c '^| # | Severity | Status | Doc | Line | Description | Evidence |' canonical/aid/templates/reviewer-ledger-schema.md
1
```

## 3. The enums and the status table — compared, not assumed

| Check | At base | Now |
|---|---|---|
| severity enum occurrences | 4 | 4 |
| status enum occurrences | 2 | 2 |
| status-table rows | 6 | 6 |

## 4. The pinned literals

Four strings `test-scoped-review-cycles.sh` reads by exact match. All resolve:

```
$ for lit in "REVIEW (cycle 1)" "scoped cycle never approves" "the cycle is UNSCOPED" "shape stays 7 columns"; do
    grep -c "$lit" canonical/aid/templates/reviewer-ledger-schema.md
  done
1
1
1
1
```

## 5. The scoped-cycle suite's fixture grades — individually

`SC15` asserts all three at once and reports one message on failure:

> `SC15 (C-3, AC-10) grader/ledger contract broken -- empty='$G_EMPTY' (want A+), one-LOW='$G_LOW' (want B+), mixed='$G_MIX' (want D+)`

That says *something* moved without saying *which*. Reproduced here one at a time, so a future
failure is attributable:

| Fixture | Expected | `grade.sh` output |
|---|---|---|
| empty ledger | `A+` | `A+` |
| one `[LOW]` Pending | `B+` | `B+` |
| one `[HIGH]` Pending + one `[LOW]` Fixed | `D+` | `D+` |

The third is the load-bearing one: it proves a `Fixed` row still does not count toward the grade,
which is the behaviour the why-line change had the most scope to disturb and did not.

## 6. The schema's diff, line by line against the prohibited set

The schema's diff is **not** empty, and must not be — the contract is what changed. Stated line by
line rather than summarised as safe:

| Changed | Prohibited? |
|---|---|
| column row 6, `Description` — adds the why-line requirement | no: the row's *description* changed, the column did not |
| column row 7, `Evidence` — adds the three provenance tokens | no: same |
| a new paragraph under § Citing the criterion — the `task-NNN AC-N` form | no: adds a citation form, touches no column |

Against the prohibited set explicitly:

- **Counting logic** — lives in `grade.sh`, whose diff is empty. Untouched.
- **Column shape** — the header row still yields one match, and the count is unchanged at seven. No
  column was added, removed, renamed, or reordered; two column *descriptions* changed.

## 7. The selector count that makes the suite reachable

The one number a full-suite run would have hidden. If the suite is not selected by a change to
these two files, everything above is verified by a run that only happened because something else
triggered it:

```
$ bash tests/canonical/select-suites.sh canonical/aid/scripts/grade.sh | grep -c test-scoped-review-cycles
1
$ bash tests/canonical/select-suites.sh canonical/aid/templates/reviewer-ledger-schema.md | grep -c test-scoped-review-cycles
1
```

Both `1`. The first was `0` until task-027 added the missing `COVERS` header — so before this
delivery, a change to `grade.sh` did not select the suite that exists to prove `grade.sh` is
unchanged. That is the shape of a guard that cannot fire, and it is why task-027 ran before this
one.
