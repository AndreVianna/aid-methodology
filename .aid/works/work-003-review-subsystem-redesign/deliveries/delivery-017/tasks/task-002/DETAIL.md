# task-002: RESOLVE gate and CI step

> **Execution protocol (binding on whoever executes this task -- no exceptions):** the moment
> this task's `State` changes, write it -- `In Progress` before starting work, `In Review` before
> dispatching the reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally whether the
> main/orchestrator agent executes this task directly or dispatches it to a sub-agent; neither may
> skip, batch, or defer these writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- never self-written by the task being
> executed.) Full mandate: `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** CONFIGURE

**Source:** work-003-review-subsystem-redesign -> delivery-017

**Depends on:** task-001

**Scope:**
- The gate in `aid-deep-review` **RESOLVE** -- the state that reads the manifest and resolves the artifacts, and the last one before DISPATCH
- **What the one site covers, measured on disk rather than assumed.** Reaching it *directly*, by invoking `/aid-deep-review`: `aid-define` (`state-cross-reference.md`), `aid-specify` (`state-review.md`), `aid-plan` (`review-deliverables.md`, `first-run-loop.md`), `aid-detail` (`review.md`, `first-run.md`), `aid-execute` (`state-delivery-gate.md`), `aid-discover` (`state-review.md`) -- eight skill reference files -- plus the shortcut engine's GATE (`canonical/aid/templates/shortcut-engine.md`). Reaching it *transitively*, by invoking `aid-discover`'s panel rather than naming the skill: `aid-describe` (`state-describe-seed.md § Step 5 -- Greenfield-Mode Review Gate`) and `aid-update-kb` (`references/state-review.md`)
- **What it does not cover, named so the boundary is not read as completeness.** The gate reaches exactly what invokes `/aid-deep-review`; every review that dispatches `aid-reviewer` directly stays outside it. `aid-review` (`SKILL.md § State: REVIEW` and `§ State: VERIFY`) -- and with it `aid-audit`, whose SKILL.md delegates its whole behaviour to `aid-review/SKILL.md` -- is the one the upstream SPEC got wrong: `feature-008-citation-accuracy/SPEC.md § 4. Wiring, and the cost argument` claims the one site covers `aid-review`, but that was conditioned on feature-006's Tier-2 migration, and delivery-012 -- which owned that migration and is `Done` at A+ -- deliberately scoped `aid-review` out to keep its meta-review VERIFY loop. No remaining delivery owns it. Outside the gate for their own reasons: `aid-specify`'s per-section review (`state-continue.md § 4. Review`), excluded by feature-006's 2026-07-27 amendment because a terminal CHAIN cannot serve an in-loop review; `aid-execute`'s Step 1.5 quick check (`state-review.md § Step 1.5: QUICK CHECK`), which feature-006 planned to route to `/aid-light-review` -- on disk it still dispatches `aid-reviewer` directly -- and which `feature-008 § 4` declines to gate under either wiring; `aid-discover`'s FIX-state re-review (`state-fix.md § Step 6: Re-Review`); and the Tier-3 `repurpose` VERIFY dispatches feature-006 deferred (`aid-research`, `aid-prototype`, `aid-test` and their named siblings). **No count is quoted, and none should be** -- the residual set must be derived at implementation time, exactly as feature-006 required of its Tier 3 after competing regexes disagreed
- **This task gates none of the uncovered sites and adds no second site.** Wiring them is a separate job with no owner in this work; recording the boundary here is this task's whole obligation toward them
- The CI step, which does not exist yet: no workflow references the citation lint, so this task **adds** the step rather than making an existing one honest -- the KB claim that it already ran was corrected by delivery-002

**Acceptance Criteria:**
- [ ] The gate sits in RESOLVE ahead of DISPATCH: in `canonical/skills/aid-deep-review/SKILL.md`, the `kb-citation-lint.sh` invocation appears at a line earlier than the `### 2. DISPATCH` heading. Grep-decidable, and it is the ordering that makes "before the dispatch" mean anything
- [ ] The gate blocks, in both directions: invoked on a manifest whose resolved artifacts carry a broken citation, RESOLVE exits 1, dispatches no `aid-reviewer` and returns the findings to the caller for FIX; the same manifest with the citation corrected proceeds to DISPATCH. A suite asserting only the blocking direction is satisfied by a gate that blocks everything, so a citation defect would cost the review cycle it was added to save
- [ ] The covered set is the one the Scope names and does not shrink silently: `grep -rl "/aid-deep-review" canonical/skills/*/references/ canonical/aid/templates/shortcut-engine.md` returns the eight reference files plus the shortcut engine, and `aid-describe`'s Step 5 and `aid-update-kb`'s `state-review.md` still invoke `aid-discover/references/state-review.md`. A caller that stops routing through the skill leaves the gate, and this is the check that says so
- [ ] The lint runs in CI
- [ ] All section-6 quality gates pass
