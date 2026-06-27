---
kb-category: primary
source: hand-authored
objective: Concept spine fixture for closure-check.sh -- UNCLOSED state (Relative Bus omitted).
summary: Spine that defines only RelativeME but omits Relative Bus -- closure-check output (a) must report Relative Bus as ungrounded.
sources: []
tags: [test-fixture]
---

# Domain Glossary

## Concept Spine

### RelativeME

**Definition-as-used-here:** The early working name for the cross-domain routing
layer. See architecture.md for current usage context.

**Relates-to:** (no cross-references defined in this fixture).

**sources:**
- `docs/adr/0007-relative-bus.md`

---

<!-- NOTE: Relative Bus is intentionally OMITTED from this spine.
     This is the unclosed-kb fixture: architecture.md uses "Relative Bus"
     but the spine does not define it. closure-check.sh output (a) MUST
     report "relative bus" as an ungrounded term. -->
