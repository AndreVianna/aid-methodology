---
kb-category: primary
source: hand-authored
objective: Test concept spine fixture where ALL candidate terms are defined (closed state).
summary: Fully-closed spine defining SpineAnchor and ClosedConcept, so output (a) is empty.
sources: []
tags: [test-fixture]
---

# Domain Glossary

## Concept Spine

### SpineAnchor

**Definition-as-used-here:** The anchor mechanism that grounds a concept in the spine.

**Relates-to:** ClosedConcept (uses the anchor).

**sources:**
- `src/spine.ts:SpineAnchor`

---

### ClosedConcept

**Definition-as-used-here:** A concept that is fully defined in the spine with no open terms.

**Relates-to:** SpineAnchor (the grounding mechanism).

**sources:**
- `src/closed.ts:ClosedConcept`

---
