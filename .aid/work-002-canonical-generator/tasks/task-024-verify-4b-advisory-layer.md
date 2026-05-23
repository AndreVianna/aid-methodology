# task-024: Write VERIFY-4b — the advisory conformance layer (graceful-degraded form)

**Type:** TEST

**Source:** work-002-canonical-generator → delivery-001

**Depends on:** task-019, task-020, task-021

**Scope:**
- Author `.claude/skills/aid-generate/scripts/verify_advisory.py`.
- For each vendor URL in `.aid/knowledge/external-sources.md` (8 URLs at time of writing — all marked `⚠️ Pending fetch`):
  - If the URL is `⚠️ Pending fetch` or unreachable (network error / non-200 status): **skip with a warning**. Increment a counter `skipped_count`. Continue.
  - If the URL is reachable AND has been previously fetched into the KB (parse `external-sources.md` to learn the fetch-state): perform the conformance check — compare a sample of generated files (per host tool) against the doc's stated conventions for frontmatter fields, file structure, naming, deprecations. Any discrepancy is a **warning**, not a failure.
- Output: a structured JSON summary at `.aid/work-002-canonical-generator/verify-4b-report.json` listing per-URL `{url, status: "skipped" | "checked", warnings: [...]}`. The orchestrator's REPORT step (task-025) reads this and surfaces:
  - The **`skipped_count`** prominently — per PLAN Risks §3, "VERIFY-4b graceful-degraded form must explicitly emit a warning count in the REPORT step so the maintainer knows how many vendor doc URLs were skipped."
  - The total **warning count** across all checked URLs.
- The verifier is **non-deterministic** (uses network, optionally dispatches a conformance-review agent) — so it is **excluded** from the AC2 byte-identical re-run guarantee (SPEC §211 explicitly carves this out). The skill's orchestration runs 4b after 4a; the run reports both but 4a alone gates pass/fail.
- This task ships the **graceful-degraded form**. The full conformance review (agent dispatch + URL fetch) activates automatically once the URLs in `external-sources.md` move from `⚠️ Pending fetch` to fetched — no separate delivery needed. Implement the dispatch hook now but leave the conformance-review agent as a stub that just emits a warning if invoked (the maintainer adds the prompt body later, scope of a different work item).

**Acceptance Criteria:**
- [ ] `.claude/skills/aid-generate/scripts/verify_advisory.py` exists; compiles; runs end-to-end.
- [ ] With all 8 URLs in `⚠️ Pending fetch` state (current state), the script completes successfully and emits `verify-4b-report.json` with `skipped_count = 8` and `checked_count = 0`.
- [ ] Exit code is always 0 (advisory layer, never blocks the run — per SPEC §200).
- [ ] The orchestrator's REPORT step (task-025) reads the report and surfaces `skipped_count` in its output.
- [ ] Forced reachability test: replace one URL with a known-reachable URL (e.g. a `file://` URL pointing to a fixture) and confirm the script runs the conformance-check path; the stub agent emits a warning that is captured in the report.
