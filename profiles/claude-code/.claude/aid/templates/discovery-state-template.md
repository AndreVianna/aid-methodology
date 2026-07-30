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
> `bash .claude/aid/scripts/config/read-setting.sh --skill <name> --key <key> --default <fallback>`

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
     run-state (profile/theme/grades/output) and stay here as markdown body.

     TWO FORMS, AND WHICH FIELD TAKES WHICH IS NOT A STYLE CHOICE. The table holds the
     artifact's standing properties; the bold lines below it hold what a single run
     produced, and are written by the state that produced them. Declaring a field in
     one form while its writer emits the other is the misparse this section already
     suffered once: `Grade` and `Checklist` were declared as table rows here while
     `aid-summarize/references/state-generate.md` writes them as bold lines and
     `state-approval.md` calls `Checklist` "an agent-written body line" -- three
     surfaces, two forms, for a field introduced in one delivery.

     NOT DECLARED HERE, and a pre-existing gap rather than part of that fix: GENERATE
     writes 17 body lines into this section (the 3 below, plus Doc-Set Source, Doc-Set
     Count, Domain, Domain Source, Theme, Minimum Grade, Minimum Grade Source, Last Run,
     Trigger Reason, Output, Output Size, Last Reviewed KB Date, Last Summary Date,
     Writeback Status). Two of those -- Theme and Output -- ALSO appear as rows of the
     table below, which is the same dual representation in the other direction, and two
     more restate frontmatter scalars under different names (Last Reviewed KB Date vs
     `last_kb_review`, Last Summary Date vs `last_summary`). Count derived from
     state-generate.md, not asserted. Reconciling all 17 is outside delivery-015's scope
     (its scope is the grading backend); recorded in the work STATE so the next change
     to this section starts from the real list. -->

| Field | Value |
|-------|-------|
| Profile | {auto-detected: web-app/library/cli/microservices/data-pipeline OR user-specified} |
| Profile Source | {auto-detected \| user-specified} |
| Profile Confidence | {high \| medium \| low \| n/a} |
| Theme | {default \| brand-{name}} |
| Output | {kb.html (size) or --} |
| Mermaid Version | {pinned version or --} |
| Mermaid Cached | {.aid/knowledge/.cache/mermaid.min.js (sha256) or --} |

Run-state body lines, written by GENERATE and updated by VALIDATE / APPROVAL:

```markdown
**Grade:** {grade or Pending}
**Grade Source:** `grade.sh`, over `.aid/.temp/review-pending/summarize.md`
**Checklist:** {Not run | Completed YYYY-MM-DD}
```

## Criteria Gaps

<!-- AUTHORED by gap-register.sh, never by hand. This is the KB-scope register: gaps raised while
     reviewing Knowledge Base documents land here.

     A criteria gap is "there is no rule to judge this by" -- a missing PRECONDITION of the review,
     not a defect in the artifact under review.

     A KB-scope gap ALSO gets a companion `Impact: Required` entry in ## Q&A (Pending) below. That
     is not duplication: it makes the existing Q-AND-A state pick the gap up with no change to that
     state at all, because Q-AND-A already drives every Pending entry to a terminal answer and
     already makes APPROVAL unreachable while any remains.

     This file is git-tracked, so the record outlives both the halt and the ledger's deletion at
     DONE. Full cell contracts: work-state-template.md ## Criteria Gaps. -->

| Gap Key | Kind | Status | Depth | Recurrences | Scope | Criterion | Resolution |
|---|---|---|---|---|---|---|---|
| _none yet_ | | | | | | | |

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
