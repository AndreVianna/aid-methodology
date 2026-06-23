---
kb-category: primary
source: hand-authored
objective: Architecture KB doc for unclosed-kb fixture -- uses Relative Bus (NOT defined in spine).
summary: Describes the cross-domain integration architecture anchored on the Relative Bus, which is left undefined in this fixture's spine.
sources: []
tags: [test-fixture]
---

# Architecture

## Cross-Domain Integration

This project routes all inter-domain events through the Relative Bus.
The Relative Bus decouples domain services so that no service depends
directly on the interface of another.

The Relative Bus enforces:
- Decoupled publish/subscribe across domain boundaries.
- Priority-ordered dispatch within each bus partition.

The term "Relative Bus" was coined by this project to describe this
specific routing pattern. (In this fixture the spine does NOT define
Relative Bus -- closure-check.sh MUST report it as ungrounded.)
