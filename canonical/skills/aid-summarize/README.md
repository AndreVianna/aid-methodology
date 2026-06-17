> **Human-facing documentation.** Machine source consumed by `/generate-profile` is [`SKILL.md`](SKILL.md) in this folder.

# aid-summarize — Optional: Visual KB Summary

Generate a single offline HTML summary of the Knowledge Base after `/aid-discover` is approved. Optional and idempotent.

## What It Does

Produces one self-contained `kb.html` at `.aid/dashboard/` from `.aid/knowledge/`:

1. **Detect profile** — `web-app`, `library`, `cli`, `microservices`, `data-pipeline`, or `auto` (default).
2. **Fetch Mermaid** — caches the latest npm version to `.aid/knowledge/.cache/mermaid.min.js` (or use `--cdn-mermaid` to skip and load at runtime).
3. **Render** — inlines CSS + JS + Mermaid library + content into a single HTML file. Light/dark theme with WCAG AA contrast in both.
4. **Validate** — `mermaid.parse()` on every diagram, anchor + relative-link check, HTML validity, contrast ratios. Produces the **Machine Grade**.
5. **Manual checklist** — interactive walkthrough of KB-completeness (K1), fact-grounding (K2), and a mandatory human visual gate (V1). Produces the **Human Grade**.
6. **Approval gate** — both Machine and Human grades must meet the minimum (default `A`) before writeback.
7. **Writeback** — appends an entry to `.aid/knowledge/STATE.md ## Summarization History`.

## When to Use

- After `/aid-discover` reaches DONE and the KB is user-approved.
- Optional — not required to proceed to `/aid-interview`.
- Re-runs are no-ops unless the KB has changed since the last summary, or `--reset` is passed.

## Artifacts

| Artifact | Location | Purpose |
|----------|----------|---------|
| `kb.html` | `.aid/dashboard/` | Single-file offline visual summary |
| `.aid/knowledge/STATE.md` `## Knowledge Summary Status` | `.aid/knowledge/STATE.md` | Profile, grades, approval status, last-run metadata |
| `.aid/knowledge/.cache/mermaid.min.js` | cache | Pinned Mermaid version (gitignored) |

## Quality Gate

Strict by design: a Mermaid diagram that fails to parse is an automatic F (no exceptions). Node.js 18+ is required for diagram validation; without it the skill refuses to run.
