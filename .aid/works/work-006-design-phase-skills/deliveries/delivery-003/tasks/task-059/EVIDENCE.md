# task-059 EVIDENCE -- the catalog's own three stale count comments, each re-derived from the file

BLUEPRINT criterion **6**. delivery-001 and delivery-002 handed these here deliberately so three
features do not collide on one file (feature-003 SPEC § *Verification*, V28).

## 0. Why the derivation *is* the oracle

No other task in this delivery can see these three lines. They are comments inside `canonical/`,
so the surviving `test-doc-counts.sh` never scans them; the repo-wide count guard that once might
have was retired upstream; and task-069's stage-2 replay reaches only the `repurpose` figure --
the other two carry digits (`16`, `15`) that are not among the quantities it scans. So the
correction and its own derivation are the whole mechanism, which is why every figure below is
taken from the file at execution time rather than from the DETAIL.

## 1. The three corrections

| Site | Was | Now | Derivation |
|---|---|---|---|
| the `repurpose` field contract | `24 rows` | **60 rows** | `grep -c '^    repurpose: true$'` -> 60 |
| G4 create-family header | `16 canonical rows (12 in this section; ...)` | **23 canonical rows (19 in this section; ...)** | `grep -c '^  - name: aid-create'` -> 23; 19 counted inside the block |
| G5 change-and-refactor header | `15 canonical aid-update* rows (12 in this section; ...)` | **22 canonical aid-update* rows (15 in this section; ...)** | `grep -c '^  - name: aid-update'` -> 22; 15 counted inside the block |

Each re-checked against the file *after* the edit: the comment's figure and the derived figure
agree in all three cases.

## 2. The G5 parenthetical needed more than a new number

The DETAIL anticipated that the "12 in this section" operand would move with the total. It did --
but not the way a `12 + 7` would predict, and the difference is a real finding rather than
arithmetic.

**There are two comment blocks labelled `G5`** in this catalog: *"G5: Change + Refactor family"*
and, further down, *"G5: Remove + Deprecate + Migrate"* (a v2.1.0 coverage-gap follow-on). The
four foundation rows delivery-002 added -- `aid-update-{architecture,stack,testing-strategy,cicd}`
-- were placed under the **second** one. Counted per block:

```
aid-update* rows:  15  under "G5: Change + Refactor family"
                    4  under "G5: Remove + Deprecate + Migrate"     <- the foundation four
                    1  in G7      1  in G8      1  in G11
                   --
                   22  total
```

Their `group:` **field** is `G5` on all four, so the functional grouping the site renders from is
correct and nothing is broken; only the physical placement under a same-named header is off. A
parenthetical reading `(19 in this section; ...)` would therefore have been **false**. The header
now says what is actually true and sums correctly:

```
22 canonical aid-update* rows (15 in this section; the four foundation rows
aid-update-{architecture,stack,testing-strategy,cicd} sit under the
Remove + Deprecate + Migrate header below, though their group: field is G5;
aid-update-test in G7, aid-update-document in G8, aid-update-dashboard in G11)

15 + 4 + 1 + 1 + 1 = 22    == the derived total
```

Moving the rows would have been the tidier fix, but this task's scope is explicit -- *"any change
to a row -- this task edits comments only"* -- so the placement is **logged** for the gate instead.
It is the same class as delivery-002's adjudicated grid-row placement finding: presentational,
with the functional field correct.

## 3. Nothing that must not move, moved

| Guard | Result |
|---|---|
| the `shortcuts` (emitting) quantity, **34** | not stated in this file at all -- its only `34` is the task id in `task-034`, untouched by the diff |
| `3 classic re-registered pipeline skills` / `classicRepurposed` | not in this file either; they live in `site/scripts/__tests__/skill-counts.test.mjs`, which is task-062's |
| any row | **none** -- every changed line begins with `#` |

The "must not move" guard is therefore satisfied *vacuously* here, which is worth stating plainly:
over-application is this delivery's most likely error mode, and the reason it could not happen in
this task is that the tempting figures are not in this file.

```
$ git diff canonical/aid/templates/shortcut-catalog.yml
  3 comment sites, 9 changed lines, every one a comment
$ python3 -c "yaml.safe_load(...)"      94 rows, 60 with repurpose:true
$ bash tests/canonical/test-catalog-dirs-parity.sh      PASS
```

## 4. Placement in the sequence

This is the last task to write the catalog **before** the render, which is why it sits here: the
catalog renders as verbatim bytes to all five profiles, so a comment corrected after task-060
would leave five stale copies and fail task-061's freshness oracle.
