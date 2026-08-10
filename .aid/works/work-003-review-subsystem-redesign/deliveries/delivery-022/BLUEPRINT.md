# Delivery BLUEPRINT -- delivery-022: One review skill

> **Delivery:** delivery-022
> **Work:** work-003-review-subsystem-redesign
> **Created:** 2026-08-09

---

## Objective

Collapse the review subsystem's two skills into one. `aid-deep-review` and `aid-light-review` merge
into `/aid-review`, which carries **named** entry paths rather than a depth flag. Scoped last in the
work because it renames the skill every other delivery is written against.

## Scope

- `/aid-review` gains **three explicitly named** entry paths, one per caller shape, per `FR-A1` as
  amended and `STATE.md` Q1(a): **ad-hoc** -- a human invoking `/aid-review` on an arbitrary
  artifact with **no manifest**; **gate** -- a pipeline skill chain-calling the graded pass **with a
  full manifest**, where a missing field is *"a caller error, not something to infer"*; and
  **screening** -- the cheap, ungraded pass that batches gaps before the graded one (`FR-C9`).
  The ad-hoc path **grades like the gate path and shares its agent and ledger**, but takes scope,
  rule set and executor as **arguments**, and **asks the human** for a field it cannot obtain rather
  than inferring one (`FR-A1`). That is why it is separately named and separately selected rather
  than modelled as the gate path with a looser manifest: Q1(a) states that inferring which is
  intended *"would reproduce exactly the failure this answer preserves"*.
- Every site naming the retired skills, re-pointed. `grep -rl "/aid-deep-review" canonical/`
  returns **12** files: the nine caller sites (eight skill reference files plus
  `shortcut-engine.md`) that `grep -rl "/aid-deep-review" canonical/skills/*/references/
  canonical/aid/templates/shortcut-engine.md` returns, plus `aid/templates/reviewer-dispatch.md`
  and the two skills' own `SKILL.md` files, which this delivery deletes or rewrites rather than
  re-points. The nine is the caller set, not the total, and both figures are stated so neither
  reads as the other.
- **`tests/canonical/test-review-extraction.sh`, repaired alongside the deletions.** It reads all
  three files this delivery removes: `reviewer-guide.md` at line 92 inside `RX07`'s `B_AFTER`
  `wc -l ... 2>/dev/null` sum, and both retired `SKILL.md` files **unguarded** at lines 61-62. The
  guarded one is the dangerous one -- `2>/dev/null` means the deletion loosens the `AC-11`
  anti-gaming baseline instead of failing the suite.
- `aid-execute/references/reviewer-guide.md` **retired** -- 77 lines still opening *"Reference for
  Step 2 (REVIEW)"*, a step that no longer exists, and still carrying the `CODE / TASK / SPEC / KB`
  source table that two other files declare retired. Retiring it also closes `Q3(b)` and `Q3(c)`.
- What the screening path writes, settled against `FR-A2` (screening computes no grade) and `FR-A4`
  (a clean screening pass may only add findings, never pre-clear the gate).
- The work's own artifacts that name the retired skills. Measured 2026-08-09 with
  `grep -rl "aid-deep-review\|aid-light-review" deliveries/ features/ *.md`, run from this work
  folder: **9 files across 4 delivery folders** (`delivery-012`, `014`, `017` and **this delivery's own BLUEPRINT**, which names them
  because retiring them is its subject), **5 files under `features/`**, and `PLAN.md`,
  `REQUIREMENTS.md` and `STATE.md`. Of these, `delivery-017/task-002` is the one whose Scope *is*
  the gate being renamed. Records that name a retired skill **as history** -- an `AMENDED` note, a
  `STATE.md` Q&A entry, a superseded SPEC paragraph -- are left alone; only live statements are
  re-pointed.

**Out of scope:** `/aid-audit`, already removed upstream -- `git ls-tree origin/master canonical/skills/` returns
neither it nor either merged skill; the `aid-screener` agent, which stays (the 10-agent roster
stands and `delivery-010` shipped the boilerplate split precisely so it would not inherit the
exhaustiveness mandate).

## Gate Criteria

- [ ] `canonical/skills/` contains `aid-review` and neither `aid-deep-review` nor `aid-light-review`
- [ ] All three entry paths are **named and selected explicitly**; none is chosen by inference from
      a missing argument. In particular, an ad-hoc invocation with no manifest does **not** fall
      through to the gate path. A caller that names no path is an error, not a default
- [ ] Every site that reached the gate before still reaches it: the nine files the pre-merge grep
      returned each invoke `/aid-review`, and the two transitive callers still route through
      `aid-discover`'s `state-review.md`
- [ ] `reviewer-guide.md` no longer exists, and `grep -rln 'reviewer.guide' canonical/` returns
      **nothing** -- it has no referrers under `canonical/` today. The emission manifests are
      regenerated rather than edited, and work records that name the retired file are history and
      are not swept
- [ ] **`tests/` is repaired in the same delivery, because deleting these three files breaks it
      silently.** `tests/canonical/test-review-extraction.sh:92` names `reviewer-guide.md` inside
      `RX07`'s `B_AFTER` sum under `wc -l ... 2>/dev/null`, so the deletion would subtract that
      file's line count from the AC-11 anti-gaming baseline **without failing** -- the redirect
      swallows the error and the clause silently loosens. The same file `cat`s
      `canonical/skills/aid-light-review/SKILL.md` and `.../aid-deep-review/SKILL.md` **unguarded**
      at lines 61-62, which the merge deletes. The criterion: after this delivery
      `grep -rn 'reviewer.guide\|aid-light-review\|aid-deep-review' tests/` returns only lines that
      reference the merged `/aid-review`, and `RX07`'s baseline is re-derived from the post-merge
      file set rather than carrying a stale sum
- [ ] `FR-C9`'s primary path still holds: gaps are batched before the graded pass, so the common
      case needs no mid-review interruption
- [ ] `AC-13`'s cost claim keeps its subject -- screening + gate measured against gate alone
- [ ] No work artifact names a retired skill except where recording the rename
- [ ] Five-profile parity (AC-12) re-run and clean; dogfood byte-identity passes
- [ ] All section-6 quality gates pass

## Tasks

_Derived from `tasks/task-NNN/DETAIL.md`. Written by `aid-detail`; empty until it runs._

| Task | Type | Wave | Title |
|------|------|------|-------|
| _none yet_ | | | |

## Dependencies

- **Depends on:** delivery-016, delivery-017, delivery-018, delivery-019, delivery-020, delivery-021
- **Blocks:** delivery-023

## Notes

**Owner decision 2026-08-09, and the direction matters.** The merge goes *into* `/aid-review`, not
the reverse. Neither new skill has ever shipped, so this is prevention rather than migration and no
adopter sees a retired name. Naming also improves: review is deep by default and `light` marks the
exception, so the qualifier leaves the common case.

**The `depth` flag stays rejected.** The 2026-07-27 rationale -- *"a single skill with a `depth` flag
would put both behaviours behind one entry point, and the failure mode is silent"* -- is honoured,
not overturned: the objection was to **silence**, and named entry paths are not silent. Collapsing
any of the three paths into an implicit one would reproduce exactly that failure.

**Known cost, accepted when this was sequenced last.** `delivery-017/task-002`'s Scope is the gate in
`aid-deep-review` RESOLVE, including an AC whose command greps for `/aid-deep-review`. 017 therefore
builds under a name this delivery retires. That churn is bounded to the rename sweep this delivery
performs anyway; the alternative was re-detailing three already-graded deliveries.
