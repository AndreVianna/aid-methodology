---
name: aid-test
description: >
  Run a test suite / verification NOW and consolidate the results into findings,
  in one pass. Generic: it runs whatever the request implies -- unit/integration/
  e2e, a security scan (SAST/DAST/fuzz/dependency-audit), a performance
  benchmark/load/stress test, a data-quality check (schema/freshness/completeness/
  uniqueness), or a model evaluation -- and reports. It RESOLVES NOTHING and is
  read-only on the source: findings hand off to /aid-fix; it never fixes. The
  skill runs the tool itself (read-only); consolidation + verification are done by
  the aid-reviewer agent (review-shaped).
  Allocates a work-NNN folder. To AUTHOR test code, use /aid-create-test (a
  keep-cycle create-family skill), not this.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
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
- **Behavior contract:** `.aid/work-005-lite-skills-refactor/specs/aid-test.md`.

State machine: **INTAKE -> RUN -> VERIFY (loop) -> PRESENT [human] -> HANDOFF? -> DONE**.
Print the `[State: NAME] -- {purpose}` entry line on each state.

---

## State: INTAKE

1. **Require a target.** Empty argument -> ask one bootstrapping question ("What should I
   test or verify?") and wait.
2. **Determine the verification kind** from the request (or the kind a sibling bound):
   functional (unit/integration/e2e), **security** (SAST/DAST/fuzz/dependency-audit),
   **performance** (workload/threshold/environment), **data-quality** (schema/freshness/
   completeness/uniqueness), or **model-eval** (run the eval harness, assert metric vs
   threshold). The framework is inferred from the KB (`test-landscape.md`).
3. **Pick the path:** **Fast** -- a clear target + kind ("run the security scan on the auth
   module", "benchmark the /orders endpoint vs the p99 SLO") -> run now. **Guided** -- vague
   -> scope target / kind / threshold first.
4. **Classify complexity (model + effort):** simple run -> `aid-reviewer` at **sonnet /
   medium**; deep security/perf analysis -> **opus / high**. Verifier tier >= producer.
5. **Consult the Work Initiation Gate, then allocate the work folder + STATE.** First run
   the gate (`.codex/aid/templates/work-initiation-gate.md`):
   `bash .codex/aid/scripts/works/enumerate-works.sh` (main tree + every git worktree).
   Empty -> allocate, no prompt. Works exist -> ask new-vs-continuation; on **continuation**
   route to the chosen work's resume door and STOP (allocate nothing); on **new work**
   allocate (`pipeline.path: lite`, `initiator: aid-test`, `lifecycle: Running`,
   `active_skill: aid-test`; `phase` not driven).

**Advance:** RUN.

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
3. **Grade:** `bash .codex/aid/scripts/grade.sh --explain <ledger>`. Not clean -> loop
   to RUN/consolidate. Circuit-breaker: 3 cycles -> IMPEDIMENT + `lifecycle: Blocked`.

**Advance:** PRESENT.

---

## State: PRESENT  (hard stop -- human)

Set `lifecycle: Paused-Awaiting-Input`. Present the consolidated findings, severity-ranked,
each with its evidence; state pass/fail against any threshold; and a printed suggestion:
"N issues found -- run `/aid-fix` to address them." Assert no resolution.

**Advance:** HANDOFF (optional) then DONE.

---

## State: HANDOFF  (optional; printed suggestions only)

Printed suggestions: `/aid-fix` (address findings), `/aid-create-test` (add regression tests
for a bug found), `/aid-change*` (if a fix is a real change). Never auto-invoked.

**Advance:** DONE.

---

## State: DONE

Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row. Leave the
findings ledger on disk for `/aid-fix`. Keep the work folder as the audit record.

---

## Constraints

- **Runs, does not author** -- test authoring is `/aid-create-test` (keep-cycle); this only
  runs + reports.
- **Read-only** on the source; never fixes (findings -> `/aid-fix`).
- **Resolves nothing**; presents consolidated findings.
- **Clean context**; the controlling agent runs the tool itself (read-only, via Bash),
  and **consolidation + verification are `aid-reviewer` sub-agent dispatches** (clean
  context) -- the findings are never graded inline.
- **Tracking:** write STATE `lifecycle` at every transition.
