# State: EMIT

EMIT assembles the coverage-notes section and then writes `.aid/knowledge/relationships.md`; it is selected after EXTRACT completes.

**This state is a router with one local step.** The artifact's schema, its column order, its
row ordering, its frontmatter block and its self-validation belong to the emitter. Nothing
about them is restated here.

## Step 1 — assemble the coverage-notes section

```bash
bash .agent/aid/scripts/graph/assemble-coverage-notes.sh
```

This is the seam where the two producers' machine contributions become the rendered
section, and it is the cheapest place to catch two mistakes that would otherwise surface
as a validator failure on an already-written artifact: a table's fixed block that did not
receive exactly one row per fixed key, and an extra key that collides. Its `--help` states
the field reordering, the exclusion-key translation and the extra-row order.

| Exit | Do |
|---|---|
| `0` | continue to step 2 |
| `1` | **Abort before writing the artifact.** Print the named offenders; this is a producer-contribution defect, and emitting over it would produce an artifact the table validator rejects |
| `2` | Abort. A usage error or an unreadable contribution |

## Step 2 — write the artifact

```bash
bash .agent/aid/scripts/graph/build-relationships.sh
```

| Exit | Do |
|---|---|
| `0` | continue to step 3 |
| `1` | The artifact **has been written**. A write failure, a self-validation finding, or a Pass-2 completion shortfall. Print the script's own message; a shortfall is EXTRACT's defect and its items are named. Continue to step 3 and let VALIDATE grade what was written — a defect in an artifact this run is about to repair belongs in the ledger, not in an abort |
| `2` | Abort. A malformed carrier or a missing input stream: no artifact was written and there is nothing to grade |

## Step 3 — carry this run's two scalars into the frontmatter

The staleness record and the run timestamp are **this feature's** two reserved frontmatter
scalars. They sit outside the artifact's byte-identity boundary by design, which is what
lets a content-addressed record live in a generated file without colliding with the
guarantee that two runs over unchanged inputs produce the same bytes. Insert them into the
frontmatter block of the artifact just written, using the composite STALE-CHECK already
printed on its `graph_inputs_digest:` line:

```
graph_inputs_digest: <the exact string STALE-CHECK printed>
graph_generated_at: <UTC, date -u +%Y-%m-%dT%H:%M:%SZ>
```

Do not recompute the digest here — a value computed twice is a value that can differ — and
do not reformat it: the whole string's equality is the staleness test.

`relationships.md` is on the run's write allowlist, so this write does not trip the fence.
It is also the only write this state makes outside the run's scratch.

Print: `[State: EMIT] complete.` and the artifact path.

**Advance:** **CHAIN** → [State: GAP-REPORT] (continue inline).
