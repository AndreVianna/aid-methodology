# Behavioral Spec — test-family restructure (task-007)

> **Status:** LOCKED for implementation (design agreed 2026-07-15).
> **Tracked under:** `.aid/work-005-lite-skills-refactor/` (branch `work-005-lite-skills-refactor`).
> **Scope:** the 4 shipped `aid-test*` skills → split into a `test` **artifact** (authoring,
> keep-cycle) and a generic `aid-test` **run+consolidate** skill (collapse). Uses the
> collapse pattern ([`aid-review`](aid-review.md)) for the run side.
> **Not implemented yet.**

---

## 1. Problem

`aid-test` was split-identity — *authoring* test code (a committed mutation) and *running*
tests (analysis) wedged into one verb — because authoring test code had no create-family
home. The three `aid-test-*` were specialized *run* skills that (like every engine
shortcut) planned a run and halted, never running anything.

## 2. The restructure

| Skill | Behavior | Category | Topology |
|---|---|---|---|
| `aid-create-test` (+ `aid-add-test`) | author new tests | keep-cycle | NEW engine-driven create rows |
| `aid-change-test` (+ `aid-update-test`) | change existing tests | keep-cycle | NEW engine-driven change rows |
| `aid-test` | run **any** suite/verification + consolidate findings | **collapse** (review-shaped) | hand-authored, `repurpose` |
| `aid-test-security` / `-performance` / `-data-quality` | → hint-aliases of `aid-test` | collapse | backward-compat thin doorways |
| test removal | bare `aid-remove` / `aid-delete` | correct-as-is | (no new skill) |

## 3. Authoring — `aid-create-test` / `aid-change-test` (keep-cycle)

- **Engine-driven**, exactly like `aid-create-api` etc.: plan → halt → `/aid-execute`.
  **Not** `repurpose`. `default_type: TEST`, group **G7** (test domain, for discovery;
  verb drives behavior, group drives triage).
- **Executed by `aid-developer`** — test code is production code (it lands in CI). This is
  the standard create/change execution path; no special handling.
- **Naming:** `create`/`change` canonical, `add`/`update` aliases (shipped convention).
- **Scope:** authoring/extending test code with framework inference from the KB
  (`test-landscape.md`) and each test tracing to a specific acceptance criterion.

## 4. Running — `aid-test` (collapse, review-shaped)

- **Generic run-and-consolidate:** runs whatever verification the request implies — unit /
  integration / e2e, security scan (SAST/DAST/fuzz/audit), performance benchmark, data-
  quality check, or **model-eval** (run harness, assert metric vs threshold) — and
  consolidates results into the global 7-column findings ledger.
- **Producer/verifier = `aid-reviewer`** (clean context). Run-a-tool is just this skill's
  *evidence-gathering* step; consolidating results into findings + severity + a hand-off to
  `/aid-fix` **is** the review shape — so `aid-test` **reuses `aid-review`'s machinery**
  (work folder, ledger, VERIFY loop, present, printed-suggestion handoff).
- **Domain knowledge preserved as conditional guidance:** the three `test-*` hint-aliases
  each bind their kind, and `aid-test` applies the matching guidance —
  security (SAST/DAST/fuzz/audit), performance (workload/threshold/environment),
  data-quality (schema/freshness/completeness/uniqueness). Nothing is lost; only the skill
  count drops.
- **Read-only posture:** running tests never mutates the source; findings route to
  `/aid-fix`, never fixed here.
- **Tiering:** simple run → sonnet; complex (deep security/perf analysis) → opus; verifier
  tier ≥ producer.

## 5. Removal

Test removal/deprecate/migrate use bare `aid-remove` / `aid-deprecate` / `aid-migrate` —
no per-artifact remover exists anywhere in the catalog.

## 6. Scaffolding reorg (`test-experiment.md` splits)

- **Experiment** half → stays (task-004 adapts it in place).
- **Test-authoring** guidance (framework inference, coverage→AC traceability, test
  structure) → moves into the create/change family scaffolding as the `test` artifact.
- **Test-running** guidance (functional-run, security, performance, data-quality) →
  becomes `aid-test`'s own reference (the conditional per-kind guidance).

## 7. Files the implementation will touch

1. `shortcut-catalog.yml` — add `aid-create-test`/`aid-add-test`,
   `aid-change-test`/`aid-update-test` (engine-driven); set `repurpose: true` on `aid-test`
   + the three `aid-test-*` (now hint-aliases).
2. `canonical/skills/` — new `aid-create-test`/`aid-change-test` doorways (+ aliases,
   generated); hand-authored `aid-test` run body + the three `test-*` thin hint-aliases.
3. `shortcut-engine.md` — the `test` run rows detach; the `test` authoring artifact is
   engine-driven under create/change.
4. Scaffolding reorg per §6.
5. Regenerate: `build-shortcut-skills.py` → `run_generator.py` → dogfood resync.

## 8. Settled decisions

Resolved with the user 2026-07-15:

1. **Split** authoring (create/change-test, keep-cycle) from running (`aid-test`, collapse).
2. **`aid-test` generic run+consolidate**, review-shaped, producer `aid-reviewer`; the three
   `test-*` become backward-compat hint-aliases; domain knowledge preserved as conditional
   guidance; model-eval folds in.
3. **Authoring executed by `aid-developer`** via the standard create/change pipeline.
4. **Test-authoring scaffolding moves** into the create/change family references (§6).
5. Removal via bare `aid-remove` (no `aid-remove-test`).
