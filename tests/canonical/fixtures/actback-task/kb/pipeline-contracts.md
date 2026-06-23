---
objective: Fixture pipeline-contracts doc for test-actback-task.sh
kb-category: primary
---

# Pipeline Contracts (fixture)

This is a minimal fixture KB doc for test-actback-task.sh.
It carries BOTH ## Conventions and ## Contracts sections (C2 owner of both).

## Conventions

- Pipeline stages must be named using the verb-noun pattern.
- Each stage must declare its input and output types.

## Contracts

- Every pipeline stage must satisfy the StageContract interface.
- Stages must be idempotent: re-running them must not produce duplicate outputs.
