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
> `bash .github/aid/scripts/config/read-setting.sh --skill <name> --key <key> --default <fallback>`

## External Documentation

| Path | Type | Accessible | Notes |
|------|------|------------|-------|
| {/path/to/docs or "None provided"} | {file/directory} | {✅/❌} | {brief note} |

## KB Documents Status

> One row per document in the project's **confirmed doc-set** (`discovery.doc_set` in
> `.aid/settings.yml`, resolved at aid-discover Step 0d from the project's domain). The set is
> **domain-driven and varies per project** — do NOT hardcode a fixed doc list here. This table
> is seeded empty and populated by aid-discover during GENERATE (Step 6) from the resolved
> doc-set; when no doc-set is declared yet, the default 15-doc seed applies.

| # | Document | Status | Grade | Last Reviewed | Notes |
|---|----------|--------|-------|---------------|-------|
| _none yet_ | _populated from the confirmed doc-set at Step 6_ | — | — | — | |

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
| Output | {kb.html (size) or —} |
| Mermaid Version | {pinned version or —} |
| Mermaid Cached | {.aid/knowledge/.cache/mermaid.min.js (sha256) or —} |

## Q&A (Pending)

> Open questions about KB facts, raised by any skill, awaiting human input or downstream resolution. Each entry: ID, category, impact, suggested answer (if inferrable), status.

### Q{N}

- **Category:** {category, e.g., Architecture, Security, UX}
- **Impact:** {High|Medium|Low|Required}
- **Status:** Pending | Answered | Skipped
- **Context:** {why this matters; what the downstream phase observed; cite a durable anchor (file + symbol) if applicable}
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
