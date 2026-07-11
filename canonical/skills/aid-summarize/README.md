> **Human-facing documentation.** Machine source consumed by `/generate-profile` is [`SKILL.md`](SKILL.md) in this folder.

# aid-summarize — Optional: Visual KB Summary

Generate a single offline HTML summary of the Knowledge Base after `/aid-discover` is approved. Optional and idempotent.

## What It Does

Produces one self-contained `kb.html` at `.aid/knowledge/` from `.aid/knowledge/`. The output is a **newcomer-facing product** — visually rich, plain-language, and distinct from the KB itself (which is a dual-audience technical artifact for humans + AI agents).

1. **Read the doc-set** — reads `discovery.doc_set` from `.aid/settings.yml` and the domain from `.aid/knowledge/STATE.md`. Resolves the section manifest: one section per KB doc present on disk, derived from each doc's frontmatter (`kb-category`, `objective`, `summary`, `tags`, `see_also`). No project-type profile is selected; section content is driven by the doc-set.
2. **Generate** — builds a multi-source layout under `.aid/.temp/summarize/summary-src/` (one HTML file per section), then assembles them into a single self-contained `kb.html`. Three KB docs receive bespoke content components rendered inline as readable content (not links): glossary terms (`domain-glossary.md`), ADR/decision cards (`decisions.md`), and capability entries (`capability-inventory.md`). All other resolved docs fall through to a generic per-fact format (table, card, prose, or infographic — whichever best communicates each fact to a newcomer).
3. **Validate** — runs machine-verifiable checks: resolved-doc-set coverage (COV — forces Machine Grade F if < 60% of resolved docs are referenced), §7 visual-fidelity gate (T1/T2/T3 via `validate-visuals.mjs`, Playwright-based — readable text, minimal overlap, correct layout for every authored inline SVG or infographic), HTML validity (H1), anchor/link integrity (L1/L2), accessibility baseline (A1–A5), WCAG AA contrast in both themes (C1/C2), offline-render completeness (S2), and no-Mermaid-engine assertion (NM). Produces the **Machine Grade**.
4. **Manual checklist** — interactive walkthrough of resolved-doc-set completeness (K1), fact-grounding (K2), and a mandatory human visual gate (V1). Produces the **Human Grade**.
5. **Approval gate** — both Machine and Human grades must meet the minimum (default `A`) before writeback.
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

Two-grade model: a Machine Grade (script-verifiable AUTO_POOL checks, 68 pts) and a Human Grade (manual-checklist MANUAL_POOL, 30 pts). The Overall Grade is the lower of the two letter grades. The COV check (resolved-doc-set coverage) is the primary completeness gate — a summary that omits more than 40% of the resolved KB docs forces Machine Grade F. Visuals are authored as inline SVG / HTML+CSS and pre-rendered at build time; no runtime Mermaid engine is present in the output. The §7 visual-fidelity gate (T1/T2/T3, `validate-visuals.mjs`, Playwright-based) replaces the retired Mermaid D1/D2 checks. There is no diagram-count floor or ceiling; visual quality is graded on fit and readability (V1 human gate), never on count.
