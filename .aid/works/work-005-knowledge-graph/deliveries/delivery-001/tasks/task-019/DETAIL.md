# task-019: Parameterise the three reused validators with --profile

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-019/STATE.md.
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

**Source:** feature-011-validator-parameterisation -> delivery-001 (Wave 3)

> **RECORDED DEVIATION, with its mitigation — read before splitting any commit.** feature-011's SPEC
> `:453–:455` states: "**Land the suite in the same change.** Steps 3–5 and the suite are inseparable:
> an amended validator without its assertions is the unproven carve-out D5 exists to prevent, and a
> plan that schedules them apart should be rejected." This task and `task-020` **do** schedule them
> apart, and the reason is a hard schema constraint, not a preference: a task carries exactly one
> Type, and an amendment (IMPLEMENT) plus its suite (TEST) cannot share one. Rather than let the
> conflict stand silently, it is resolved in favour of the SPEC's *intent*: **the two tasks are one
> commit.** `task-020` depends on this task, both sit in gate wave 3, and neither may be committed
> without the other — so no amended validator ever exists in history without its assertions, which is
> the property `:453` is protecting. The task boundary here is a **review** boundary, not a commit
> boundary.

**Depends on:** task-011, task-013

**Scope:**
- **Not started.** Verified on disk: `canonical/aid/scripts/summarize/validate-html-output.sh` and
  `canonical/aid/scripts/summarize/contrast-check.mjs` contain **zero** graph references;
  `validate-visuals.mjs`'s eleven "graph" hits are all `.infographic` substring matches, not graph
  support; and none of the three parses a `--profile` flag.
- Add `--profile kb-summary|graph` to all three, per D1's six properties: flag absence selects
  `kb-summary` **byte-identically**; the closed value set lives once per script, in its header; an
  unrecognised value exits **2** as a usage error naming the closed set; the active profile prints
  **only** when the flag is passed explicitly; a delta names checks, never categories; and a waived
  check prints why (`S2. Offline render [N/A] external assets permitted for profile 'graph'`), never
  a silent pass.
- D2's per-check reading of `validate-html-output.sh` against `graph.html`; D3's contrast-checker
  work including **the one deliberate default-path exception** — the dark-theme extraction
  correction, which applies to both profiles, so `kb.html`'s dark block reports the dark values it
  always should have; D4's `validate-visuals.mjs` handling including the two paths that pass without
  checking.
- **Depends on task-011** (BLUEPRINT edge 2 — the `S2` carve-out's firing condition is read off the
  decision record) **and task-013** (the carve-outs cannot be exercised until `graph.html` exists).

**Acceptance Criteria:**
- [ ] The two existing call sites are **not edited**: `grade-summary.sh:263` and
      `grade-summary.sh:348` each still pass the artifact path alone
- [ ] Default-path output is byte-identical except the named contrast exception, whose baseline is
      **re-taken** and whose substance is asserted instead — byte-identity matters because
      `grade-summary.sh` derives `S2`, `NM`, `L1`, `L2`, `C1` and `C2` by grepping emitted text, so a
      wording change can move a grade without moving a verdict
- [ ] The no-runtime-engine assertion is enforced in **all three sub-checks, unconditionally, for
      both artifacts**
- [ ] Every graph palette token resolves in **both** themes and is checked at the 3:1 target SC 1.4.11
      sets; a token that fails to resolve is a **failure**, not a skipped warning
- [ ] Any reused check whose input set can be empty reports a zero-sized input set as such and does
      **not** produce a pass
- [ ] Missing Playwright or a missing artifact degrades with an actionable message, records the skip
      rather than swallowing it, and lets the run continue (PV19)
- [ ] An unrecognised profile value exits 2 with a usage error naming the closed set, so a third
      policy cannot be introduced at a call site
- [ ] `--help` output and header comments match actual behaviour for every flag they document
- [ ] `graph.html` is validated only under `--profile graph`; no waiver names a category, a severity
      band or a check family
- [ ] C-5's WebGL-context mode is **not** claimed as covered here — no reused validator requests a
      context, so none can observe it; the routing is recorded rather than implied
- [ ] **All existing tests still pass** (IMPLEMENT type-default, `task-decomposition.md`:175). Named
      explicitly because this task touches surfaces shared beyond this work's own suites, so a
      regression can land where the graph suites do not look: run the affected suites, not only the
      `test-graph-*` set. Use `tests/canonical/select-suites.sh --run` to pick them by change set
- [ ] All section-6 quality gates pass
