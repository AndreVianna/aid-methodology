# State: PREFLIGHT

PREFLIGHT is the synchronous gate that verifies every prerequisite before any other state runs; it is selected on every invocation, before state detection proceeds.

Run:

```bash
bash .cursor/aid/scripts/graph/graph-preflight.sh
```

It performs seven checks, P1 through P7. **The script's own `--help` is the authority for
the set and for the action each failure names** — it is not restated here, because a
second copy of a check list is a divergence waiting to happen. Two properties of it
matter to this state:

- **It writes nothing, whatever the answer.** A refusal leaves the project byte-identical
  to how the run found it. Do NOT create a state file, a scratch directory or a ledger
  before it has passed.
- **One check is not a refusal.** A missing `.aid/knowledge/external-sources.md` prints a
  notice on stderr and the run **continues**: a missing registry is zero nodes of the
  affected kinds and explicitly not an error, and the coverage notes report the absence.
  Surface the notice to the user and carry on.

Routing is carried by the exit code and by nothing else:

| Exit | Meaning | Do |
|---|---|---|
| `0` | every prerequisite holds | CHAIN to ENUMERATE |
| `1` | a prerequisite failed | **Abort the run.** Print the script's own cause line and its `→` action line verbatim; add nothing and soften nothing |
| `2` | a usage error | Abort. This is a defect in the invocation, not in the project |

**Then raise the fence, before the first write of the run:**

```bash
bash .cursor/aid/scripts/graph/kb-write-fence.sh --snapshot
```

This is the post-condition half of the read-only guarantee: the snapshot covers the
**complement** of the run's write allowlist inside `.aid/knowledge/`, and DONE — on every
exit path, including the idempotent one — verifies it. Its `--help` states the allowlist,
the four properties that make the check non-vacuous, and its exit codes. A non-zero exit
here aborts the run: a fence that could not be raised cannot be verified, and a run whose
read-only claim is uncheckable must not proceed.

Print: `[State: PREFLIGHT] complete.`

**Advance:** **CHAIN** → [State: ENUMERATE] (continue inline).
