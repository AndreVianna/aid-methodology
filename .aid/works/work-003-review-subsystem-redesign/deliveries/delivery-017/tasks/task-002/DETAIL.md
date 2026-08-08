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
- **What it does not cover, named so the boundary is not read as completeness.** The gate reaches exactly what invokes `/aid-deep-review`; every review that dispatches `aid-reviewer` directly stays outside it. Outside on disk today: `aid-review` (`SKILL.md § State: REVIEW`, `§ State: VERIFY`) and with it `aid-audit`, which delegates to it; `aid-specify`'s per-section review (`state-continue.md § 4. Review`); `aid-execute`'s Step 1.5 quick check (`state-review.md § Step 1.5: QUICK CHECK`); `aid-discover`'s FIX-state re-review (`state-fix.md § Step 6: Re-Review`); and the deferred Tier-3 `repurpose` VERIFY dispatches. **No count is quoted, and none should be** -- the residual set is derived at implementation time as the COMPLEMENT of the covered set -- the acceptance criterion below pins the covered set with a command; the residual is what is left of the review sites after subtracting it, and is not that command's output. Why each sits outside, and which delivery was to have moved it, is `feature-008-citation-accuracy/SPEC.md § 4`'s to state, not this task's.
- **This task gates none of the uncovered sites and adds no second site.** Wiring them is a separate job with no owner in this work; recording the boundary here is this task's whole obligation toward them
- The CI step, which does not exist yet: no workflow references the citation lint, so this task **adds** the step rather than making an existing one honest -- the KB claim that it already ran was corrected by delivery-002

**Acceptance Criteria:**
- [ ] The gate sits in RESOLVE ahead of DISPATCH: in `canonical/skills/aid-deep-review/SKILL.md`, the `kb-citation-lint.sh` invocation appears at a line earlier than the `### 2. DISPATCH` heading. Grep-decidable, and it is the ordering that makes "before the dispatch" mean anything
- [ ] The gate blocks, in both directions: invoked on a manifest whose resolved artifacts carry a broken citation, RESOLVE exits 1, dispatches no `aid-reviewer` and returns the findings to the caller for FIX; the same manifest with the citation corrected proceeds to DISPATCH. A suite asserting only the blocking direction is satisfied by a gate that blocks everything, so a citation defect would cost the review cycle it was added to save
- [ ] The covered set is the one the Scope names and does not shrink silently: `grep -rl "/aid-deep-review" canonical/skills/*/references/ canonical/aid/templates/shortcut-engine.md` returns the eight reference files plus the shortcut engine, and `aid-describe`'s Step 5 and `aid-update-kb`'s `state-review.md` still invoke `aid-discover/references/state-review.md`. A caller that stops routing through the skill leaves the gate, and this is the check that says so
- [ ] The lint runs in CI
- [ ] All section-6 quality gates pass
