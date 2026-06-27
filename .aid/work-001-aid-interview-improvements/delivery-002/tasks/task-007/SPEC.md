# task-007: verify T4 catches a responsive clip + wire suite (M4 test)

**Type:** TEST

**Source:** work-001-aid-interview-improvements -> delivery-002

**Depends on:** task-006

**Scope:**
- Extend the EXISTING canonical suite **`tests/canonical/test-visual-fidelity.sh`** (do NOT create a
  new suite -- it already exercises `--check-only` and invocation-error paths with a Playwright
  graceful-skip). Add, per feature-007 M4:
  - (a) a `--check-only` assertion that **T4 appears in the documented check list** (no Playwright
    needed -- runs always);
  - (b) guarded by Playwright availability (matching the existing graceful-skip), a **positive case**
    (a within-bounds visual passes T4) and a **negative case**: a deliberately over-wide fixture that
    **FAILS T4 at 732px / 390px while still PASSING T1-T3 at the wide viewport** -- proving T4 catches
    what T1/T2/T3 miss.
- The clip demonstration MUST be **Playwright-rendered**, not source-inspected (global web-visual
  rule + M4 closure: "the demonstration that T4 catches a real clip must be Playwright-rendered").
- The over-wide fixture is a controlled, committed input (deterministic), not a flaky live page;
  clean setup/teardown.
- Confirm the suite is registered so it runs under `test.yml` (PR-gated to master) as today.

**Acceptance Criteria:**
- [ ] `test-visual-fidelity.sh` gains a `--check-only` assertion that T4 is in the check list (runs without Playwright). *(M4 plug-in points)*
- [ ] A Playwright-rendered negative case demonstrates the over-wide fixture FAILS T4 at 732/390 while PASSING T1-T3 at the wide viewport; a positive case passes T4. *(M4 closure; global web-visual rule)*
- [ ] The over-wide fixture is committed + deterministic; tests use clean setup/teardown and the existing Playwright graceful-skip. *(TEST default)*
- [ ] All of feature-007 M4's acceptance is covered: gate FAILS on a visual clipping at 732/390 and PASSES the current in-spec `kb.html`. *(M4 closure)*
- [ ] Suite runs under `test.yml` on PRs to master; local `tests/run-all.sh` (HOME-pinned) + the `site` build stay green. *(master-CI-only-on-master constraint)*
- [ ] All REQUIREMENTS.md §6 quality gates pass.
