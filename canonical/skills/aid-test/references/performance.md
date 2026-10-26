# Test Performance (performance kind-sibling of /aid-test)

`/aid-test performance` is a thin **kind-sibling** of **`/aid-test`**
(`.agents/skills/aid-test/SKILL.md`) -- not an alias: its own catalog row
(`alias_of: null`, `{verb: test, artifact: performance}`), `repurpose: true`
(hand-authored). It carries **no logic of its own.**

Execute `.agents/skills/aid-test/SKILL.md` exactly as written, with the verification
**kind bound to performance** (capture the workload profile -- concurrency/rate/data volume
-- the threshold/SLO, and the environment; the result must be reproducible). Report
measured-vs-threshold with the workload + environment noted. Substitute only the invocation
name (`/aid-test performance`) in any printed usage example. Findings route to `/aid-fix`.
