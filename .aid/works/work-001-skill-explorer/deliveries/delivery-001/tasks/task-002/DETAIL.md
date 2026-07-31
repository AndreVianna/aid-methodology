# task-002: Clean-install triage record for the whole `site/` vitest suite

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-002. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-002/STATE.md.
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

**Type:** RESEARCH

**Source:** work-001-skill-explorer -> delivery-001 (feature-001-skill-detail-pages)

**Depends on:** task-001

**Scope:**
- On a clean `npm ci` in `site/`, run `npm test` and a full `npm run prebuild`, and produce a triage record covering all eight test files: `site/scripts/__tests__/fetch-release-data.test.mjs`, `gen-reference.test.mjs`, `sync-docs.test.mjs`, and the five TypeScript suites that have never executed in CI -- `site/src/data/__tests__/ac13-version-injection.test.ts`, `site/src/data/__tests__/version.test.ts`, `site/src/lib/__tests__/feature-009-releases-banner.test.ts`, `site/src/lib/__tests__/feature-010-feedback.test.ts`, `site/src/lib/__tests__/release-data.test.ts`.
- Classify each failure as (a) a stale assertion of KI-005's class, (b) environmental (the `[TSCONFIG_ERROR] Tsconfig not found` load failure and the two `git diff`-based idempotency failures both clear under a clean `npm ci` / a resolvable checkout), or (c) a real defect.
- Route every finding explicitly: absorb into task-003, or escalate to the owner as a gate escalation. This is delivery-001's escalation valve -- nothing is silently absorbed.
- Verify, on the same clean install, that `gen-reference.mjs` is byte-unmodified, its throw-on-drift guard passes, and its four generated pages plus `.reference-manifest.json` are byte-unchanged after the full `prebuild`.
- **This task changes no file.** It produces the triage record only; remediation is task-003's and CI wiring is task-004's.

**Acceptance Criteria:**
- [ ] All eight test files are enumerated with a load status and a pass/fail verdict measured on a clean `npm ci`; none is left "unknown" or "did not load".
- [ ] Every failure carries a cited cause -- file and line, or the runner's own message verbatim -- and exactly one of the three classifications.
- [ ] Every finding carries an explicit route (absorb into task-003, or escalate) with a one-line reason. No finding is left unrouted.
- [ ] `npm run prebuild` completes on the clean install; `gen-reference.mjs` is byte-unmodified, its drift guard passes, and its four generated pages plus `.reference-manifest.json` are byte-unchanged.
- [ ] The record states plainly whether `npm test` exits 0 as-is for the whole suite; if not, it quantifies exactly what stands between the current state and that outcome.
- [ ] No file under `site/` or `.github/` is modified by this task.
- [ ] Sources are cited for every claim (command run, exit code, file and line).
- [ ] The recommendation is actionable: each route names its destination task or names the owner escalation. *(The RESEARCH default "at least 2 alternatives compared" is deliberately overridden -- a triage has findings, not options; the sources-cited and actionable-recommendation defaults are kept and sharpened above.)*
- [ ] All section-6 quality gates pass
