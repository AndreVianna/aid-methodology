# task-002: Ownership-consistency guard suite

**Type:** TEST

**Source:** feature-001-scout-ownership-reconcile → delivery-001

**Depends on:** task-001

**Scope:**
- Add `tests/canonical/test-discovery-doc-ownership.sh` (auto-discovered by `run-all.sh` glob; no harness edit). Follow the existing suite shape (`source ../lib/assert.sh`, `set -u`, `--verbose`, exit 0/1) — mirror `test-read-setting.sh`.
- Parse the `state-generate.md` dispatch table (Step 1 scout block + the `[2/5]`–`[5/5]` rows) into a `doc→owner` map; extract each `canonical/agents/discovery-*/AGENT.md` `Produce .aid/knowledge/<doc>.md` claim (frontmatter description + `## What You Do`) and scan `## What You Don't Do` for contradicting `Map <doc>` disclaimers.
- Assert: (a) the union of Produce claims equals the dispatch map exactly; (b) no doc is claimed by two agents; (c) no agent disclaims a doc the table assigns to it.
- Ownership-only — no doc-count / "14" / "16" assertion (must not collide with task-008 / FR-P0-4).

**Acceptance Criteria:**
- [ ] Suite passes on the reconciled tree and would fail on the pre-task-001 tree for both scout and quality (reason about this; do not revert to prove it).
- [ ] Suite contains no doc-count/"14"/"16" assertion.
- [ ] `bash tests/run-all.sh` reports all suites pass (13 existing + this one).
- [ ] All §6 quality gates pass (deterministic test, clean setup/teardown, render-drift clean).
