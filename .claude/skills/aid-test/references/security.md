# Test Security (security kind-sibling of /aid-test)

`/aid-test security` is a thin **kind-sibling** of **`/aid-test`**
(`.agents/skills/aid-test/SKILL.md`) -- not an alias: its own catalog row
(`alias_of: null`, `{verb: test, artifact: security}`), `repurpose: true` (hand-authored).
It carries **no logic of its own.**

Execute `.agents/skills/aid-test/SKILL.md` exactly as written, with the verification
**kind bound to security** (technique: SAST / DAST / fuzz / dependency-audit; capture the
target surface + threat focus). Substitute only the invocation name (`/aid-test security`)
in any printed usage example. Findings route to `/aid-fix` (vulnerability kind) -- this only
verifies + reports, never remediates. To AUTHOR security tests, use `/aid-create test`.
