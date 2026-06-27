---
kb-category: primary
source: hand-authored
objective: Architecture KB doc for closed-kb fixture -- uses Relative Bus (defined in spine).
summary: Describes the cross-domain integration architecture anchored on the Relative Bus.
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
specific routing pattern (see domain-glossary.md for the authoritative
definition).
