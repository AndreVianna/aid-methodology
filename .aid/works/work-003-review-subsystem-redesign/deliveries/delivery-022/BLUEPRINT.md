# Delivery BLUEPRINT -- delivery-022: One review skill

> **Delivery:** delivery-022
> **Work:** work-003-review-subsystem-redesign
> **Created:** 2026-08-09

---

## Objective

Collapse the review subsystem's two skills into one. `aid-deep-review` and `aid-light-review` merge
into `/aid-review`, which carries **named** entry paths rather than a depth flag. Scoped **after
every delivery the rename would otherwise churn** -- 023 follows it, but 023 is written against the
post-merge name and so is unaffected -- because **`delivery-017` is authored against the retired name**: of the six deliveries this one
waits on, `grep -rl "aid-deep-review\|aid-light-review" deliveries/delivery-01[6-9] deliveries/delivery-02[01]`
run from the work folder returns only `delivery-017` (its BLUEPRINT and `task-002`'s DETAIL, whose
whole Scope is the gate in `aid-deep-review` RESOLVE). Renaming earlier would force that work to be
written against a name already decided for retirement and then re-written. `delivery-016` uses the
phrase *"A deep-review dispatch"* for the **concept**, not the skill, so the rename does not reach
it. `delivery-023`, which follows this one, is already written against the post-merge name.

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
- **The four `tests/canonical/` suites that read the files this delivery deletes, repaired
  alongside the deletions.** `grep -rln 'reviewer.guide\|aid-light-review\|aid-deep-review' tests/`
  run from the repo root returns exactly these, and each breaks differently:
  - `test-review-extraction.sh` -- **it reads the deleted files in seven places, and four of
    them fail silently.** That asymmetry is the whole reason this suite is in scope: a loud failure
    tells the next person what to fix, a silent one leaves an assertion measuring nothing while the
    suite still reports green. Classified by reading each site:
    - **Fails loudly (3).** `RX01` at 57-58 asserts `[[ -f ... ]]` equals `yes`. The unguarded
      `cat`s at 61-62 leave `$light`/`$deep` empty, which `RX02`-`RX04` then fail on.
      `RX13`/`RX14` at 158-159 count the profile renders with `find ... | wc -l`, so a missing
      render increments `missing` and `RX14` fails.
    - **Fails silently (4).** `RX05` at 76 runs `grep -qiE ... aid-light-review/SKILL.md`; **`grep`
      exits 2 on a missing file**, so the `else` branch runs and `RX05` reports `pass` having tested
      nothing. `B_AFTER` at 92 sums `reviewer-guide.md` under `wc -l ... 2>/dev/null`, and `NEW=`
      at 95-96 `cat`s both retired `SKILL.md` files under the same redirect -- so the deletion
      **shrinks both sides of `SUM = B_AFTER + NEW`** and the `AC-11` anti-gaming clause loosens
      instead of tripping. `RX15`/`RX16` at 172 and 183 resolve the render with
      `find ... | head -1` and then `[[ -n "$f" ]] || continue`, so the loop body is skipped, the
      `drift`/`pan` counters stay `0`, and both assertions pass vacuously.
  - `test-gap-gate-wiring.sh` -- `gated_somehow()`'s `elif grep -q 'aid-deep-review'` branch at
    line 80 falls through to `fail` once the name is gone, taking `GW04`/`GW05` with it.
  - `test-settings-frontmatter-gates.sh` -- `$DEEP` (line 18) points at the deleted `SKILL.md`, so
    `SG18` fails.
  - `test-shortcut-engine-contract.sh` -- `SEC03a` asserts the engine still contains
    `/aid-deep-review` and `SEC03b` reads the deleted file (lines 164-167).
  **The repair is not a rename.** A rename leaves all four silent sites exactly as vacuous as
  the classification above says they are, which the gate criteria forbid. Three distinct repairs:
  **All seven reads are assigned**, so no site is left to an implementer's discretion:
  - **Re-point** (2 sites), where the subject survives under the new name: `RX05` at 76, and
    `RX15`/`RX16`'s render lookups at 172 and 183. Outside this file: `test-gap-gate-wiring.sh:80`,
    `test-settings-frontmatter-gates.sh:18`, `test-shortcut-engine-contract.sh:164-167`.
  - **Drop** (1 site), where the subject has no successor: `reviewer-guide.md` is retired outright,
    so its term must leave `B_AFTER`'s sum at 92 rather than point somewhere new.
  - **Collapse** (4 sites), where two subjects become one: `RX01` (57-58), the `cat`s that bind
    `$light`/`$deep` (61-62), `NEW=`'s two `cat`s (95-96), and `RX13`/`RX14` (158-159). Each asserts
    over *two* skills that this delivery merges into one, so the loop and its expected counts change
    shape, not just their strings.
  And in every case the read must be made **loud**: an assertion whose subject file is missing has
  to fail, not skip and not fall through to `pass`.
