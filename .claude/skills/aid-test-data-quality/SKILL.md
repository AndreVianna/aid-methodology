---
name: aid-test-data-quality
description: >
  Run data-quality checks against thresholds and report -- schema, freshness, completeness,
  uniqueness. Use this skill when you need to know whether a dataset or pipeline is
  currently trustworthy. Read-only; it resolves nothing, and findings hand off to /aid-fix.
  A thin kind-sibling of /aid-test, which defines its full behavior.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
argument-hint: "<dataset/pipeline + checks> -- the target and which checks (schema/freshness/completeness/uniqueness)"
---

# Test Data Quality (data-quality kind-sibling of /aid-test)

`/aid-test-data-quality` is a thin **kind-sibling** of **`/aid-test`**
(`.claude/skills/aid-test/SKILL.md`) -- not an alias: its own catalog row
(`alias_of: null`, `{verb: test, artifact: data-quality}`), `repurpose: true`
(hand-authored). It carries **no logic of its own.**

Execute `.claude/skills/aid-test/SKILL.md` exactly as written, with the verification
**kind bound to data-quality** (capture the dataset/pipeline, which checks -- schema /
freshness / completeness / uniqueness -- and the pass/fail threshold per check). Report
per-check pass/fail with thresholds. Substitute only the invocation name
(`/aid-test-data-quality`) in any printed usage example. Findings route to `/aid-fix`.
