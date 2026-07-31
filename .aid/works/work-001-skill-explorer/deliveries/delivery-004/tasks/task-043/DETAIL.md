# task-043: `## Source fragments` appender registration

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-043. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-043/STATE.md.
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

**Source:** work-001-skill-explorer -> delivery-004 (feature-005-verbatim-source-provenance)

**Depends on:** task-041, task-042

**Scope:**
- Create `site/scripts/lib/provenance/index.mjs` exporting `provenanceAppender = { id: 'source-fragments', render(skill) }`, and add **exactly one entry** to `BODY_APPENDERS` in `site/scripts/skills/body.mjs` -- a file created by task-010 in delivery-002 and last edited by task-037 in delivery-003. Nothing else in that file is modified, including either `BODY_PROVIDERS` entry.
- `render(skill)` runs four steps in this fixed order: call feature-003's `buildFlowChart({ name: dirName, dir })` memoized per directory for the run; `verifyProvenance(chart)`; `buildEntries(chart)`; `renderFragmentList(entries)`.
- **Verification runs before any markdown is produced for that skill**, so a bad range can never be written into a page. A failure is an uncaught throw: the process exits non-zero, feature-001's drift guard never runs, `prebuild` fails and `npm run build` fails -- the same blast radius feature-001 specifies for its own guards.
- `render(skill)` takes feature-001's `SkillRecord` and uses exactly two of its fields: `dirName` and `sourcePath`. It deliberately does **not** use `bodyStartLine` / `lineCount`, even though feature-001 added them anticipating this feature: a node's provenance may cite a `references/state-*.md` worker or `canonical/aid/templates/shortcut-engine.md`, not only that skill's `SKILL.md`, so range verification must read whichever file is cited rather than trust a per-skill line count.
- The section is emitted **unconditionally, for every skill**, and is never gated on a script having run. That is a constraint feature-005 places on feature-006 and the reason AC-5 survives KI-004's no-JavaScript degradation; delivery-005 must not make its presence conditional.
- **stdout is unchanged.** feature-001 fixes "exactly four lines per successful run"; an appender that logged would break it, and per-node logging is out of the question at corpus scale.
- Ownership: everything under `site/scripts/lib/provenance/` is this feature's; `body.mjs` stays feature-001's file; `paths.mjs` is consumed read-only. No file owned by feature-002, 003, 004 or 006 is touched.

**Acceptance Criteria:**
- [ ] `verifyProvenance` runs **before** any markdown is produced for that skill, verified by asserting that a chart with a bad range produces no page bytes at all.
- [ ] The appender uses only `SkillRecord.dirName` and `sourcePath`; `bodyStartLine` and `lineCount` appear nowhere in the module.
- [ ] `buildFlowChart` is memoized per directory name for the run, asserted by call count.
- [ ] The `## Source fragments` section is emitted **unconditionally for every skill** -- there is no code path that skips it, and no flag, config or environment value can suppress it.
- [ ] **Exactly one entry** is added to `BODY_APPENDERS`; `BODY_PROVIDERS` and every other line of `body.mjs` are untouched, verified by diff.
- [ ] `BODY_APPENDERS` remains a static array literal: no glob, no dynamic `import()`, no registration side effect.
- [ ] stdout remains **exactly four lines** per successful run and stderr is silent on success -- the appender logs nothing.
- [ ] An uncaught throw from verification exits non-zero and fails `prebuild` and `npm run build`.
- [ ] **Deliveries 001-003 still hold:** AC-1, AC-2, AC-3, AC-4, AC-6 and AC-8 all pass unchanged, and `gen-reference.mjs` remains byte-unmodified.
- [ ] No file owned by feature-002, 003, 004 or 006 is modified.
- [ ] Unit tests exist for the appender's ordering and its unconditional emission; all existing tests still pass; the build passes.
- [ ] All section-6 quality gates pass
