# task-004: `npm test` gate step in `docs.yml`'s build job

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-004. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-004/STATE.md.
Shape: 6 sections matching .claude/aid/templates/delivery-plans/task-template.md.

> **Execution protocol (binding on whoever executes this task -- no
> exceptions):** the moment this task's `State` changes, write it --
> `In Progress` before starting work, `In Review` before dispatching the
> reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally
> whether the main/orchestrator agent executes this task directly or
> dispatches it to a sub-agent; neither may skip, batch, or defer these
> writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- it is never
> self-written by the task being executed.) Full mandate:
> `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** CONFIGURE

**Source:** work-001-skill-explorer -> delivery-001 (feature-001-skill-detail-pages)

**Depends on:** task-002, task-003

**Scope:**
- **Dependency resolution -- a `Canceled` task-003 SATISFIES this dependency.** task-003 is contingent and is `Canceled` at creation when task-002 routes nothing to absorb; that is its **success** path, not a failure. This task therefore proceeds once **task-002 is `Done`** and **task-003 is either `Done` or `Canceled`**. Only a `Failed` or still-open task-003 blocks it. Do not wait for a `Done` that will never come, and do not treat the `Canceled` state as an unmet prerequisite.
- Insert one step into `.github/workflows/docs.yml`'s `build` job -- name `Test (site vitest suite)`, `working-directory: site`, `run: npm test` -- positioned strictly between the existing `npm ci` step and the `npm run build` step. After `npm ci` because `vitest` is a devDependency; before `npm run build` to fail fast, so a red suite never produces a Pages artifact.
- Emit **no `env:` block** on the test step, deliberately: the build step exports `AID_VERSION` / `AID_LATEST_RELEASE_JSON` / `AID_RELEASES_JSON`, and inheriting them would fight `src/data/__tests__/ac13-version-injection.test.ts`, which sets and restores `process.env.AID_VERSION` itself. The suite must exercise the `.release-data.json` fallback path deterministically.
- No trigger change is otherwise required -- the `build` job already runs on `pull_request` to `master` with a `site/**` path filter, so pull requests are gated automatically, and the `deploy` job's `if: github.event_name != 'pull_request'` is untouched.
- **Scope is contingent on an owner answer.** feature-005's OQ-3 asks whether `docs.yml`'s path filter should gain `canonical/**` (the two filters at `docs.yml`:13-17 and :20-24), since a `canonical/`-only commit triggers no docs build today and deployed deep-link anchors can sit one generation stale. If the owner answers yes, that change lands in this same edit; if no, the filters are untouched. Either way the answer is recorded -- delivery-001 owns the decision because `docs.yml` is already open here, and deciding it at delivery-004 would reopen a shipped artifact.

**Acceptance Criteria:**
- [ ] The step sits strictly between the `npm ci` and `npm run build` steps of the `build` job, and carries no `env:` key.
- [ ] The `deploy` job's `if: github.event_name != 'pull_request'` and every existing trigger are unchanged, except as the OQ-3 answer directs.
- [ ] The edit is idempotent -- re-applying it produces no second step and no further diff.
- [ ] No secret, token or credential appears in plaintext anywhere in the workflow.
- [ ] A red suite fails the `build` job **before** `npm run build` executes, so no Pages artifact can be produced from one -- verified by step ordering plus a deliberate local failure.
- [ ] feature-005's OQ-3 is answered and recorded in `deliveries/delivery-001/STATE.md`, and the two path filters at `docs.yml`:13-17 and :20-24 match that answer.
- [ ] `site/scripts/gen-reference.mjs` is byte-unmodified and no file under `site/` is changed by this task.
- [ ] All section-6 quality gates pass
