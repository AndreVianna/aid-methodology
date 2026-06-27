---
objective: Fixture schemas doc for test-actback-task.sh
kb-category: primary
---

# Schemas (fixture)

This is a minimal fixture KB doc for test-actback-task.sh.
It carries a ## Contracts section (expected owner: C5).

## Contracts

- All API responses must include a `status` field (string).
- The `id` field must be a non-empty UUID string.
- Schemas are versioned; breaking changes require a major version bump.
