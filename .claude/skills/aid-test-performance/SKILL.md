---
name: aid-test-performance
description: >
  Run a performance verification NOW -- benchmark, load test, or stress test
  against a threshold/SLO -- and report measured-vs-threshold. A thin kind-sibling
  of /aid-test with the verification kind bound to performance. Read-only; resolves
  nothing; findings hand off to /aid-fix. This file carries no logic of its own --
  its full behavior is defined by .claude/skills/aid-test/SKILL.md.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
argument-hint: "<target + threshold> -- the hot path/endpoint and the SLO to measure against"
---

# Test Performance (performance kind-sibling of /aid-test)

`/aid-test-performance` is a thin **kind-sibling** of **`/aid-test`**
(`.claude/skills/aid-test/SKILL.md`) -- not an alias: its own catalog row
(`alias_of: null`, `{verb: test, artifact: performance}`), `repurpose: true`
(hand-authored). It carries **no logic of its own.**

Execute `.claude/skills/aid-test/SKILL.md` exactly as written, with the verification
**kind bound to performance** (capture the workload profile -- concurrency/rate/data volume
-- the threshold/SLO, and the environment; the result must be reproducible). Report
measured-vs-threshold with the workload + environment noted. Substitute only the invocation
name (`/aid-test-performance`) in any printed usage example. Findings route to `/aid-fix`.
