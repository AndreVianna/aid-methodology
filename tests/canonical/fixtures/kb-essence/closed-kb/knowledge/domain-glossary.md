---
kb-category: primary
source: hand-authored
objective: Concept spine fixture for closure-check.sh -- CLOSED state (Relative Bus defined).
summary: Fully-closed spine defining Relative Bus and RelativeME so closure-check output (a) is empty.
sources: []
tags: [test-fixture]
---

# Domain Glossary

## Concept Spine

### Relative Bus

**Definition-as-used-here:** The project-coined cross-domain routing layer that
every domain service publishes to and subscribes from. No service calls another
domain service directly; all inter-domain events are routed through the Relative
Bus, which guarantees priority-ordered, decoupled delivery across service
boundaries.

**Relates-to:** RelativeME (earlier working name -- now superseded).

**sources:**
- `src/bus/relative.ts`
- `docs/adr/0007-relative-bus.md`

---

### RelativeME

**Definition-as-used-here:** The early working name for what became the Relative
Bus. All references have been updated to Relative Bus in current code and docs.

**Relates-to:** Relative Bus (the canonical current term for this concept).

**sources:**
- `docs/adr/0007-relative-bus.md`

---
