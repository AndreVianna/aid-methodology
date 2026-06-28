# task-040: Split verification -- DBI, orphan-prune, count +1, substring guard, CI green

**Type:** TEST

**Source:** work-001-aid-interview-improvements -> delivery-006

**Depends on:** task-039

**Scope:**
- Verify delivery-006 against its gate criteria and the feature-006 DoD 1-8 (AC-8). Skills are
  prose-executed and not unit-tested by design, so this task runs the structural/byte-identity checks,
  the scoped sweep, the substring-guard delta, the inter-skill-seam walkthrough, and the §6 heavy
  gates; it authors no skill content and fixes nothing (defects loop back to the owning task 037/038/039).
- **(A) Inter-skill seam works (DoD 2 / AC-1).** Walk through the hand-off: aid-describe COMPLETION
  PAUSEs at approved REQUIREMENTS with the `/aid-define` signpost (not a chain); aid-define's State
  Detection requires `Interview State: Approved` and detects FEATURE-DECOMPOSITION -> CROSS-REFERENCE
  -> DONE; invoked before approval aid-define HALTs with the `/aid-describe` pointer; each skill prints
  a hand-off pointer on a sibling-owned state; the lite path completes wholly in aid-describe
  (LITE-DONE -> /aid-execute).
- **(B) Scoped zero-stale sweep (DoD 1,3 / AC-1,AC-3).** A boundary-aware `grep -rn "aid-interview"`
  over the shipped/canonical surface set (`canonical/`, the 5 `profiles/` trees, the `.claude/` mirror,
  the install manifests = 5 `emission-manifest.jsonl` + `.aid/.aid-manifest.json`, `site/`, `docs/`,
  `tests/`, root `README.md`, `examples/`, `dashboard/home.html` + `.aid/dashboard/home.html`) returns
  ZERO live `/aid-interview` command tokens and `skills/aid-interview/` path tokens; the only permitted
  `aid-interview`-prefixed matches are the protected `aid-interviewer` agent and the deliberately-kept
  ref filenames (`interview-loop.md` / `interview-strategies.md`). The out-of-scope surfaces
  (`.aid/knowledge/`, `.aid/work-*/`, `.aid/design/`, frozen dashboard fixtures + `test_feature009.py`)
  are confirmed excluded, not failures.
- **(C) Trees rendered + old dir pruned (DoD 4 / AC-2).** Each `profiles/*/skills/aid-describe/` +
  `aid-define/` exists, each `profiles/*/skills/aid-interview/` is gone, and each
  `emission-manifest.jsonl` reflects the swap; the `.claude/` mirror matches.
- **(D) DBI byte-identity, both skills (DoD 5 / AC-2 / NFR-6).** The DBI test passes -- `aid-describe/`
  is byte-identical across the 5 host trees + the dogfood mirror, and `aid-define/` likewise.
- **(E) Count +1 + manifests + docs current (DoD 6 / AC-3).** `.aid/.aid-manifest.json` paths updated
  for both dirs (old removed); `gen-reference.mjs` has two Define-group entries and the skills-drift
  guard passes against disk; the intro count is `14` and `skills.md` is regenerated to `14`; the
  in-scope hand-authored count surfaces (methodology numeric AND spelled-out Fourteen / glossary /
  maintainer / index) are incremented; `grep aid-interview site/` returns zero live refs; the
  `.aid/knowledge` + `summary-src` count surfaces are documented as left for /aid-housekeep (not a gate
  failure).
- **(F) Substring guard intact (DoD 7 / AC-4).** `grep -rn "aid-interviewer"` count over the
  shipped/canonical surface set equals the task-036 baseline (unchanged before/after); the
  `aid-interviewer` agent dir is untouched and is still aid-describe's dispatch agent.
- **(G) CI green incl. master-only heavy gates (DoD 8 / AC-5).** render-drift, DBI, the
  `gen-reference.mjs` skills-drift guard, ASCII-only, installer (incl. the Windows lane), and the
  docs/Astro build all pass; run `tests/run-all.sh` (HOME-pinned) + the `site` Astro build locally
  before claiming green (master-CI-only-on-master constraint).
- Record results to this task's STATE.md / the delivery gate; file any [HIGH]/[CRITICAL] findings per
  the ledger schema. Out of scope: fixing any defect found (loop back to task-037/038/039 + re-render).

**Acceptance Criteria:**
- [ ] Inter-skill seam verified: aid-describe COMPLETION PAUSEs to `/aid-define`; aid-define requires
  `Interview State: Approved` and walks FEATURE-DECOMPOSITION->CROSS-REFERENCE->DONE; before-approval
  HALT + sibling hand-off pointers print; lite path completes in aid-describe. *(gate criterion 1, DoD 2)*
- [ ] Scoped boundary-aware `grep` returns ZERO live `/aid-interview` + `skills/aid-interview/` tokens
  over the shipped/canonical surface set; only `aid-interviewer` + the kept ref filenames remain; the
  out-of-scope surfaces are confirmed excluded. *(gate criterion 1, DoD 1,3)*
- [ ] Both new dirs render byte-identically (DBI passes) across the 5 host trees + the dogfood mirror;
  each `profiles/*/skills/aid-interview/` is orphan-pruned and the emission manifests reflect the swap.
  *(gate criterion 2, DoD 4,5)*
- [ ] Count surfaces are +1 and consistent: numeric `14` AND spelled-out `Fourteen` (no contradiction);
  two manifest entries + two docs-site entries; skills-drift guard passes; `.aid/.aid-manifest.json`
  paths updated. *(gate criterion 3, DoD 6)*
- [ ] `grep -rn "aid-interviewer"` count equals the task-036 baseline (unchanged); the agent dir is
  untouched. *(gate criterion 4, DoD 7)*
- [ ] CI green: render-drift, DBI, skills-drift guard, ASCII-only, installer incl. Windows lane, and
  docs/Astro build -- `tests/run-all.sh` (HOME-pinned) + the `site` Astro build run locally and pass.
  *(gate criterion 5, DoD 8)*
- [ ] Tests are deterministic with clean setup/teardown; all delivery-006 gate criteria and feature-006
  AC-8 + DoD 1-8 are covered. *(TEST defaults)*
