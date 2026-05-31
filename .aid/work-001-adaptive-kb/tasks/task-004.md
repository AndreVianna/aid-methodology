# task-004: Expectations single-source guard suite

**Type:** TEST

**Source:** feature-002-expectations-consolidation → delivery-001

**Depends on:** task-003

**Scope:**
- Add `tests/canonical/test-expectations-single-source.sh` (auto-discovered). Follow existing suite shape.
- Assert: (1) **single-source invariant** — a canary block (`### architecture.md`) resolves only to `canonical/skills/aid-discover/references/document-expectations.md`, and `discovery-reviewer/AGENT.md` has 0 per-doc `### *.md` blocks; (2) **reviewer-has-access invariant** — `{{DOCUMENT_EXPECTATIONS}}` is present in `reviewer-prompt.md` AND `document-expectations.md` is named in BOTH `state-review.md` and `state-fix.md` (so a missing FIX-mode wiring fails the suite).
- Keep to grep invariants (guard-rail, not behavior).

**Acceptance Criteria:**
- [ ] Suite passes on the post-task-003 tree; the two-dispatch-site (REVIEW + FIX) check is present.
- [ ] `bash tests/run-all.sh` all green (now +2 suites from delivery-001).
- [ ] All §6 quality gates pass (deterministic, clean setup/teardown, render-drift clean).
