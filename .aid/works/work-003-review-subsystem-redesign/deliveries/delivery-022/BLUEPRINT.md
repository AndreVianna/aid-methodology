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
  run from the repo root returns exactly these. One of them needs naming separately, because it
  breaks in a way a rename does not fix:
  - `test-review-extraction.sh` -- **it reads the deleted files in seven places, and three of
    those reads fail loudly while four fail silently.** That asymmetry is why this suite is named
    here rather than left to the sweep: a loud failure tells the next person what to fix, a silent
    one leaves an assertion measuring nothing while the suite still reports green. Two of the silent
    four sit on **both halves of `RX07`'s `SUM = B_AFTER + NEW`**, so the deletion shrinks both
    sides and the `AC-11` anti-gaming clause loosens instead of tripping.
  - `test-gap-gate-wiring.sh`, `test-settings-frontmatter-gates.sh` and
    `test-shortcut-engine-contract.sh` -- each holds a loud read that fails once the name is gone.
  **The repair is not a rename**, and that is the delivery-level constraint: a rename leaves all
  four silent sites exactly as vacuous as they are now, which the gate criteria forbid. Every read
  site must be **classified loud-or-silent, assigned a repair, and made loud** -- an assertion whose
  subject file is missing has to fail, not skip and not fall through to `pass`.

  **The per-site classification is task `DETAIL.md` content, not Scope.** `artifact-schemas.md`
  scopes this section to bounded in-scope deliverables; which line each read sits on, which shell
  construct makes it silent, and which of re-point / drop / collapse it takes are per-site
  implementation analysis, which `artifact-schemas.md` puts in a task's own `Scope` ("bounded list
  of what the task produces/modifies"). `/aid-detail` derives it from the file, which is where it
  came from in the first place -- it is re-derivable by `grep -n` and was re-derived three times
  during review. The gate criteria below carry the obligation, so nothing is lost by not restating
  the analysis here.

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
- [ ] **Every silently-failing assertion Scope identifies fails when its own subject file is
      absent.** Stated separately from the criterion above because the grep does not reach it -- a
      re-pointed assertion can still be vacuous -- and enforced **per assertion**, because a
      suite-level check is satisfied by one assertion failing loudly while another still passes on
      nothing. **Verified one at a time:** for each, move its subject file aside in a scratch copy
      and confirm **that assertion** reports a failure. One run per assertion, one failure per run
      -- a single run that goes red overall is not evidence for any of them. Which construct makes
      each read silent, and therefore what repair trips it, is the task's to establish; this
      criterion fixes only the outcome the task must reach
- [ ] **The repair does not rely on dropping `2>/dev/null`.** Called out because it is the reading
      the code invites and it does not work: the suite runs `set -uo pipefail` with **no `-e`**, so
      a failing `wc`/`cat` inside `$( )` completes the assignment anyway. Any repair that leaves a
      missing input contributing `0` to a sum fails this criterion however the redirect is written
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
- **Blocks:** delivery-023, delivery-027

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
