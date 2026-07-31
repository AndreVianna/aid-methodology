# task-045: `jsdom` test-only devDependency and the DOM test environment

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-045. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-045/STATE.md.
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

**Source:** work-001-skill-explorer -> delivery-005 (feature-006-interactive-node-panel)

**Depends on:** task-044

**Scope:**
- Add `jsdom` to `site/package.json` `devDependencies` and establish the per-file `// @vitest-environment jsdom` opt-in that task-053 uses. `site/` has **no `vitest.config.*`** -- `astro.config.mjs` is the only `*.config.*` in the directory -- so vitest runs in its default `node` environment with no `document`, no `MutationObserver` and no focus model, and half of feature-006 is DOM lifecycle.
- **This task is delivery-005's decision point, and the decision is the owner's.** feature-006's OQ-1 asks whether one test-only devDependency is acceptable. REQUIREMENTS section 7 permits a new dependency only "where FR-3's node interaction requires it"; `jsdom` never ships to a browser, so this SPEC reads it as outside that prohibition. **If the owner declines, delivery-005 is DROPPED rather than shipped with its DOM lifecycle untested** -- the alternative is a node-only suite that covers the projection and the pure predicates but leaves event delegation, the re-attachment lifecycle and every ARIA attribute unverified, which is most of the risk in this feature. Dropping is cheap and pre-approved: delivery-005 is a **Should**, nothing depends on it, AC-5 is already discharged by delivery-004's static list, and rollback is four deletions and two one-line reverts.
- Playwright is **rejected as an automated gate** and must not be substituted: it is genuinely new to `site/`, `docs.yml` has no browser step and would need `npx playwright install chromium` on every pull request, and section 7's allowance is for a *runtime* dependency, which this is not. The repo's existing Playwright lane lives in a different workflow and is not extended here.
- `dependencies` is untouched -- that is the half section 7 constrains. No script key is added and the `prebuild` / `predev` chains are unchanged.

**Acceptance Criteria:**
- [ ] `site/package.json` `dependencies` is **unmodified**, verified by diff; exactly one `devDependencies` entry is added, and it is `jsdom`.
- [ ] `package-lock.json` pins it reproducibly and `npm ci` succeeds from a clean state.
- [ ] The default `node` environment is unchanged for every existing suite: the full suite still exits 0 on a clean `npm ci`, and no existing test file gains an environment directive.
- [ ] The `// @vitest-environment jsdom` opt-in is demonstrated to work on a single throwaway or scaffold case, so task-053 does not discover the mechanism is unavailable.
- [ ] No `vitest.config.*` file is introduced -- the opt-in is per-file, so the runner's default stays `node` and no other suite's environment changes.
- [ ] No script key is added to `package.json` and the `prebuild` / `predev` chains are byte-unchanged.
- [ ] The configuration is idempotent: re-running install produces no further change.
- [ ] No secret, token or credential appears in plaintext.
- [ ] **The owner's answer to feature-006 OQ-1 is recorded in `deliveries/delivery-005/STATE.md`**, either way, before this task is Done.
- [ ] If the owner declined, this task and every remaining delivery-005 task are `Canceled` with the reason recorded, `package.json` is left byte-unchanged, and the delivery is dropped rather than partially shipped.
- [ ] All section-6 quality gates pass
