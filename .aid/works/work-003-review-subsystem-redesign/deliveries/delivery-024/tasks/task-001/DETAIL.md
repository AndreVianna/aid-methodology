# task-001: The catalogue's shape and its builder

> **Execution protocol (binding on whoever executes this task -- no exceptions):** the moment
> this task's `State` changes, write it -- `In Progress` before starting work, `In Review` before
> dispatching the reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally whether the
> main/orchestrator agent executes this task directly or dispatches it to a sub-agent; neither may
> skip, batch, or defer these writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- never self-written by the task being
> executed.) Full mandate: `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** IMPLEMENT

**Source:** work-003-review-subsystem-redesign -> delivery-024

**Depends on:** -- (none)

**Scope:**
- `tests/recall-catalogue.tsv` and whatever builds it: the nine columns `SPEC.md § 2` specifies, in that order
- The `class` column read from `review-rubrics/INDEX.md` **at build time**, never hardcoded -- a rule set added later must not need this file edited to be classified
- The `(fixture, rule_id)` uniqueness constraint, enforced by the builder rather than left to authors

**Acceptance Criteria:**
- [ ] Every column `SPEC.md § 2` names is present, and no column it does not name is
- [ ] `rule_set` is **absent** -- `SPEC.md § 2` derives it from `class` and from the `rule_id` prefix, and storing it would be a third source that can disagree
- [ ] Two rows sharing a `(fixture, rule_id)` pair are rejected, with the pair named in the error
- [ ] A row whose `fixture` is `--` is accepted only when `summary` carries a reason
- [ ] `class` for a rule set present in `INDEX.md` but absent from any list in this repo still resolves -- demonstrated by adding a throwaway class to a copy of `INDEX.md` and re-running the build
- [ ] All section-6 quality gates pass
