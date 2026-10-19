---
name: aid-test
description: >
  Run tests or checks and report the findings. Use when something must be verified.
allowed-tools: Read Glob Grep Bash Shell Terminal Write Edit Agent
argument-hint: "<target> -- what to test/verify (a suite/module, or a kind: security, performance, data-quality, model-eval)"
---

# Test (run + consolidate, resolve nothing)

`/aid-test` **runs** the requested verification and consolidates the results -- it does not
*author* tests (that is `/aid-create-test`, a keep-cycle create-family skill). It is
**review-shaped**: run-a-tool is the evidence-gathering step, and consolidating results into
severity-tagged findings that hand off to `/aid-fix` is exactly the `/aid-review` shape --
so this **reuses `aid-review`'s machinery** (work folder, 7-column ledger, clean-context
verify, present, printed-suggestion handoff). The three `test-*` kind-siblings
(`/aid-test-security`, `/aid-test-performance`, `/aid-test-data-quality`) delegate here.

- **Read-only** on the source; never fixes (findings -> `/aid-fix`).
- **Not a numbered pipeline phase**; does not route to `/aid-execute`.

State machine: **INTAKE (-> INTAKE-ASK?) -> ALLOCATE -> RUN -> VERIFY (loop) -> PRESENT [human] ->
HANDOFF? -> DONE**.
Print the `[State: NAME] -- {purpose}` entry line on each state.
Steps, hand-offs and the work record follow [`skill-steps.md`](../../aid/templates/skill-steps.md).

---

## State Detection

**Detection shapes the entry step and validates a saved step, and never routes** (`skill-steps.md`, § State Detection). A fresh start enters INTAKE. A resume continues at the step the work record saves, which the gate's § 3b routes to; the saved step's artifact is checked against disk, and a mismatch goes to recovery, never to a silent re-route.

---

## State: INTAKE

INTAKE and INTAKE-ASK run before the work record exists, so they save no steps (`skill-steps.md`, § Before a work exists).

1. **Check the target.** Note whether the argument is empty. Do not ask here.
2. **Determine the verification kind** from the request (or the kind a sibling bound):
   functional (unit/integration/e2e), **security** (SAST/DAST/fuzz/dependency-audit),
   **performance** (workload/threshold/environment), **data-quality** (schema/freshness/
   completeness/uniqueness), or **model-eval** (run the eval harness, assert metric vs
   threshold). The framework is inferred from the KB (`test-landscape.md`).
