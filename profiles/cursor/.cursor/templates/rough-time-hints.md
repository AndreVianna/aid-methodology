# Rough-Time-Hints Table

This table is the source of truth for what AID skills bracket with `▶/✓` lines
per FR1 AC2 (work-003-traceability). The hint expansion fires when a SKILL's body
calls `read-hint <class-name>` in a bracket-pair line. Every operation class listed
here is considered long enough to warrant a bracket pair; the threshold is
qualitative, not numeric. Sub-second tool calls are NOT in this table by design —
if an operation completes in under a second it generates more noise than signal and
should not be bracketed.

## Calibration policy

ETAs in this table SHOULD be measured, not guessed. Each row has a `Last
measured` column with the date the ETA was last refreshed from observed runtimes,
and a `Samples` column tracking how many runs informed the figure.

When a SKILL executes a bracket-pair, the `✓ done` line MUST record the actual
elapsed time. Periodically (suggested: each `/aid-discover` run or each new
`/aid-execute` delivery), refresh the ETAs in this table from those observations.
See `.cursor/templates/long-wait-protocol.md` for the orchestrator-side
check-in pattern that emits mid-wait status when ETAs exceed 5 minutes.

## ETA Table (current as of 2026-05-23)

| Operation Class | ETA Band | Last measured | Samples | Notes |
|---|---|---|---|---|
| `aid-researcher` (architecture KB scan) | 8–12 min | 2026-05-23 | 1 (9m02s observed in /aid-discover cycle-11 FIX) | Reads + synthesises repo structure for architecture KB doc |
| `aid-researcher` (code-patterns scan) | 12–18 min | 2026-05-23 | 1 (15m24s observed) | Reads code patterns, coding standards, data model, module map |
| `aid-researcher` (integration scan) | 12–16 min | 2026-05-23 | 1 (14m09s observed) | Reads integration points, API contracts, external sources |
| `aid-researcher` (quality scan) | 11–15 min | 2026-05-23 | 1 (13m14s observed) | Reads test landscape, security model, tech-debt, infrastructure |
| `aid-researcher` (pre-scan / project structure) | 9–13 min | 2026-05-23 | 1 (11m03s observed) | Initial repo scan; produces project-structure and external-sources KB docs |
| `aid-reviewer` (KB review) | 15-25 min | 2026-05-23 | 3 (16m48s + 20m16s + 23m30s observed in cycles 14 + 11 + 12; cycle 13 crashed at 9m32s before completion - not counted) | Adversarial review of all KB docs against current code; produces severity-tagged issue list + spot-checks + Review History entry. Cycle 14 was faster (~16m) because KB was already near-clean post cycle-12 cleanup - fewer findings to write up. |
| `aid-reviewer` | 5–20 min | 2026-05-23 | ~3 (5–20 min range observed across work-003 review passes; varies sharply with delivery size) | Reviews task output against acceptance criteria and grading rubric |
| `aid-developer` (IMPLEMENT) | 3–8 min | (gut estimate) | 0 | Writes code + unit tests; time scales with task complexity. **Not yet measured — calibrate after next /aid-execute run.** |
| `aid-developer` (DOCUMENT) | 1–3 min | (gut estimate) | 0 | Writes documentation artifact; shorter than code tasks. **Not yet measured.** |
| `aid-developer` (TEST) | 2–5 min | (gut estimate) | 0 | Writes and runs integration/E2E tests. **Not yet measured.** |
| `aid-architect` | 2–4 min | (gut estimate) | 0 | Designs or reviews architecture decisions. **Not yet measured.** |
| `validate-html-output.sh` | ~30 s | 2026-05-21 | 1 | Runs html-validate + link-integrity checks (H1+A1-A5+S2 structural/a11y plus L1+L2 anchor/relative-md links) on the knowledge-summary HTML output. Merged from the former validate-html.sh + validate-links.sh in 2026-05-26 script consolidation. |
| `validate-diagrams.mjs` | ~30 s | 2026-05-21 | 1 | Renders Mermaid diagrams via mmdc and checks output |
| `contrast-check.mjs` | ~30 s | 2026-05-21 | 1 | Checks WCAG contrast ratios for all colour pairs |
| `/aid-generate` (end-to-end) | ~30 s | 2026-05-23 | 4 (4 observed run_generator.py invocations during work-003) | Runs run_generator.py across all 3 profiles; includes VERIFY (deterministic) |
| `setup.sh` (smoke install) | ~10 s | 2026-05-23 | 2 | Interactive menu (`printf "1\n4\n" |`); copies one profile tree to target dir |
| `python run_generator.py` | ~25 s | 2026-05-23 | 4 | Full canonical→profile render + VERIFY (deterministic) + VERIFY (advisory) |

## Notes

- **ETAs are upper bounds**, not best-case. The 5-min threshold for L2 mid-wait
  check-ins (see `long-wait-protocol.md`) is based on the LOW end of the band:
  if the LOW end exceeds 5 min, arm the timer.
- **Multi-subagent dispatches** (e.g., 4 parallel discovery sub-agents during
  `/aid-discover` GENERATE) experience tail-latency: the user waits for the
  SLOWEST. Use the highest ETA from the parallel set as the dispatch ETA.
- **Calibration history.** Pre-2026-05-23 figures (1–5 min for everything) were
  gut estimates that under-stated actual runtimes by 3–7x. The 2026-05-23 refresh
  brought them in line with observed data from work-003 (see STATE.md cycle 11/12
  Review History entries 26 + 31 for the source observations).
- **`(gut estimate)` rows are NOT calibrated** — they remain at the pre-2026-05-23
  guess. Refresh them after each `/aid-execute` (aid-developer/aid-architect/aid-reviewer ETAs)
  or `/aid-deploy` (aid-operator ETAs) that produces ≥3 observations.
