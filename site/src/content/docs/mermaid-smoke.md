---
title: Mermaid Smoke Test
description: Proof that Mermaid diagram rendering works in this Starlight site.
---

This page proves the Mermaid integration is working (AC5 enabler).

## AID Pipeline Overview

```mermaid
flowchart LR
    A[Orchestrator] -->|plan| B[Architect]
    B -->|SPEC.md| C[Developer]
    C -->|code| D[Reviewer]
    D -->|grade| E{Pass?}
    E -->|yes| F[Operator]
    E -->|no| C
    F -->|deploy| G[Monitor]
```

The diagram above shows the high-level AID agent pipeline: the Orchestrator coordinates
the Architect, Developer, Reviewer, Operator, and Monitor agents through iterative cycles.
