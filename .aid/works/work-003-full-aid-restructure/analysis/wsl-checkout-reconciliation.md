# WSL checkout reconciliation (Q193)

Owner-authorized reconciliation only; delivery-003 stays paused, no model calls.

## Inputs

| Item | Value |
|---|---|
| WSL checkout | `/home/andre/projects/aid`, branch `work-003`, HEAD `86b797a1e5118d753cb7c8d04267596266806f92` (H); left untouched, never fetched |
| Pushed tip | `origin/work-003` = `8a9695090200f91c7803cd2912e5841df6ad11ad` (O), 18 commits ahead of H; H is its ancestor |
| WSL changes | 83 modified tracked (0 staged, 0 mode changes, 0 symlinks), 2 untracked, stash empty |
| Private backup | `.aid/.temp/wsl-reconciliation-20261025T012453Z/` (ignored; see its `analysis/VERIFY.txt`) |

## Method

For each path: H blob, W blob (WSL working bytes, raw and clean-filtered) and O blob.
W == O is integrated. Otherwise `git merge-file` with base H, ours W, theirs O: a clean
result equal to O means every WSL hunk is already pushed. Each remaining conflict was read
line by line. Generated site pages were checked by running `site/scripts/gen-skills.mjs` on
the pushed source: zero drift, so the pushed generated tree is current for its source.

## Result

| Class | Count |
|---|---|
| Integrated (identical, or every hunk already in pushed) | 65 |
| Superseded source (pushed holds a later revision) | 6 |
| Superseded generated (derived; pushed regenerates with zero drift) | 12 |
| Untracked, identical to a pushed file | 1 |
| Untracked test artifact, not carried | 1 |
| Unique useful work missing from pushed | 0 |
| Line-ending or mode only | 0 |

No source change was carried forward. `.aid/STATE.yml` in the WSL checkout holds one
Pending question with context `mode check`: a writer test that ran against the live checkout
(2026-10-24 12:40 -0400). It stays in place and in the backup.

## Per-path accounting

