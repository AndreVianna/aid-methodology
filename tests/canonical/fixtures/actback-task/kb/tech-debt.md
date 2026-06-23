---
objective: Fixture tech-debt doc for test-actback-task.sh
kb-category: primary
---

# Tech Debt (fixture)

This is a minimal fixture KB doc for test-actback-task.sh.
It carries a ## Gotchas section (expected owner: C7).

## Gotchas

- The config file must be updated in lockstep with the schema registry.
- Build step order matters: the codegen step must run before compilation.
