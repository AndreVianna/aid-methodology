# task-076: `validate-html-output.sh --profile graph` S2 carve-out

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

**Source:** work-005-knowledge-graph -> delivery-004

**Depends on:** task-075

**Scope:**
- **Conditional (feature-011 contingency C1).** This task fires **only if** delivery-001's
  rendering decision (FR-18) selected delivery that genuinely fetches from an external origin, as
  evidenced by task-075 recording an `S2` failure against the real `graph.html`. Under the
  reference local-vendored layout it does not fire.
- When it fires: add `[--profile kb-summary|graph]` to
  `canonical/aid/scripts/summarize/validate-html-output.sh`, with `kb-summary` as the default, so
  that the `graph` profile differs from `kb-summary` in **exactly one** check -- `S2` reported
  `[N/A]` with its printed reason.
- **Out of scope:** every other check, in particular all three `NM` sub-checks, which stay
  enforced for both profiles unconditionally (the earlier NM.1 waiver was withdrawn as a
  correctness fix); `grade-summary.sh` and the CI `validate-visuals.mjs` call site, neither of
  which is edited; `validate-visuals.mjs`'s own T2 exclusion (contingency C2, task-084 in
  delivery-005); the golden-output suite that guards this change (task-077).

**Acceptance Criteria:**
- [ ] **If task-075 did not record an `S2` failure -- i.e. FR-18 did not select external delivery
      -- this task is a recorded no-op**: no file is edited, and the gate records why, citing
      task-075's determination as the evidence.
- [ ] When it fires: `kb-summary` is the default profile, so `grade-summary.sh`'s existing
      `bash "$SCRIPT_DIR/validate-html-output.sh" "$HTML"` call site is **untouched** and
      `kb.html`'s assertion set, output text and exit status are byte-unchanged.
- [ ] The `graph` profile waives **exactly one named check**: `S2`. Every other check, including
      `NM.1`, `NM.2` and `NM.3`, behaves identically under both profiles.
- [ ] The waived check prints its reason rather than passing silently -- the line reads
      `S2. Offline render [N/A] external assets permitted for profile 'graph'` -- which is also how
      AC-6's prerequisite disclosure is discharged at validation time.
- [ ] The profile table lives **once**, in the script header, as a closed set; an unrecognised
      `--profile` value exits **2** (usage error, per `coding-standards.md` § Exit Codes), so a
      third policy cannot be introduced at a call site.
- [ ] `bash tests/canonical/test-guardrails-d012.sh` passes **unmodified** after the change (D4
      proof 2).
- [ ] The golden-output suite proving the default path is byte-unchanged and the profile differs
      by one line lands in **task-077**; the two are inseparable (feature-011 Feature Flow steps
      2-3), and an amended validator without its suite is exactly the unproven carve-out D4 exists
      to prevent. *(This is the stated override of the IMPLEMENT default "unit tests for all new
      public methods": the vehicle is that named suite.)*
- [ ] All existing canonical suites still pass.
- [ ] Build passes: because the edited file is canonical, a FULL generator run plus
      `git diff --exit-code -- profiles/` is re-run and recorded here -- no render task follows
      task-069 inside this delivery, so this task carries that obligation when it fires.
- [ ] The code baseline of `.aid/knowledge/coding-standards.md` and `.aid/knowledge/quality-gates.md`
      holds, and the delivery gate's `grade.sh` run over `.aid/.temp/review-pending/` reaches the
      resolved `review.minimum_grade` of **A+** -- zero findings with Status `Pending` or
      `Recurred`.
