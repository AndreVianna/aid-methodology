# IMPEDIMENT — `/aid-plan` REVIEW circuit breaker tripped

> **Work:** work-003-review-subsystem-redesign
> **Phase:** Plan (REVIEW state, scope `plan-019-023`)
> **Raised:** 2026-08-10
> **Bar:** `A` (`.aid/settings.yml:6`; `read-setting.sh --skill aid-plan --key minimum_grade` = `A`)

---

## The condition

`aid-deep-review § FIX` declares the breaker as **non-improvement**, not a cycle count:

> **Circuit breaker: the grade does not improve after 3 consecutive cycles.** Then stop, write an
> `IMPEDIMENT`, and set the caller's lifecycle `Blocked`. … A loop returning the same grade three
> times running has stopped being a review and become a ritual.

Cycles **17, 18 and 19 each graded `C`**. The breaker has tripped on its stated condition.

## Grade history, measured

Each row is `grade.sh --explain` over that cycle's ledger in `.aid/.temp/review-pending/`.

| Cycle | Grade | Findings | | Cycle | Grade | Findings |
|---|---|---|---|---|---|---|
| 2 | `D` | 10 | | 11 | `C` | 3 |
| 3 | `C-` | 10 | | 12 | `C` | 3 |
| 4 | `C-` | 6 | | 13 | `C+` | 1 |
| 5 | `D+` | 6 | | 14 | `C` | 2 |
| 6 | `C+` | 1 | | 15 | `C-` | 7 |
| 7 | `C` | 3 | | 16 | `C` | 4 |
| 8 | `C` | 2 | | 17 | `C` | 2 |
| 9 | `C` | 3 | | 18 | `C` | 2 |
| 10 | `C+` | 1 | | 19 | `C` | 3 |

**Fourteen consecutive cycles between `C-` and `C+`.** Every finding was fixed and verified on disk
before the next cycle ran; no finding was ever deferred, accepted or waived. The loop is not stalled
on an unfixed defect — it is stalled because **each fix mints new defects at about the rate it
closes them**.

## Root cause

**Every finding in the last three cycles was in the previous cycle's own repair**, and the
concentration is not diffuse:

| Cycle | Findings by file |
|---|---|
| 16 | `STATE.md` ×2, `PLAN.md`, `delivery-022/BLUEPRINT.md` |
| 17 | `delivery-022/BLUEPRINT.md`, `STATE.md` |
| 18 | `delivery-022/BLUEPRINT.md` ×2 |
| 19 | `delivery-022/BLUEPRINT.md` ×3 |

`delivery-022/BLUEPRINT.md`'s `## Scope` has accumulated **task-level forensics**: a per-line
classification of seven read sites in `tests/canonical/test-review-extraction.sh`, each labelled
loud or silent, with guard-by-guard reasoning and an analysis of the suite's shell options.

`artifact-schemas.md § Delivery BLUEPRINT.md` scopes that section to
*"bounded in-scope deliverables + an explicit `**Out of scope:**` line"*. Per-site implementation
analysis is **task `DETAIL.md`** content — that schema's `Scope` is *"bounded list of what the task
produces/modifies"*, and `delivery-022`'s Tasks table is still `_none yet_`, so `/aid-detail` has
not yet run and the detail has nowhere legitimate to live.

**The mechanism.** Each cycle I authored more precise forensic prose to satisfy the last finding.
More precision means more checkable claims, and every checkable claim is defect surface. Because the
artifact type does not require that precision, the added surface carries **no offsetting value** —
it is pure exposure. That is why the grade cannot climb: the bar is zero findings above `MINOR`, and
the artifact is structured so that each repair reopens the same class one level deeper.

Cycle 19 is the clean illustration. Cycle 18 replaced a wrong-but-complete repair prescription with
a right-but-incomplete one, and cycle 19 found the incompleteness — a defect that existed only
because cycle 18 wrote a more detailed prescription than a BLUEPRINT needs.

## What is NOT the problem

- **The criteria.** All eleven criteria gaps are registered and dispositioned; `--open-keys` is
  empty; `check-gaps.sh` exits 0.
- **The mechanical battery.** `lint-modality` 95/95. `kb-citation-lint` reports **zero** violations
  in any in-scope artifact. Dependency-graph reciprocity is exact in both directions across all 23
  deliveries. The sighting arithmetic has been independently re-derived by three separate reviewers
  and agrees at all three restatement sites. Every embedded command reproduces from the cwd its text
  names.
- **The substance.** No finding in the last six cycles disputed a *decision*. All were precision
  defects in prose describing decisions that are themselves sound.

## Recommended resolution — needs an owner decision

**Move the test-suite forensics out of `delivery-022/BLUEPRINT.md § Scope` and into the task
`DETAIL.md` files `/aid-detail` will author for it.** The BLUEPRINT keeps the obligation and the
gate criteria; the DETAIL carries the per-site analysis, where the schema puts it and where a
reviewer grades it against task rules rather than definition rules.

Why this needs a decision rather than another edit: the content being moved is **verified correct**.
Trimming it is a conformance judgment about what a BLUEPRINT is for, and it changes an artifact this
work has spent nineteen cycles hardening. The alternatives, for the record:

1. **Move it** (recommended) — schema-conformant, removes the defect surface, loses nothing because
   `/aid-detail` runs next anyway.
2. **Accept `C` and proceed to `/aid-detail`** — the artifact is substantively sound and the bar is
   a quality target, not a correctness proof. Requires an explicit owner waiver of the `A` bar for
   this scope, recorded in the register.
3. **Keep cycling** — the measured expectation is another 1–3 findings per cycle at `C`±1, in the
   same file, indefinitely.

## Tracking

Plan REVIEW state: **Blocked** pending the decision above. No delivery lifecycle changes; deliveries
`019`–`023` remain `Pending-Spec`.
