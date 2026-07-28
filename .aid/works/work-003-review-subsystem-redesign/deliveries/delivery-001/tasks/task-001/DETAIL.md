# task-001: Base reconciliation and emission manifests

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

**Source:** work-003-review-subsystem-redesign -> delivery-001

**Depends on:** --

**Scope:**
- `git checkout --` on `canonical/agents/aid-reviewer/AGENT.md` in the main tree, discarding the uncommitted markdown-formatter run
- ~~The five rendered `profiles/*/emission-manifest.jsonl` files~~ **CUT at execution** -- the `src` normalization is deliberate generator behaviour (`render.py`, "for manifest src stability"), so there is no defect here

**Acceptance Criteria:**
- [ ] `git diff canonical/agents/aid-reviewer/AGENT.md` is empty in the main tree
- [ ] _(cut -- the manifest `src` value is an intentional logical identifier, not a filesystem path)_
- [ ] All section-6 quality gates pass
