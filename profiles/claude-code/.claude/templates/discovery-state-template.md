# Discovery State

> **Source:** aid-config (creates) · aid-discover + aid-summarize (update)
> **Status:** Initial | In Progress | Approved
> **Current Grade:** {grade or Pending}
> **User Approved:** yes | no
> **Last KB Review:** {YYYY-MM-DD or —}
> **Last Summary:** {YYYY-MM-DD or —}

This is the single state file for the **Discovery area** — persistent project knowledge: the Knowledge Base + the visual summary. One STATE.md per project's `.aid/knowledge/` directory. Absorbs what used to be `DISCOVERY-STATE.md` + `SUMMARY-STATE.md`.

> **Project-level settings** (minimum grade, heartbeat interval, max parallel tasks,
> etc.) live in `.aid/settings.yml`, not here. STATE.md is for run-state only —
> per-area review history, Q&A, current-cycle grade snapshots. Resolve any
> configured value via:
> `bash .claude/scripts/config/read-setting.sh --skill <name> --key <key> --default <fallback>`

## External Documentation

| Path | Type | Accessible | Notes |
|------|------|------------|-------|
| {/path/to/docs or "None provided"} | {file/directory} | {✅/❌} | {brief note} |

## KB Documents Status

| # | Document | Status | Grade | Last Reviewed | Notes |
|---|----------|--------|-------|---------------|-------|
| 1 | project-structure.md | Pending | — | — | |
| 2 | external-sources.md | Pending | — | — | |
| 3 | architecture.md | Pending | — | — | |
| 4 | technology-stack.md | Pending | — | — | |
| 5 | module-map.md | Pending | — | — | |
| 6 | coding-standards.md | Pending | — | — | |
| 7 | schemas.md | Pending | — | — | |
| 8 | pipeline-contracts.md | Pending | — | — | |
| 9 | integration-map.md | Pending | — | — | |
| 10 | domain-glossary.md | Pending | — | — | |
| 11 | test-landscape.md | Pending | — | — | |
| 12 | tech-debt.md | Pending | — | — | |
| 13 | infrastructure.md | Pending | — | — | |
| 14 | feature-inventory.md | Pending | — | — | |

## Knowledge Summary Status

| Field | Value |
|-------|-------|
| Profile | {auto-detected: web-app/library/cli/microservices/data-pipeline OR user-specified} |
| Profile Source | {auto-detected | user-specified} |
| Profile Confidence | {high | medium | low | n/a} |
| Theme | default | brand-{name} |
| Machine Grade | {grade or Pending} |
| Human Grade | {grade or Pending} |
| User Approved | yes | no |
| Last Run | {YYYY-MM-DD or —} |
| Output | {knowledge-summary.html (size) or —} |
| Mermaid Version | {pinned version or —} |
| Mermaid Cached | {.aid/knowledge/.cache/mermaid.min.js (sha256) or —} |

## Q&A (Pending)

> Open questions about KB facts, raised by any skill, awaiting human input or downstream resolution. Each entry: ID, category, impact, suggested answer (if inferrable), status.

### Q{N}

- **Category:** {category, e.g., Architecture, Security, UX}
- **Impact:** {High|Medium|Low|Required}
- **Status:** Pending | Answered | Skipped
- **Context:** {why this matters; what the downstream phase observed; cite relevant file:line if applicable}
- **Suggested:** {answer if inferrable, or —}
- **Answer:** {filled when status is Answered}
- **Applied to:** {KB doc(s) the answer was applied to}

## Review History

> One row per /aid-discover review cycle. Append-only.

| # | Date | Grade | Source | Notes |
|---|------|-------|--------|-------|
| 1 | {YYYY-MM-DD} | — | /aid-discover | Initial generation |

## Summarization History

> One row per /aid-summarize run. Append-only.

| # | Date | Grade | Profile | Mermaid | Output | Notes |
|---|------|-------|---------|---------|--------|-------|
| 1 | {YYYY-MM-DD} | — | — | — | — | Initial run |
