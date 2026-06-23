# Delivery SPEC -- delivery-005: Validation Fixture

[!NOTE]
This is the DELIVERY-LEVEL SPEC.md. It is the IMMUTABLE DEFINITION for this delivery.
Written by aid-plan; not a state file. State lives in delivery-005/STATE.md.

> **Delivery:** delivery-005
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
prove correct triage classification and teach-back closure. This is the CI-anchored regression proof
that the essence engine works and stays working. This delivery is the **engine + brownfield** scope;
the greenfield path fixture is carved to delivery-009.

## Scope

In scope -- **feature-012, ENGINE + BROWNFIELD scope only**:

- **AC2 -- 'Relative bus' regression.** A fixture with a planted coined concept + a regression test
  asserting capture-and-define (end-to-end, over delivery-001's harvest/spine/closure engine).
- **AC3 -- closure self-containment.** A proof that the KB produced for the fixture leaves no
  project-specific term undefined (concept closure passes), jointly with f004's `closure-check.sh`.
- **AC6 -- calibration tuning.** Planted transcription / hollowness / coverage-vs-source fixtures
  that f005's rubric must flag; this delivery is the executable oracle that pins f004's
  `[SPIKE-H2]` denylist/salience floor and f005's `[SPIKE-C1]` CAL-N severity floors.
- **AC7 -- brownfield path fixtures.** brownfield-small + brownfield-large fixtures that f006's
  triage must classify correctly and run to teach-back closure.

**Out of scope (carved to delivery-009):** the **greenfield** path fixture (AC7 greenfield).
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
  closure. *(f012, AC6 + AC7 brownfield)*
- [ ] The f004 denylist/salience floor (SPIKE-H2) and the f005 CAL-N severity floors (SPIKE-C1) are
  pinned by these fixtures; the suites are auto-discovered by `tests/run-all.sh` and CI-anchored. *(f012)*
- [ ] All section-6 quality gates pass

## Tasks

| Task | Type | Title |
|------|------|-------|
| _none yet_ | | |

## Dependencies

- **Depends on:** delivery-001, delivery-004
- **Blocks:** delivery-009

## Notes

**Scope-split (Cross-Cutting Risk R1):** feature-012 is split engine+brownfield-here /
greenfield-in-delivery-009. The AC2/AC3/AC6/AC7-brownfield fixtures are owned here; the AC7-greenfield
path fixture is explicitly out-of-scope and owned by delivery-009. This delivery exercises
delivery-001's f004/f005 scripts and delivery-004's f006 recon over planted fixtures. The threshold
SPIKEs that delivery-001/004 deferred (f004 H2, f005 C1, f006 T1) are pinned here -- the
consume-after-define ordering holds because the owning features ship the *shape* and this delivery
tunes the *floor*, changing the default in the owning feature's file when a fixture proves it wrong.
