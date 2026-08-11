# task-002: Seed the corpus, one defect per rule

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

**Depends on:** task-001

**Scope:**
- `tests/canonical/fixtures/recall-corpus/**` -- the seeded artifacts
- One catalogue row for **every rule row in every in-domain rule set**: seeded, or `fixture = --` carrying its reason in `summary`
- Each row's `polarity` set to what the fixture actually shows -- the anchor being present, or being missing

**Acceptance Criteria:**
- [ ] Every rule row in an in-domain rule set has exactly one catalogue row. The in-domain set is the predicate `SPEC.md § 2b` defines -- **a rule set containing at least one rule row** -- evaluated by reading the rule sets, never from a list held anywhere
- [ ] Every seeded defect is independently addressable: the catalogue identifies it precisely enough that a review either found *that* defect or did not, with no judgment call at scoring time
- [ ] Each `locator` is a **content anchor, never a line number** -- a fixture is edited by every re-seed
- [ ] The fixtures build their own inputs and read nothing under `.aid/works/`
- [ ] Each `--` row's `summary` says why the rule is knowingly unseeded, in a sentence a reader can disagree with
- [ ] All section-6 quality gates pass