3. **Pick the path:** **Fast** -- a clear target + kind ("run the security scan on the auth
   module", "benchmark the /orders endpoint vs the p99 SLO") -> run now. **Guided** -- vague
   -> scope target / kind / threshold first, in INTAKE-ASK.
4. **Classify complexity (model + effort):** simple run -> `aid-reviewer` at **sonnet /
   medium**; deep security/perf analysis -> **opus / high**. Verifier tier >= producer.
5. **Check for works.** Run `bash .aid/runtime/scripts/works/enumerate-works.sh`
   (main tree + every git worktree). Note whether any exist. Do not prompt here.

**Advance:** CHAIN -> [State: INTAKE-ASK] when any of these holds: the argument is empty, the path is Guided, works exist; otherwise CHAIN -> [State: ALLOCATE].

---

## State: INTAKE-ASK  (only when a question must be put)

Ask one topic at a time, through the question protocol, in this order and only for what applies:

1. **Empty argument** -> the bootstrapping question ("What should I test or verify?"). The
   answer is the target; the path and complexity are then set from it.
2. **Guided path** -> scope target / kind / threshold.
3. **Works exist** -> the gate's new-vs-continuation question with the enumerated list.

**Advance:** ASK -> [State: ALLOCATE].

---

## State: ALLOCATE

Allocate the work through the gate: the Work Initiation Gate
(`.aid/runtime/templates/work-initiation-gate.md`).

- **New work:** call the gate's `§ 3a` with the user's words, this skill's name (`aid-test`), its saved step (`RUN`), the step the work continues at once it exists (INTAKE and INTAKE-ASK run before the record and save nothing), `--path lite`, and a kebab-case slug from the target. The gate's `§ 3a` step 2 creates and enters the worktree (`worktree-lifecycle.sh create <work-id> <name>`),
  **then** allocate (`.aid/works/<work-id>-<slug>/`) the work folder and write its record through
  the writer, before it hands back: "`STATE.yml` was created by the gate;
  skip any instruction to write `initiator`, `active_skill`, `lifecycle` or `phase` by hand;
  set other keys through the writer." This skill drives no `phase`. When `/aid-orchestrate`
  passed an `intent:` block, the gate's `--create` has already written its `reading` and `depth`; the record is never written by hand, so the rest of the block stays in the conversation (`.aid/runtime/templates/shortcut-engine.md`); a typed `/aid-test` writes none.
- **Continuation:** On continuation, follow the gate's § 3b: enter the chosen work's worktree and run the skill its record names, at its saved step.

Every `--step` call in this skill passes in its `--detail` the verification kind, including one a sibling bound, so a
  resume finds it in the record.

**Advance:** CHAIN -> [State: RUN].

---

## State: RUN

Execute the verification **read-only** (Bash: the test runner, scanner, benchmark, or
data-quality check per the kind; never mutate the source), capturing raw output. Then
dispatch **`aid-reviewer`** (clean context, tiered) to **consolidate** the raw results into
the global 7-column findings ledger (`reviewer-ledger-schema.md`) at
`.aid/.temp/review-pending/<work>-test.md`, applying the kind's guidance -- security:
SAST/DAST/fuzz/audit findings + severity; performance: measured-vs-threshold with the
workload/environment noted; data-quality: per-check pass/fail with thresholds; functional:
pass/fail + failures; model-eval: metric vs threshold. Every finding cites its evidence
(the run output + a `file:line` where applicable).

**Advance:** VERIFY.

---

## State: VERIFY

1. **Mechanical grounding check** (no dispatch): every finding cites run output / a
   `file:line`; a metric/threshold finding states its threshold + measured value.
2. **Adversarial verification** -- a clean-context **`aid-reviewer`** checks the ledger:
   findings real and grounded in the run output, correctly severity-tagged, no
   over/under-statement, and the run actually exercised the stated scope. Writes a
   review-quality ledger to `.aid/.temp/review-pending/<work>-verify.md`.
3. **Grade:** `bash .aid/runtime/scripts/grade.sh --explain <ledger>`. Not clean -> loop
   to RUN/consolidate. Circuit-breaker: 3 cycles -> IMPEDIMENT, and the lifecycle set to `Blocked` through the writer.

**Advance:** PRESENT.

---

## State: PRESENT  (hard stop -- human)

The hard stop follows the ASK step of `skill-steps.md`. Present the consolidated findings, severity-ranked,
each with its evidence; state pass/fail against any threshold; and a printed suggestion:
"N issues found -- run `/aid-fix` to address them." Assert no resolution.

**Advance:** ASK -> [State: HANDOFF].

---

## State: HANDOFF  (optional; printed suggestions only)

Printed suggestions: `/aid-fix` (address findings), `/aid-create-test` (add regression tests
for a bug found), `/aid-update*` (if a fix is a real change). Never auto-invoked. Ask which one,
if any, the user takes; a picked one is named in one plain line.

**Advance:** ASK -> [State: DONE].

---

## State: DONE

Finish through the writer: `bash .aid/runtime/scripts/execute/writeback-state.sh --pipeline --field Lifecycle --value Completed`, which also clears the saved skill and step. Leave the findings ledger on disk for `/aid-fix`. Keep the work folder as the audit record.

**Advance:** HALT.

---

## Constraints

- **Runs, does not author** -- test authoring is `/aid-create-test` (keep-cycle); this only
  runs + reports.
- **Read-only** on the source; never fixes (findings -> `/aid-fix`).
- **Resolves nothing**; presents consolidated findings.
- **Clean context**; the controlling agent runs the tool itself (read-only, via Bash),
  and **consolidation + verification are `aid-reviewer` sub-agent dispatches** (clean
  context) -- the findings are never graded inline.
- **Tracking:** every record change goes through the writer (`skill-steps.md`, § The work record).
