---
name: aid-test-security
description: >
  Run a security verification and consolidate the findings -- SAST, DAST, fuzzing, or a
  dependency audit. Use this skill when you need to know what is currently exploitable or
  outdated. Read-only; it resolves nothing, and findings hand off to /aid-fix. A thin
  kind-sibling of /aid-test, which defines its full behavior.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
argument-hint: "<target> -- the endpoint/module/dependency set to verify"
---

# Test Security (security kind-sibling of /aid-test)

`/aid-test-security` is a thin **kind-sibling** of **`/aid-test`**
(`.agent/skills/aid-test/SKILL.md`) -- not an alias: its own catalog row
(`alias_of: null`, `{verb: test, artifact: security}`), `repurpose: true` (hand-authored).
It carries **no logic of its own.**

Execute `.agent/skills/aid-test/SKILL.md` exactly as written, with the verification
**kind bound to security** (technique: SAST / DAST / fuzz / dependency-audit; capture the
target surface + threat focus). Substitute only the invocation name (`/aid-test-security`)
in any printed usage example. Findings route to `/aid-fix` (vulnerability kind) -- this only
verifies + reports, never remediates. To AUTHOR security tests, use `/aid-create-test`.
