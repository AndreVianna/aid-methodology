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

_None yet._ Tasks 003, 004 and 005 propose ids per admitted row; task-006 writes them and records
each allocation here. Admitting zero rows is a valid outcome, provided the screening table is
recorded.

| New id | Replaces (catalog row) | Applies to | Severity | Allocated by |
|---|---|---|---|---|

---

## Recorded outputs — the twelve gate criteria

Each section is filled by the task that discharges the criterion. A section left empty at gate
time is an unmet criterion, not an oversight.

### 1. Single review path — audit passes, both globs return one
_Pending — task-007, task-008, task-009._

### 2. Rival PR closed; doc law holds
_Pending — task-002, task-009. Closing pull request #185 is an owner action, not a task._

### 3. Migrated catalog checks under new ids
_Pending — task-003, task-004, task-005, task-006._

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
_Pending — task-007, task-011._

### 10. Base diff, render parity
_Pending — task-025, against the base recorded above._

### 11. Every count carries its command and reproduces
_Pending — task-025._

### 12. All section-6 quality gates pass
_Pending — task-025._
