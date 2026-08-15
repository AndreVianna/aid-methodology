---
name: aid-test-performance
description: >
  Run a performance verification against a threshold or SLO -- a benchmark, a load test, or
  a stress test -- and report measured against target. Use this skill when you need to know
  whether something is fast enough, and by how much. Read-only; it resolves nothing, and
  findings hand off to /aid-fix. A thin kind-sibling of /aid-test, which defines its full
  behavior.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
argument-hint: "<target + threshold> -- the hot path/endpoint and the SLO to measure against"
---

# Test Performance (performance kind-sibling of /aid-test)

`/aid-test-performance` is a thin **kind-sibling** of **`/aid-test`**
(`.codex/skills/aid-test/SKILL.md`) -- not an alias: its own catalog row
(`alias_of: null`, `{verb: test, artifact: performance}`), `repurpose: true`
(hand-authored). It carries **no logic of its own.**

Execute `.codex/skills/aid-test/SKILL.md` exactly as written, with the verification
**kind bound to performance** (capture the workload profile -- concurrency/rate/data volume
-- the threshold/SLO, and the environment; the result must be reproducible). Report
measured-vs-threshold with the workload + environment noted. Substitute only the invocation
name (`/aid-test-performance`) in any printed usage example. Findings route to `/aid-fix`.
