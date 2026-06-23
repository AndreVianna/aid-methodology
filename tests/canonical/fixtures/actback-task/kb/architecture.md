---
objective: Fixture architecture doc for test-actback-task.sh
kb-category: primary
---

# Architecture (fixture)

This is a minimal fixture KB doc for test-actback-task.sh.
It carries a ## Invariants section (expected owner: C1).

## Invariants

- All components must communicate through the message bus; direct calls between
  components are forbidden.
- The configuration layer must be read-only at runtime.
