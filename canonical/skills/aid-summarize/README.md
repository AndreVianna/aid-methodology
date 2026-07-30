> **Human-facing documentation.** Machine source consumed by `/generate-profile` is [`SKILL.md`](SKILL.md) in this folder.

# aid-summarize — Optional: Visual KB Summary

Generate a single offline HTML summary of the Knowledge Base after `/aid-discover` is approved. Optional and idempotent.

## What It Does

Produces one self-contained `kb.html` at `.aid/knowledge/` from `.aid/knowledge/`. The output is a **newcomer-facing product** — visually rich, plain-language, and distinct from the KB itself (which is a dual-audience technical artifact for humans + AI agents).

1. **Read the doc-set** — reads `discovery.doc_set` from `.aid/settings.yml` and the domain from `.aid/knowledge/STATE.md`. Resolves the section manifest: one section per KB doc present on disk, derived from each doc's frontmatter (`kb-category`, `objective`, `summary`, `tags`, `see_also`). No project-type profile is selected; section content is driven by the doc-set.
2. **Generate** — builds a multi-source layout under `.aid/.temp/summarize/summary-src/` (one HTML file per section), then assembles them into a single self-contained `kb.html`. Three KB docs receive bespoke content components rendered inline as readable content (not links): glossary terms (`domain-glossary.md`), ADR/decision cards (`decisions.md`), and capability entries (`capability-inventory.md`). All other resolved docs fall through to a generic per-fact format (table, card, prose, or infographic — whichever best communicates each fact to a newcomer).
3. **Validate** — runs machine-verifiable checks: resolved-doc-set coverage (one `SUMMARY-01` finding per unreferenced document, naming it), the §7 visual-fidelity gate (T1/T2/T3 via `validate-visuals.mjs` — **available but not invoked by the orchestrator; run it by hand, see `references/state-validate.md`**), HTML validity (H1), anchor/link integrity (L1/L2), accessibility baseline (A1–A5), WCAG AA contrast in both themes (C1/C2), offline-render completeness (S2), and the retired-engine assertion (NM). Produces **findings**, not a grade.
4. **Manual checklist** — interactive walkthrough of resolved-doc-set completeness, fact-grounding, and the mandatory human visual check. Produces **findings** too. If it has not been completed there is no grade at all — the gate pauses for the human rather than reporting a failure nobody observed.
5. **Approval gate** — the grade (one grade, from `grade.sh` over the ledger) must meet the minimum (default `A`), **and** the human checklist must have been completed, before writeback. The checklist gates by existing, not by contributing a score.
6. **Writeback** — appends an entry to `.aid/knowledge/STATE.md ## Summarization History`.

## When to Use

- After `/aid-discover` reaches DONE and the KB is user-approved.
- Optional — not required to proceed to `/aid-describe`.
- Re-runs are no-ops unless the KB has changed since the last summary, or `--reset` is passed.

## Artifacts

| Artifact | Location | Purpose |
|----------|----------|---------|
| `kb.html` | `.aid/knowledge/` | Single-file offline visual summary (newcomer-facing) |
| `summary-src/` | `.aid/.temp/summarize/summary-src/` | Multi-source layout (one section file per resolved doc; assembled into `kb.html`) |
| `## Knowledge Summary Status` | `.aid/knowledge/STATE.md` | Domain, doc-set, grades, approval status, last-run metadata |

## Quality Gate

One grading backend: `grade.sh` derives the letter from the review ledger, exactly as for every other artifact. The machine checks and the human checklist both contribute **findings** to that ledger; neither computes a grade of its own. (Earlier versions used a two-grade weighted model — a machine pool and a human pool, combined by taking the lower letter. See `knowledge-summary/grading-rubric.md` for why it was retired.) Doc-set coverage is the primary completeness signal: each KB document not represented in the summary is its own `SUMMARY-01` finding, naming that document, so coverage reports which documents are missing instead of a percentage. The grade still moves in bands (`grade.sh` counts 1 / 2-5 / 6+), so partial fixes may not move it -- what changed is that the report is per-document, not that the curve is smooth. Visuals are authored as inline SVG / HTML+CSS and pre-rendered at build time; no runtime Mermaid engine is present in the output. The §7 visual-fidelity gate (`validate-visuals.mjs`, Playwright-based) was meant to replace the retired Mermaid checks, but nothing invokes it yet — until it is wired, the mandatory human visual check is the live safeguard. There is no diagram-count floor or ceiling; visual quality is judged on fit and readability through the human visual check, never on count.
