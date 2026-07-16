---
name: aid-test-security
description: >
  Run a security verification NOW -- SAST, DAST, fuzzing, or dependency audit --
  and consolidate findings. A thin kind-sibling of /aid-test with the verification
  kind bound to security. Read-only; resolves nothing; findings hand off to
  /aid-fix. This file carries no logic of its own -- its full behavior is defined
  by .claude/skills/aid-test/SKILL.md.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
argument-hint: "<target> -- the endpoint/module/dependency set to verify"
---

# Test Security (security kind-sibling of /aid-test)

`/aid-test-security` is a thin **kind-sibling** of **`/aid-test`**
(`.claude/skills/aid-test/SKILL.md`) -- not an alias: its own catalog row
(`alias_of: null`, `{verb: test, artifact: security}`), `repurpose: true` (hand-authored).
It carries **no logic of its own.**

Execute `.claude/skills/aid-test/SKILL.md` exactly as written, with the verification
**kind bound to security** (technique: SAST / DAST / fuzz / dependency-audit; capture the
target surface + threat focus). Substitute only the invocation name (`/aid-test-security`)
in any printed usage example. Findings route to `/aid-fix` (vulnerability kind) -- this only
verifies + reports, never remediates. To AUTHOR security tests, use `/aid-create-test`.
