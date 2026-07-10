# task-007: Validate + remediate KB concept-closure hygiene

**Type:** REFACTOR

**Source:** work-003-state-schema -> delivery-001

**Depends on:** -- (none)

**Scope:**
- **Validate the premise first (no security theater).** Run `.claude/aid/scripts/kb/closure-check.sh`
  against the current KB and determine whether it still reports a large ungrounded-term set, and
  WHY. Classify the reported terms: are they genuinely undefined KB concepts (a real gap), or
  generic non-concept token-junk (bash, registry, code tokens, stop-words) that the harvester
  should never have emitted?
- **Fix at the root, not the symptom.** If the reports are token-junk, improve the harvester /
  closure filter so it stops emitting non-concept tokens — do NOT simply pad
  `discovery.term_exclusions` in `.aid/settings.yml` (that is whack-a-mole; the exclusions list
  trails the harvest by design). If a bounded, legitimately-static exclusion set is the right
  tool for a residual, add it with justification.
- **Edit the canonical sources, not the mirror.** Both scripts have canonical origins —
  `canonical/aid/scripts/kb/closure-check.sh` and `canonical/aid/scripts/kb/harvest-coined-terms.sh`;
  edit those (NOT the generated `.claude/aid/...` copies), then run
  `python .claude/skills/generate-profile/scripts/run_generator.py`, resync the dogfood `.claude/`,
  and confirm `tests/canonical/test-dogfood-byte-identity.sh` passes. (A `.aid/settings.yml` change,
  if any, is repo-local and not rendered.)
- **If the premise is false** (closure-check is clean at HEAD, or the residual is immaterial),
  close this task as **Not Applicable** with the evidence, rather than inventing a fix.
- Surface (don't bury) any genuinely-undefined KB concept the validation turns up — that routes
  to a targeted `/aid-discover` closure-loop, not to this task.

**Acceptance Criteria:**
- [ ] `closure-check.sh` output at HEAD is captured and its terms classified (real-concept vs token-junk) with evidence (traces to BLUEPRINT gate criteria #11).
- [ ] Either: the harvester/filter root cause is fixed (in `canonical/`, re-rendered, byte-identity green) so closure-check no longer reports token-junk (before/after count) — OR: the premise is documented false and the task is closed Not Applicable with evidence (traces to BLUEPRINT gate criteria #11).
- [ ] No blind padding of `discovery.term_exclusions` used as a substitute for a root-cause fix; any exclusion added is individually justified (traces to BLUEPRINT gate criteria #11).
- [ ] All applicable quality gates pass (per `.aid/settings.yml`).
