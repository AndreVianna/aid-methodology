# State: ENUMERATE

ENUMERATE walks the project source once and writes the node, observation, candidate and coverage streams the rest of the run consumes; it is selected after PREFLIGHT passes.

**This state is a router.** The traversal, what counts as significant, the exclusion
classes and every stream's field shape belong to `scan-source.sh`, which owns the one walk
of the project source. Nothing about it is restated here — its `--help` is the authority
for its flags, its outputs and its exit codes.

Run:

```bash
bash .claude/aid/scripts/graph/scan-source.sh
```

Route on its exit code:

| Exit | Do |
|---|---|
| `0` | CHAIN to STALE-CHECK |
| `1` | Abort the run. Print the script's own message; a write failure or a rejected row is not something this state can repair |
| `2` | Abort the run. Print the script's own message |

**Why this state runs before STALE-CHECK, and not after.** One of the staleness digest's
components is defined over the enumerated node set, and a newly added artifact is
invisible to any stored path list — so the enumeration has to have happened before
staleness can be decided. What a `CURRENT` verdict saves is the expensive half: the
two-pass extraction with its bounded agent step, and the render. This half is the cheap,
deterministic one, and it writes **only allowlisted scratch** — which is why the no-op
this run may still reach is stated as *no durable write*, and why DONE removes the scratch
on that path too.

Print: `[State: ENUMERATE] complete.` and the counts the script reported.

**Advance:** **CHAIN** → [State: STALE-CHECK] (continue inline).
