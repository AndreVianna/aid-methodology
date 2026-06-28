# AID Examples

Three tutorial-style worked examples showing AID applied step by step to realistic projects. Each example walks through the relevant pipeline phases, explains the purpose of each step, and shows the key artifacts produced.

---

## Greenfield Project — full path

**Scenario:** A new project with no existing codebase. Shows how to use AID from scratch: `aid-config` → `aid-describe` (TRIAGE routes to full path) → `aid-define` → `aid-specify` → `aid-plan` → `aid-detail` → `aid-execute`.

→ [examples/greenfield/](greenfield/)

**Key takeaway:** On a greenfield project you skip Discovery and start at Interview. TRIAGE classifies the work and decides the path. The full path is appropriate when the requirements need fleshing out and the deliveries need formal sequencing.

---

## Brownfield Project — full path

**Scenario:** An existing codebase with undocumented history. Shows the full AID pipeline: `aid-config` → `aid-discover` (builds the 14-document Knowledge Base) → `aid-describe` → `aid-define` → `aid-specify` → `aid-plan` → `aid-detail` → `aid-execute`. Demonstrates how the Knowledge Base drives the spec.

→ [examples/brownfield-full-path/](brownfield-full-path/)

**Key takeaway:** Discovery turns an unfamiliar codebase into a navigable Knowledge Base in one session. Every downstream spec decision is grounded in KB evidence — not guesswork.

---

## Brownfield Project — lite path

**Scenario:** An existing codebase with a small, well-scoped change. Shows the condensed flow: `aid-describe` → TRIAGE routes to a LITE sub-path → work-root `SPEC.md` + `tasks/` → `aid-execute`. Optionally shows a recipe shortcut for a recurring pattern.

→ [examples/brownfield-lite-path/](brownfield-lite-path/)

**Key takeaway:** For small work, the lite path eliminates the overhead of the full pipeline. TRIAGE handles the routing automatically — you just answer three questions and go straight to execution.

---

## Which example should I read first?

- **New to AID?** Start with the greenfield example — it introduces the pipeline in the simplest context.
- **Inheriting an existing codebase?** Read the brownfield full-path example — Discovery is the core value proposition for brownfield work.
- **Fixing a bug or making a small change?** Read the brownfield lite-path example — it shows how to stay lean when the scope is clear.

For background on the methodology and terms used in the examples, see:
- [docs/glossary.md](../docs/glossary.md) — term definitions
- [docs/faq.md](../docs/faq.md) — how-to questions
- [docs/aid-methodology.md](../docs/aid-methodology.md) — full methodology reference
