---
kb-category: meta
source: generated
objective: Discovery-area run-state ledger — the Knowledge Base's review/grade history, approval state, pending Q&A, and visual-summary status for this project.
summary: Read this for the KB's current grade, approval state, open questions, and summarization status — the process/run-state behind the knowledge docs, not knowledge content itself. One STATE.md per `.aid/knowledge/`.
tags: [meta, state, run-state, review-history, qa, approval]
see_also: [README.md, INDEX.md]
owner: skill-self
audience: [developer, architect]
kb_status: Initial | In Progress | Approved
kb_grade: "{grade or Pending}"
last_kb_review: "{YYYY-MM-DD or --}"
summary_approved: yes | no
last_summary: "{YYYY-MM-DD or --}"
---

# Discovery State

> **Source:** aid-config (creates) · aid-discover + aid-summarize (update)
> **User Approved:** yes | no

This is the single state file for the **Discovery area** — persistent project knowledge: the Knowledge Base + the visual summary. One STATE.md per project's `.aid/knowledge/` directory. Absorbs what used to be `DISCOVERY-STATE.md` + `SUMMARY-STATE.md`.

> **Project-level settings** (minimum grade, heartbeat interval, max parallel tasks,
> etc.) live in `.aid/settings.yml`, not here. STATE.md is for run-state only —
> per-area review history, Q&A, current-cycle grade snapshots. Resolve any
> configured value via:
> `bash .codex/aid/scripts/config/read-setting.sh --skill <name> --key <key> --default <fallback>`

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

<!-- The summary's approval scalar (`summary_approved`) and its last-run date
     (`last_summary`) live in the YAML frontmatter block at the top of this file --
     the single scalar there replaces the table-row-vs-bold-line dual representation
     that used to cause a silent misparse. The remaining fields below are non-approval
     run-state (profile/theme/grades/output) and stay here as markdown body. -->

| Field | Value |
|-------|-------|
| Profile | {auto-detected: web-app/library/cli/microservices/data-pipeline OR user-specified} |
| Profile Source | {auto-detected | user-specified} |
| Profile Confidence | {high | medium | low | n/a} |
| Theme | default | brand-{name} |
| Machine Grade | {grade or Pending} |
| Human Grade | {grade or Pending} |
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