| Path | Class | Evidence |
|---|---|---|
| `.aid/knowledge/test-landscape.md` | superseded | pushed group list adds RAW; WSL list is the earlier one; conflict(2) |
| `canonical/aid/rules.md` | integrated | W blob == O blob, mode 100644 |
| `canonical/aid/templates/question-protocol.md` | integrated | 3-way merge(H,W,O) == O: every WSL hunk already in pushed |
| `canonical/aid/templates/skill-steps.md` | integrated | W blob == O blob, mode 100644 |
| `canonical/aid/templates/work-initiation-gate.md` | integrated | W blob == O blob, mode 100644 |
| `canonical/aid/templates/worktree-lifecycle.md` | integrated | W blob == O blob, mode 100644 |
| `canonical/skills/aid-config/SKILL.md` | integrated | W blob == O blob, mode 100644 |
| `canonical/skills/aid-monitor/references/state-observe.md` | integrated | W blob == O blob, mode 100644 |
| `canonical/skills/aid-orchestrate/SKILL.md` | superseded | pushed moves the outcomes-before-symptoms rule into the reading check; WSL has it in the older place; conflict(1) |
| `canonical/skills/aid-orchestrate/references/check-intent.md` | integrated | W blob == O blob, mode 100644 |
| `canonical/skills/aid-orchestrate/references/size-and-route.md` | integrated | W blob == O blob, mode 100644 |
| `canonical/skills/aid-report/SKILL.md` | integrated | W blob == O blob, mode 100644 |
| `canonical/skills/aid-research/SKILL.md` | superseded | pushed says explicitly that the choice is the user's (stronger than WSL wording); conflict(1) |
| `canonical/skills/aid-review/SKILL.md` | integrated | W blob == O blob, mode 100644 |
| `canonical/skills/aid-set-connector/SKILL.md` | integrated | W blob == O blob, mode 100644 |
| `site/scripts/__tests__/flow-advance.test.mjs` | integrated | W blob == O blob, mode 100644 |
| `site/scripts/__tests__/flow-extract-inline.test.mjs` | integrated | W blob == O blob, mode 100644 |
| `site/scripts/__tests__/flow-graph.test.mjs` | integrated | W blob == O blob, mode 100644 |
| `site/src/content/docs/concepts/methodology.md` | integrated | W blob == O blob, mode 100644 |
| `site/src/content/docs/skills/aid-config.md` | superseded-generated | generated; gen-skills on pushed source = zero drift; WSL copy older output; conflict(1) |
| `site/src/content/docs/skills/aid-monitor.md` | integrated | W blob == O blob, mode 100644 |
| `site/src/content/docs/skills/aid-orchestrate.md` | superseded-generated | generated; gen-skills on pushed source = zero drift; WSL copy older output; conflict(1) |
| `site/src/content/docs/skills/aid-report.md` | superseded-generated | generated; gen-skills on pushed source = zero drift; WSL copy older output; conflict(7) |
| `site/src/content/docs/skills/aid-research.md` | superseded-generated | generated; gen-skills on pushed source = zero drift; WSL copy older output; conflict(12) |
| `site/src/content/docs/skills/aid-review.md` | superseded-generated | generated; gen-skills on pushed source = zero drift; WSL copy older output; conflict(3) |
| `site/src/content/docs/skills/aid-set-connector.md` | superseded-generated | generated; gen-skills on pushed source = zero drift; WSL copy older output; conflict(1) |
| `site/src/data/skill-flows/aid-config.flow.json` | superseded-generated | generated; gen-skills on pushed source = zero drift; WSL copy older output; conflict(15) |
| `site/src/data/skill-flows/aid-create-api.flow.json` | integrated | 3-way merge(H,W,O) == O: every WSL hunk already in pushed |
| `site/src/data/skill-flows/aid-create-cli.flow.json` | integrated | 3-way merge(H,W,O) == O: every WSL hunk already in pushed |
| `site/src/data/skill-flows/aid-create-config.flow.json` | integrated | 3-way merge(H,W,O) == O: every WSL hunk already in pushed |
| `site/src/data/skill-flows/aid-create-dashboard.flow.json` | integrated | 3-way merge(H,W,O) == O: every WSL hunk already in pushed |
| `site/src/data/skill-flows/aid-create-data-model.flow.json` | integrated | 3-way merge(H,W,O) == O: every WSL hunk already in pushed |
| `site/src/data/skill-flows/aid-create-data-pipeline.flow.json` | integrated | 3-way merge(H,W,O) == O: every WSL hunk already in pushed |
| `site/src/data/skill-flows/aid-create-infra.flow.json` | integrated | 3-way merge(H,W,O) == O: every WSL hunk already in pushed |
| `site/src/data/skill-flows/aid-create-integration.flow.json` | integrated | 3-way merge(H,W,O) == O: every WSL hunk already in pushed |
| `site/src/data/skill-flows/aid-create-job.flow.json` | integrated | 3-way merge(H,W,O) == O: every WSL hunk already in pushed |
| `site/src/data/skill-flows/aid-create-messaging.flow.json` | integrated | 3-way merge(H,W,O) == O: every WSL hunk already in pushed |
| `site/src/data/skill-flows/aid-create-test.flow.json` | integrated | 3-way merge(H,W,O) == O: every WSL hunk already in pushed |
| `site/src/data/skill-flows/aid-create-theme.flow.json` | integrated | 3-way merge(H,W,O) == O: every WSL hunk already in pushed |
| `site/src/data/skill-flows/aid-create-ui.flow.json` | integrated | 3-way merge(H,W,O) == O: every WSL hunk already in pushed |
| `site/src/data/skill-flows/aid-create.flow.json` | integrated | 3-way merge(H,W,O) == O: every WSL hunk already in pushed |
| `site/src/data/skill-flows/aid-deprecate.flow.json` | integrated | 3-way merge(H,W,O) == O: every WSL hunk already in pushed |
| `site/src/data/skill-flows/aid-describe.flow.json` | integrated | W blob == O blob, mode 100644 |
| `site/src/data/skill-flows/aid-detail.flow.json` | integrated | W blob == O blob, mode 100644 |
| `site/src/data/skill-flows/aid-discover.flow.json` | integrated | W blob == O blob, mode 100644 |
| `site/src/data/skill-flows/aid-experiment.flow.json` | integrated | 3-way merge(H,W,O) == O: every WSL hunk already in pushed |
| `site/src/data/skill-flows/aid-fix.flow.json` | integrated | 3-way merge(H,W,O) == O: every WSL hunk already in pushed |
| `site/src/data/skill-flows/aid-housekeep.flow.json` | integrated | W blob == O blob, mode 100644 |
| `site/src/data/skill-flows/aid-migrate.flow.json` | integrated | 3-way merge(H,W,O) == O: every WSL hunk already in pushed |
| `site/src/data/skill-flows/aid-monitor.flow.json` | integrated | W blob == O blob, mode 100644 |
| `site/src/data/skill-flows/aid-orchestrate.flow.json` | superseded-generated | generated; gen-skills on pushed source = zero drift; WSL copy older output; conflict(24) |
| `site/src/data/skill-flows/aid-refactor.flow.json` | integrated | 3-way merge(H,W,O) == O: every WSL hunk already in pushed |
| `site/src/data/skill-flows/aid-remove.flow.json` | integrated | 3-way merge(H,W,O) == O: every WSL hunk already in pushed |
| `site/src/data/skill-flows/aid-report.flow.json` | superseded-generated | generated; gen-skills on pushed source = zero drift; WSL copy older output; conflict(21) |
| `site/src/data/skill-flows/aid-research.flow.json` | superseded-generated | generated; gen-skills on pushed source = zero drift; WSL copy older output; conflict(22) |
| `site/src/data/skill-flows/aid-review.flow.json` | superseded-generated | generated; gen-skills on pushed source = zero drift; WSL copy older output; conflict(6) |
| `site/src/data/skill-flows/aid-set-connector.flow.json` | superseded-generated | generated; gen-skills on pushed source = zero drift; WSL copy older output; conflict(8) |
| `site/src/data/skill-flows/aid-update-api.flow.json` | integrated | 3-way merge(H,W,O) == O: every WSL hunk already in pushed |
| `site/src/data/skill-flows/aid-update-cli.flow.json` | integrated | 3-way merge(H,W,O) == O: every WSL hunk already in pushed |
| `site/src/data/skill-flows/aid-update-config.flow.json` | integrated | 3-way merge(H,W,O) == O: every WSL hunk already in pushed |
| `site/src/data/skill-flows/aid-update-dashboard.flow.json` | integrated | 3-way merge(H,W,O) == O: every WSL hunk already in pushed |
| `site/src/data/skill-flows/aid-update-data-model.flow.json` | integrated | 3-way merge(H,W,O) == O: every WSL hunk already in pushed |
| `site/src/data/skill-flows/aid-update-data-pipeline.flow.json` | integrated | 3-way merge(H,W,O) == O: every WSL hunk already in pushed |
| `site/src/data/skill-flows/aid-update-infra.flow.json` | integrated | 3-way merge(H,W,O) == O: every WSL hunk already in pushed |
| `site/src/data/skill-flows/aid-update-integration.flow.json` | integrated | 3-way merge(H,W,O) == O: every WSL hunk already in pushed |
| `site/src/data/skill-flows/aid-update-job.flow.json` | integrated | 3-way merge(H,W,O) == O: every WSL hunk already in pushed |
| `site/src/data/skill-flows/aid-update-kb.flow.json` | integrated | W blob == O blob, mode 100644 |
| `site/src/data/skill-flows/aid-update-messaging.flow.json` | integrated | 3-way merge(H,W,O) == O: every WSL hunk already in pushed |
| `site/src/data/skill-flows/aid-update-test.flow.json` | integrated | 3-way merge(H,W,O) == O: every WSL hunk already in pushed |
| `site/src/data/skill-flows/aid-update-theme.flow.json` | integrated | 3-way merge(H,W,O) == O: every WSL hunk already in pushed |
| `site/src/data/skill-flows/aid-update-ui.flow.json` | integrated | 3-way merge(H,W,O) == O: every WSL hunk already in pushed |
| `site/src/data/skill-flows/aid-update.flow.json` | integrated | 3-way merge(H,W,O) == O: every WSL hunk already in pushed |
| `tests/canonical/test-aid-cli-ps1.sh` | integrated | W blob == O blob, mode 100755 |
| `tests/canonical/test-conversation-runner.sh` | superseded | pushed group list adds RAW; WSL lacks it; conflict(4) |
| `tests/canonical/test-host-hooks.sh` | integrated | W blob == O blob, mode 100755 |
| `tests/canonical/test-kb-export-pw.mjs` | integrated | W blob == O blob, mode 100644 |
| `tests/canonical/test-release-migrate-smoke.sh` | integrated | W blob == O blob, mode 100755 |
| `tests/conversation/judge.md` | integrated | W blob == O blob, mode 100644 |
| `tests/conversation/protocol-checks.md` | integrated | W blob == O blob, mode 100644 |
| `tests/conversation/run.py` | superseded | pushed CodexAgent adds raw_dir (passive raw capture); WSL is the earlier signature; conflict(4) |
| `tests/conversation/samples/feature-002/002-14-orchestrate-unsure-reading.md` | integrated | W blob == O blob, mode 100644 |
| `tests/conversation/samples/feature-002/002-17-review-publish-approval.md` | integrated | W blob == O blob, mode 100644 |
| `tests/coverage-rehome-allowlist.tsv` | superseded | WSL-added row present once in pushed file; position-only conflict; conflict(1) |
| `tests/conversation/support/tracker_mcp.py` | untracked-integrated | untracked in WSL; W blob == O blob (tracked in pushed) |
| `.aid/STATE.yml` | untracked-test-artifact | untracked; one Pending question "mode check" (a writer test leak, 2026-10-24 12:40 -0400); not in pushed; kept in backup and in place, not carried |
