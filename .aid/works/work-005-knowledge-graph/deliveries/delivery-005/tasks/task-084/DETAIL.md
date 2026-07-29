# task-084: `validate-visuals.mjs --profile graph` T2 exclusion

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

**Source:** work-005-knowledge-graph -> delivery-005

**Depends on:** task-082, task-086

**Scope:**
- **Conditional (feature-011 § D3 contingency C2). Firing condition:** this task fires **only if**
  delivery-001's rendering decision selected an **SVG** live drawing surface.
  `validate-visuals.mjs`'s collector takes `.diagram-box`, `.infographic`, and every outermost
  `<svg>` not inside one of those -- so an SVG surface is collected and **T2** (sibling `<g>`
  bounding boxes may not overlap by more than 20% of the smaller area) collides by design, because
  overlapping semantic groups are what a graph layout *is*. A `<canvas>` or WebGL surface matches
  none of the collector's selectors, is not collected, and needs no exclusion at all. The trigger
  evidence is task-075's contingency determination read against the live surface this delivery
  ships.
- If it fires, amend **exactly one script**:
  `canonical/aid/scripts/summarize/validate-visuals.mjs` gains
  `--profile kb-summary|graph`, where `graph` reports **T2** as `[N/A]` with its printed reason.
- **The exclusion is scoped to the one marked element.** T2 is waived **only** for the single
  element carrying the live-surface marker class. `T1` (rendered font-size >= 10 px and not
  zero-height-clipped), `T3` (non-trivial bounding rect) and `T4` (no horizontal overflow at
  732 px and 390 px) remain enforced **on that same element**, and all four remain enforced on
  every other collected visual. A label under 10 px or a clipped region is a real legibility
  defect, not a design collision, and the fix is to render it larger, not to stop measuring it.
- Add the live-surface marker class to the graph's drawing surface so the exclusion has a concrete
  element to bind to. **The class name is fixed by owner decision (2026-07-28) as
  `graph-live-surface`** — feature-011 waives T2 "for the single element carrying the live-surface
  marker class" but never names the token, and both this task and `validate-visuals.mjs`'s profile
  table must agree on it, so it is not left to the executor.
- **This task depends on the render barrier (task-086) and must re-render after editing.**
  *(Owner correction 2026-07-28.)* The firing condition is a T2 failure on the **live** surface, which
  cannot be observed until the canvas exists and the artifact has been rendered — task-075 determined
  the contingency in delivery-004 against a `graph.html` that had no canvas at all. And because this
  task edits a canonical script *after* delivery-005's CONFIGURE render barrier, it must run the FULL
  generator itself and leave `git diff --exit-code -- profiles/` clean, or the profile trees ship
  stale. Same obligation task-076 carries in delivery-004.
- **Keep the five properties that make this parameterised rather than weakened** (feature-011
  § D3): `kb-summary` is the default so `kb.html`'s behaviour is byte-unchanged and the existing
  CI call site (`validate-visuals.mjs <html>`) is not edited; the profile table lives **once**, in
  the script header, as a closed set, and an unrecognised value exits `2`; each profile waives
  exactly one **named** check, not a category or a severity band; the waiver is scoped to an
  element rather than a page; and a waived check prints why it was waived, so the policy in effect
  is visible in the validation log.
- **Out of scope:** the `S2` carve-out on `validate-html-output.sh` (contingency C1, task-076);
  `grade-summary.sh`, untouched either way; and any widening of the profile beyond T2.
  `test-validate-visuals-profiles.sh` (task-085) is **inseparable** from this task -- an amended
  validator without its golden-output suite is exactly the unproven carve-out feature-011 § D4
  exists to prevent -- and must land with it.

**Acceptance Criteria:**
- [ ] **If delivery-001 did not select an SVG live drawing surface, this task is a recorded no-op
      and the gate records why**, citing the decision record and task-075's trigger evidence. No
      shared validator is edited.
- [ ] `--profile graph` reports T2 as `[N/A]` with a printed reason, for the marked live-surface
      element **only**.
- [ ] `T1`, `T3` and `T4` still fail the marked element when it violates them.
- [ ] An unmarked `.diagram-box` on the same page is still checked on all four of T1-T4.
- [ ] Omitting `--profile` selects `kb-summary`, and the existing CI call site in
      `.github/workflows/test.yml` is not edited.
- [ ] An unrecognised `--profile` value exits `2` -- the usage-error code per
      `.aid/knowledge/coding-standards.md` § Exit Codes and the code the script already returns
      for an unknown flag.
- [ ] The profile table is declared once, in the script header, as a closed set, so a third policy
      cannot be introduced at a call site.
- [ ] `bash tests/canonical/test-guardrails-d012.sh` passes **unmodified**.
- [ ] All existing canonical suites still pass; the named suite lands in **task-085**, which must
      land together with this task and never separately.
- [ ] Build passes: `node canonical/aid/scripts/summarize/validate-visuals.mjs` runs on both
      profiles without a syntax or usage error.
- [ ] `.aid/knowledge/coding-standards.md` JS/Node conventions are honoured, and the script is
      edited under `canonical/` only -- no rendered copy is hand-edited.
- [ ] The reviewer ledger for this task carries no finding with Status `Pending` or `Recurred`, so
      the delivery gate's `grade.sh` run over `.aid/.temp/review-pending/` reaches this
      repository's resolved `A+` (`review.minimum_grade`; `.aid/knowledge/quality-gates.md`
      § Minimum-Grade Thresholds).
