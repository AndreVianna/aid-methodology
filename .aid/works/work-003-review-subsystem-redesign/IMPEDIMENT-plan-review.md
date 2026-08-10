# IMPEDIMENT — `/aid-plan` REVIEW circuit breaker tripped

> **Work:** work-003-review-subsystem-redesign
> **Phase:** Plan (REVIEW state, scope `plan-019-023`)
> **Raised:** 2026-08-10
> **Bar:** `A` (`.aid/settings.yml:6`; `read-setting.sh --skill aid-plan --key minimum_grade` = `A`)
> **Status:** **RESOLVED 2026-08-10** — option 1 taken, and the diagnosis widened

## Resolution

The owner took **option 1** (move the forensics) and, on the diagnostic questions this impediment
prompted, accepted **four** amendments rather than one. They are recorded as `STATE.md` Q27–Q30, each
carrying its own measurement, and all four are applied.

| Amendment | What it changes | Carried by |
|---|---|---|
| Q30(b) — the recommendation above | `delivery-022`'s per-site forensics leave `## Scope` for task `DETAIL.md`; the obligation stays as two gate criteria. 172 → 155 lines | applied directly |
| Q30(a) | A derived fact is stated **once** and cited elsewhere — the **Restatement convention**, in `REQUIREMENTS.md`'s conventions preamble | applied directly |
| Q29 | A fix is not complete until its class has been swept — `FR-E2`, `AC-17` | delivery-025 |
| Q27 | A coverage row's unit becomes the **claim**, not the file — `FR-D10`, `AC-15` | delivery-026 |
| Q28 | **Recall measurement** — a seeded corpus and a measured fraction, group H (`FR-H1`–`FR-H3`), `AC-16` | delivery-024, delivery-027 |

**Why the root cause below was necessary but not sufficient.** This document correctly identified
the artifact-shape problem in one file. The wider measurement, taken after it was written and
recorded in `STATE.md` Q27 and Q28, found that the loop's failure was not confined to
`delivery-022`: every pre-existing defect had been missed by several reviews each, and the file
most often marked `Examined` was also the file that later yielded the most findings. The three
cycles that tripped the breaker were the visible end of that, not its cause. Q27 and Q28 address the cause: a
review whose coverage is a file-granular self-report, in a work with no term at all for findings
**missed**.

**Pipeline state.** `lifecycle` returns to `Running`; `block_reason` and `block_artifact` cleared.
Deliveries `019`–`023` remain `Pending-Spec`, joined by `024`–`027`. One thing is newly open and is
recorded in `PLAN.md § Open at Plan`: `feature-009` owns the new requirements and had no SPEC.
**Resolved 2026-08-10** — `/aid-specify` ran and authored it; it is `In Discussion` and must reach
`Ready` before deliveries `024`, `025` and `027` are detailed.

---

> The original record follows unchanged. Its root-cause analysis stands; the resolution above widens
> it rather than replacing it.

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