- `aid-execute/references/reviewer-guide.md` **retired** -- 77 lines carrying the
  `CODE / TASK / SPEC / KB` source table that `reviewer-ledger-schema.md` and `aid-reviewer/AGENT.md`
  both declare retired, and reached by nothing: `grep -rln 'reviewer.guide' canonical/` returns
  nothing. Its opening line, *"Reference for Step 2 (REVIEW)"*, still names a **live** step --
  `state-delivery-gate.md`'s `## Step 2: REVIEW` -- so the case for retiring it is the stale content
  and the absent referrers, **not** a vanished step. Retiring it also closes `Q3(b)` and `Q3(c)`.
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

**Out of scope:** `/aid-audit`, already removed upstream --
`git ls-tree --name-only origin/master:canonical/skills/` returns 76 names and none of them is
`aid-audit` or either merged skill; the `aid-screener` agent, which stays (the 10-agent roster
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
- [ ] **The four test suites in Scope are repaired in this delivery**, and the whole suite passes:
      `grep -rln 'reviewer.guide\|aid-light-review\|aid-deep-review' tests/` run from the repo root
      returns **nothing**, and **both halves of `RX07`'s `SUM` -- `B_AFTER` and `NEW` -- are
      re-derived from the post-merge file set** rather than carrying a sum that silently shrank
- [ ] **Each of the four silent assertions fails when its own subject file is absent.** Stated
      separately from the criterion above because the grep does not reach it -- a re-pointed
      assertion can still be vacuous -- and stated **per assertion**, because a suite-level check
      is satisfied by `RX01` failing loudly while `RX05` still passes on nothing. The four, and
      what each must do: `RX05` must assert its subject exists before grepping it (a bare
      `grep -q` on a missing file exits 2 and takes the `else` branch); `B_AFTER` and `NEW` must
      **assert their inputs exist before reading them** -- dropping `2>/dev/null` is **not**
      sufficient and must not be taken as the option: the suite runs `set -uo pipefail` with **no
      `-e`** (line 15), so a failing `wc`/`cat` inside `$( )` completes the assignment anyway and
      `SUM` still shrinks. Verified: `set -uo pipefail; N=$(cat /nonexistent | wc -l)` yields `N=0`
      and execution continues, with or without the redirect. The only repair that trips is an
      explicit existence check, or building the sum from a file list the test separately asserts is
      complete; `RX15`/`RX16` must fail on an unresolved render instead of
      `continue`-ing past it. **Verified one at a time:** for each of the four, move its subject
      file aside in a scratch copy and confirm **that assertion** reports a failure. Four separate
      runs, four separate failures -- a single run that goes red overall is not evidence for any of
      them
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

**Known cost, accepted when this was sequenced after the deliveries the rename would churn.** `delivery-017/task-002`'s Scope is the gate in
`aid-deep-review` RESOLVE, including an AC whose command greps for `/aid-deep-review`. 017 therefore
builds under a name this delivery retires. That churn is bounded to the rename sweep this delivery
performs anyway; the alternative was re-detailing three already-graded deliveries.
