---
name: aid-test-data-quality
description: >
  Run data-quality checks (schema, freshness, completeness, uniqueness) and report. Use to
  check data trust.
allowed-tools: Read Glob Grep Bash Shell Terminal Write Edit Agent
argument-hint: "<dataset/pipeline + checks> -- the target and which checks (schema/freshness/completeness/uniqueness)"
---

# Test Data Quality (data-quality kind-sibling of /aid-test)

`/aid-test-data-quality` is a thin **kind-sibling** of **`/aid-test`**
(`.agents/skills/aid-test/SKILL.md`) -- not an alias: its own catalog row
(`alias_of: null`, `{verb: test, artifact: data-quality}`), `repurpose: true`
(hand-authored). It carries **no logic of its own.**

Execute `.agents/skills/aid-test/SKILL.md` exactly as written, with the verification
**kind bound to data-quality** (capture the dataset/pipeline, which checks -- schema /
freshness / completeness / uniqueness -- and the pass/fail threshold per check). Report
per-check pass/fail with thresholds. Substitute only the invocation name
(`/aid-test-data-quality`) in any printed usage example. Findings route to `/aid-fix`.
