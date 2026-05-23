# Rough-Time-Hints Table

This table is the source of truth for what AID skills bracket with `▶/✓` lines
per FR1 AC2 (work-003-traceability). The hint expansion fires when a SKILL's body
calls `read-hint <class-name>` in a bracket-pair line. Every operation class listed
here is considered long enough to warrant a bracket pair; the threshold is
qualitative, not numeric. Sub-second tool calls are NOT in this table by design —
if an operation completes in under a second it generates more noise than signal and
should not be bracketed.

| Operation Class | Expected Time Band | Notes |
|---|---|---|
| `discovery-architect` | ~3–5 min | Reads and synthesises repo structure for architecture KB doc |
| `discovery-analyst` | ~3–5 min | Reads code patterns, coding standards, data model, module map |
| `discovery-integrator` | ~3–5 min | Reads integration points, API contracts, external sources |
| `discovery-quality` | ~3–5 min | Reads test landscape, security model, tech-debt, infrastructure |
| `discovery-scout` | ~2–4 min | Initial repo scan; produces project-structure and external-sources KB docs |
| `discovery-reviewer` | ~2–3 min | Reviews all KB docs for accuracy, counts, cross-doc consistency |
| `reviewer` | ~1–2 min | Reviews task output against acceptance criteria and grading rubric |
| `developer` (IMPLEMENT) | ~3–8 min | Writes code + unit tests; time scales with task complexity |
| `developer` (DOCUMENT) | ~1–3 min | Writes documentation artifact; shorter than code tasks |
| `developer` (TEST) | ~2–5 min | Writes and runs integration/E2E tests |
| `architect` | ~2–4 min | Designs or reviews architecture decisions |
| `validate-html.sh` | ~30 s | Runs html-validate on the knowledge-summary HTML output |
| `validate-links.sh` | ~30 s | Checks internal and external link integrity |
| `validate-diagrams.mjs` | ~30 s | Renders Mermaid diagrams via mmdc and checks output |
| `contrast-check.mjs` | ~30 s | Checks WCAG contrast ratios for all colour pairs |
| `/aid-generate` (end-to-end) | ~1–2 min | Runs run_generator.py across all 3 profiles; includes VERIFY-4a |
