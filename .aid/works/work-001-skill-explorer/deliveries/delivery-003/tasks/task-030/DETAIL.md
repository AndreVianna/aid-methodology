# task-030: Sidecar emission, `shapeCounts` and the extended drift guard

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-030. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-030/STATE.md.
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

**Type:** IMPLEMENT

**Source:** work-001-skill-explorer -> delivery-003 (feature-003-authored-flow-charts)

**Depends on:** task-019, task-029

**Scope:**
- Implement task-019's **seam 1 (S3)** and **seam 2 (`shapeCounts`)** inside `site/scripts/gen-skills.mjs` -- **a file created by task-012 and last edited by task-015, both in delivery-002.** This task is delivery-003's only edit to it; nothing here may run concurrently with a delivery-002 task.
- Write one `<skill>.flow.json` sidecar per skill to `site/src/data/skill-flows/`, serialized by `serializeChart` from task-020. That location is chosen on two independent grounds: it must sit **outside** the docs content collection, or a non-page file there is parsed as content or breaks the collection; and `site/src/data/` is the site's existing home for data modules that components consume, which is exactly what the sidecar needs -- readable by Node at build time for feature-005 and importable from an Astro component for feature-006. `site/public/` is fetch-only and `site/scripts/` is not importable from a component, so each fails one side.
- Add the `shapeCounts` key to `site/scripts/.skills-manifest.json`, computed from the live classifier. **This is the only authority in the repo for how many skills are of each shape** -- no page, no test and no KB document may state a per-shape number except by reading it from here.
- Extend the drift guard exactly as task-019's seam-1 decision directs, and update AC-1's error message to match whatever that decision was.
- Delivery-002's guarantees must survive this edit unchanged.

**Acceptance Criteria:**
- [ ] One sidecar is written per skill at `site/src/data/skill-flows/<skill>.flow.json`, and its bytes equal `serializeChart(chart)` exactly -- fixed key order, two-space JSON, one trailing newline, LF only.
- [ ] `shapeCounts` is present in `.skills-manifest.json`, computed from the live classifier over the live directory scan, and **contains no literal**; the shape keys are the five classifier values.
- [ ] The drift guard behaves exactly as task-019's seam-1 decision directs, and AC-1's error message matches that decision.
- [ ] The manifest still carries **no `generatedAt`** and no wall-clock value, and every path in it is a POSIX string built by concatenation.
- [ ] Two consecutive generator runs produce byte-identical pages, sidecars and manifest.
- [ ] **Delivery-002's guarantees still hold:** AC-1 still throws in both directions, AC-2 and AC-8 pass unchanged, `gen-reference.mjs` is byte-unmodified with its drift guard passing, and its four generated pages plus `.reference-manifest.json` are byte-unchanged.
- [ ] stdout remains **exactly four lines** per successful run -- feature-001's contract is not widened by sidecar or `shapeCounts` emission -- and stderr is silent on success.
- [ ] No per-shape count is emitted to stdout or written into any page.
- [ ] Unit tests exist for the sidecar write, the `shapeCounts` computation and the extended guard; all existing tests still pass; the build passes.
- [ ] All section-6 quality gates pass
