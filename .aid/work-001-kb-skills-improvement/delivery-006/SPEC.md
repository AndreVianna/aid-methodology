# Delivery SPEC -- delivery-006: Validation Fixture

[!NOTE]
This is the DELIVERY-LEVEL SPEC.md. It is the IMMUTABLE DEFINITION for this delivery.
Written by aid-plan; not a state file. State lives in delivery-006/STATE.md.

> **Delivery:** delivery-006
> **Work:** work-001-kb-skills-improvement
> **Created:** 2026-06-23

---

## Objective

Validate the whole overhaul against the **known failure case** and lock it against regression. Ship
a fixture project containing a planted 'Relative bus'-style coined concept -- a load-bearing native
concept of exactly the kind discovery silently missed before -- and a regression test asserting the
method **captures and defines it**, proving the essence-capture gap is closed. Add the closure
self-containment proof, the calibration-severity calibration (pinning f004's denylist/salience floor
and f005's CAL-N severity floors against planted fixtures), and the brownfield path fixtures that
prove correct triage classification and teach-back closure plus a greenfield-DETECTION fixture (recon
classifies a ~0-source tree as greenfield). This is the CI-anchored regression proof that the essence
engine works and stays working. Greenfield is **detection-only** — recon-classify DETECTS greenfield
and aid-discover signposts to `/aid-interview` and halts; there is **no greenfield generation path /
closure** to exercise, so no greenfield path-runs fixture exists (the former greenfield-path carve-out
-- the defunct pre-act-back greenfield-path delivery, NOT the current live delivery-009 Governance --
is deleted).

## Scope

In scope -- **feature-012, ENGINE + BROWNFIELD + greenfield-DETECTION scope** (greenfield is
detection-only; there is no greenfield path-runs fixture, as greenfield is detect-and-signpost):

- **AC1 -- teach-back closure fixture (TEST-C).** A teach-back pass-KB (every concept defined + the
  engine narratable) and fail-KB (a load-bearing concept undefined / the engine un-narratable) plus a
  regression suite (`test-teachback-fixtures.sh`) that runs f005's `kb-teachback-questions.sh` +
  f004's `closure-check.sh`, asserting the pass-KB yields a PASS verdict and the fail-KB a FAIL --
  including the **non-lexical engine-narration limb** (a FAIL even when every term is defined). This is
  **engine-validation**: it exercises f005's teach-back keystone gate, so it belongs to this delivery's
  engine scope.
- **AC2 -- 'Relative bus' regression.** A fixture with a planted coined concept + a regression test
  asserting capture-and-define (end-to-end, over delivery-001's harvest/spine/closure engine).
- **AC3 -- closure self-containment.** A proof that the KB produced for the fixture leaves no
  project-specific term undefined (concept closure passes), jointly with f004's `closure-check.sh`.
- **AC6 -- calibration tuning.** Planted transcription / hollowness / coverage-vs-source fixtures
  that f005's rubric must flag; this delivery is the executable oracle that pins f004's
  `[SPIKE-H2]` denylist/salience floor and f005's `[SPIKE-C1]` CAL-N severity floors.
- **AC7 -- brownfield path fixtures + greenfield DETECTION.** brownfield-small + brownfield-large
  fixtures that f006's triage must classify correctly and run to teach-back closure, PLUS a
  greenfield-DETECTION fixture (a ~0-source `project-index.md`) that recon-classify must classify as
  **greenfield** (classification only). Greenfield is detect-and-signpost — there is **no greenfield
  path-runs / greenfield-closure fixture** (no greenfield generation engine to exercise).
- **AC16 -- act-back fixture (the V-E family).** The end-to-end act-back fixture whose *shape* is
  defined by delivery-005 / feature-013 ([SPIKE-A5]): a **representative-task spec fixture** (a fixed
  `discovery.doc_set` shape over which delivery-005's `kb-actback-task.sh` emits a stable, well-formed
  representative task) + an **`actback-pass-kb`/`actback-fail-kb` pair** (the pass-KB carries the
  first-class operational sections the task needs; the fail-KB buries/omits them). The **V-E
  regression assertion family** (alongside f012's V-A..V-D) CI-asserts the **mechanical half**
  (`kb-actback-task.sh` emits the same task byte-reproducibly; the presence check reports the named
  operational sections **present** for `actback-pass-kb`, **absent** for `actback-fail-kb`); the
  **judgment half** (does the clean-context M6 plan succeed; are its insufficiency flags well-founded)
  is runtime-anchored, NOT a CI assertion, and is added as a new row to f012's Judgment-Boundary table.
  This mirrors exactly how this delivery builds the teach-back/calibration fixtures (mechanical limb
  CI-asserted, engine-narration/judgment limb runtime-anchored).

**Out of scope (no longer exists):** the **greenfield path-runs / greenfield-closure** fixture (the
former AC7-greenfield generation path). Greenfield was de-scoped to detect-and-signpost on 2026-06-23;
the former greenfield-path delivery (the defunct pre-act-back greenfield-path delivery that would have
held the greenfield path fixture -- NOT the current live delivery-009 Governance) is **deleted**. What
remains in scope
here is the greenfield-**DETECTION** fixture (classification only, above). The AC1 teach-back fixture is
**engine-validation and stays here**.
**Out of scope (elsewhere):** the scripts/mandates/recon themselves (delivery-001 f004/f005,
delivery-004 f006 -- f012 *exercises* them, it does not author or edit them). When a fixture proves a
default wrong, the default is changed in the owning feature's file and this delivery's test
re-asserts; the tests are the oracle, not the patch.

## Gate Criteria

- [ ] Given a fixture project with a planted 'Relative bus'-style coined concept, the method captures
  and defines it, and a regression test guards it. *(f012, AC2)*
- [ ] Given the KB produced for the fixture, the self-containment check leaves no project-specific
  term undefined (concept closure passes). *(f012, AC3, with f004)*
- [ ] Given calibration fixtures, f005's rubric flags transcription/hollowness/coverage; given
  brownfield path fixtures, f006's triage classifies correctly and each path reaches teach-back
  closure; given a greenfield-DETECTION fixture (~0-source tree), recon-classify classifies it as
  **greenfield** (classification only — no greenfield path-runs/closure, as greenfield is
  detect-and-signpost). *(f012, AC6 + AC7 brownfield + greenfield-detection)*
- [ ] The f004 denylist/salience floor (SPIKE-H2) and the f005 CAL-N severity floors (SPIKE-C1) are
  pinned by these fixtures; the suites are auto-discovered by `tests/run-all.sh` and CI-anchored. *(f012)*
- [ ] Given the act-back fixture (representative-task spec fixture + `actback-pass-kb`/`actback-fail-kb`
  pair), the **V-E** family CI-asserts the mechanical half (delivery-005's `kb-actback-task.sh` emits
  the same task byte-reproducibly; the presence check reports the operational sections present for
  `actback-pass-kb`, absent for `actback-fail-kb`); the judgment half (M6 plan success + flag
  well-foundedness) is runtime-anchored and added as a Judgment-Boundary row. *(f012 builds + exercises
  the f013 act-back fixture shape; AC16, [SPIKE-A5])*
- [ ] All section-6 quality gates pass

## Tasks

| Task | Type | Title |
|------|------|-------|
| _none yet_ | | |

## Dependencies

- **Depends on:** delivery-001, delivery-004, delivery-005
- **Blocks:** -- (none)

## Notes

**Greenfield de-scope (2026-06-23):** greenfield is now detect-and-signpost, not a generation path.
The former greenfield-path delivery (the defunct pre-act-back greenfield-path delivery that would have
carried a greenfield path-runs fixture -- NOT the current live delivery-009 Governance) is
**deleted**. feature-012 is
no longer scope-split: ALL its fixtures are owned here — the AC2/AC3/AC6 fixtures, the AC7 brownfield
path fixtures, AND a greenfield-**DETECTION** fixture (classification only; recon classifies a
~0-source tree as greenfield). There is **no greenfield path-runs / greenfield-closure fixture** —
there is no greenfield generation engine to exercise. This delivery exercises delivery-001's f004/f005
scripts and delivery-004's f006 recon over planted fixtures. The threshold SPIKEs that
delivery-001/004 deferred (f004 H2, f005 C1, f006 T1) are pinned here -- the consume-after-define
ordering holds because the owning features ship the *shape* and this delivery tunes the *floor*,
changing the default in the owning feature's file when a fixture proves it wrong.

**Act-back fixture added (2026-06-23).** feature-013 (the act-back gate) was inserted as delivery-005,
which ships `kb-actback-task.sh` + the M6 mandate + the doc-model rule and defines the act-back fixture
*shape*; this Validation delivery **builds + exercises** that fixture (the V-E family), exactly as it
builds f012's teach-back/calibration fixtures. The new task-039 adds the representative-task spec
fixture + the `actback-pass-kb`/`actback-fail-kb` pair + the V-E mechanical assertion, with the
judgment half (M6 plan success / flag well-foundedness) runtime-anchored, not CI-scored ([SPIKE-A5],
AC16). This delivery now also depends on delivery-005 (provide-before-exercise).
