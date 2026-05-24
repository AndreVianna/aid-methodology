# package-001: traceability (heartbeat + state-file consolidation)

## Deliveries

- delivery-001: heartbeat (FR1) + state-file consolidation (FR2) — 13 tasks

## Deployment

- **Type:** methodology + assets (no built artifact — git clone + setup.sh distribution)
- **Target:** GitHub merge — [`AndreVianna/aid-methodology#9`](https://github.com/AndreVianna/aid-methodology/pull/9) (`work-003 → master`)
- **Version:** (none — no VERSION file in repo; deferred per user choice + tech-debt H2)
- **Tag:** (none — no release tag, per user choice)
- **PR title:** `Release: work-003 — heartbeat (FR1) + state-file consolidation (FR2)`
- **PR body:** structured per aid-deploy/SKILL.md Step 4 template + AID-methodology context (deliveries, features, retired filenames, verification, review history, change stats, scope, known issues)
- **Account flow:** edit attempted under `AndreVianna-Ross` → 403 (expected; repo `AndreVianna/aid-methodology` needs `AndreVianna`); switched account, edited successfully, switched back. Per `[[repo-push-access]]` memory.

## Environment

- **Runtime:** Bash (or git-bash on Windows); PowerShell 5.1+ for setup.ps1; Node 18+ optional; Python 3 for generator
- **Config:** profiles/{claude-code,codex,cursor}.toml — per-tool render config
- **Secrets:** none (this repo has no runtime secrets — distribution is source-only)
- **Dependencies:** Host AI tool of user's choice (Claude Code / Codex CLI / Cursor)

## Verification

- **Build:** ✅ `python run_generator.py` → VERIFY-4a PASS (byte-identical re-render across 3 profiles + file-presence audit + frontmatter parse; 311 files emitted, 0 deleted). VERIFY-4b: 8/8 web sources skipped (advisory layer, intentionally stubbed).
- **Tests (smoke install):** ✅ `setup.sh /c/tmp/aid-deploy-verify --force` (claude-code profile, end-to-end). Post-install spot-check: `.claude/skills/aid-deploy/SKILL.md` has 6 `[State:` heartbeat markers; `writeback-state.sh` installed (FR2-correct name).
- **Lint:** N/A — no linter configured for this repo (tech-debt H3).
- **Side-discovery:** `writeback-state.sh` silently accepts `--help` as the GRADE argument and writes a junk entry. Will route as Q&A in KB updates step.

## Release Notes

### What's New

**FR1 — You-Are-Here Heartbeat (feature-001)**
Every AID skill now prints structured "where am I in the state machine" markers so users and AI assistants always know which state/sub-step is running. Four acceptance criteria:
- **AC1 state-entry print** — every state prints `[State: <NAME>] — <one-liner>` on entry.
- **AC2 bracket-pair floor** — long operations are wrapped in `▶ <op> starting (~<time band>)` … `✓ <op> done` (with `✗` failure branch). Rough time bands sourced from new `canonical/templates/rough-time-hints.md`.
- **AC3 ASCII state-map** — every skill renders a `▸ you are here` map showing all states and current position (e.g., `[✓ IDLE] → [● SELECTING] → [ VERIFYING ] → [ PACKAGING ] → [ DONE ]`).
- **AC4 sub-unit drill-down** — for long-running iterative states (`aid-execute EXECUTE-WAVE`, `aid-discover GENERATE`), heartbeat drills down to per-task/per-agent granularity with serial-fallback semantics.

Pure skill-body text — no hooks, no event streams, no schemas. Works on every host AI tool (Claude Code, Codex, Cursor).

**FR2 — One STATE.md per Area (feature-002)**
AID has three "areas": **Discovery** (persistent KB), **Work** (per-work dev lifecycle), **Monitor** (per-work post-conclusion, deferred). Each area now has exactly one `STATE.md` instead of N per-skill/per-artifact state files. Seven acceptance criteria, all satisfied:

| Pre-FR2 (retired) | Post-FR2 (consolidated into) |
|---|---|
| `.aid/knowledge/DISCOVERY-STATE.md` + `SUMMARY-STATE.md` | `.aid/knowledge/STATE.md` |
| `.aid/{work}/INTERVIEW-STATE.md` + per-feature `STATE.md` × N + per-task `task-NNN-STATE.md` × N + (future) `DEPLOYMENT-STATE.md` | `.aid/{work}/STATE.md` |
| (Monitor) | per-work `STATE.md` (deferred until Monitor area matures) |

Artifact change logs (`REQUIREMENTS.md`, `SPEC.md`, `PLAN.md`, task-NNN.md, KB docs) are unchanged — that's *content history* (distinct from *process state*).

### Technical Changes

- **All 10 `aid-*` skills** updated with heartbeat (FR1) + state-file refs migrated to consolidated STATE.md (FR2).
- **13 canonical agent files** (`canonical/agents/{architect,discovery-*,interviewer,orchestrator,researcher,reviewer}/`) updated to route Q&A into the right consolidated STATE.md sections.
- **4 `knowledge-summary` scripts** (`check-preflight.sh`, `stale-check.sh`, `grade.sh`, `writeback-state.sh` [renamed from `writeback-discovery-state.sh`]) read/write `STATE.md` instead of retired filenames. `aid-summarize` is now end-to-end runnable.
- **2 new canonical templates:** `work-state-template.md` + `discovery-state-template.md` (area-STATE shape). Retired: `interview-state.md`, `feature-state.md`, `implementation-state.md`, `deployment-state.md`, old `discovery-state.md`, `reports/discovery-state-template.md`.
- **KB documentation:** `coding-standards.md §8.5` codifies state-file naming rule; `data-model.md §1A` codifies area-STATE rule + §2.7 flags `task-NNN-STATE.md` as LEGACY.
- **All 3 install profiles** (`profiles/{claude-code,codex,cursor}/`) re-rendered; generator round-trip byte-identical.
- **`canonical/rules/aid-methodology.mdc`** workspace structure block rewritten to show FR2 area-STATE layout.
- **3 dogfood works** (work-001, work-002, work-003) already migrated to area-STATE shape.

### Known Issues

None unresolved. 1 MINOR cosmetic deviation acknowledged in pass-3 review: `aid-discover` and `aid-summarize` SKILL.md have asymmetric column-0 `^▶ ` vs `^✓ ` counts — semantically balanced (extras are STATE.md write-receipts and indented per-agent done lines, not unmatched operation closures), within A-grade rubric tolerance.

### Side-discoveries (route to KB via Q&A in Step 6)

- `canonical/templates/package.md` is missing from the canonical tree (lives only in install trees `.claude/`, `profiles/*/.{claude,agents,cursor}/templates/`). Generator drift bug — would be caught by `aid-generate`'s VERIFY-4a if the file existed in canonical. Q&A entry to route.
- `writeback-state.sh` silently accepts `--help` as the GRADE argument and writes a junk entry. Defensive arg-handling gap. Q&A entry to route.
- Slash-command `/aid-deploy` body shown to the model when invoked is the OLD pre-FR2 cached version (with `DEPLOYMENT-STATE.md` / `DISCOVERY-STATE.md` / `task-NNN-STATE.md`), even though the on-disk file is the new FR2-correct version. Harness loads SKILL.md text at session start, not at invocation. Q&A entry to route (this may already be a known platform-level concern, not an AID bug).

## KB Updates Routed

4 Q&A entries routed to `.aid/knowledge/STATE.md ## Q&A (Pending)` for next `/aid-discover` run to process:

- **Q190 [Medium]** Generator / Canonical Drift — `canonical/templates/package.md` missing (only in install trees); audit for similar orphans
- **Q191 [Low]** Tooling — `writeback-state.sh` accepts `--help` as GRADE arg silently; add defensive arg-handling
- **Q192 [Low]** Host Platform — slash-command body in this session was pre-FR2 cached version; document harness skill-load behavior
- **Q193 [High]** Features — add feature-001 + feature-002 to `feature-inventory.md`

⚠️ Direct KB edits NOT performed during deploy (per aid-deploy SKILL.md Step 6). All routes via Discovery.

## Status: Shipped (Date: 2026-05-23)
