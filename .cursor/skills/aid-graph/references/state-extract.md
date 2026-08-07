# State: EXTRACT

EXTRACT harvests the Knowledge Base side of the graph, derives edges from the enumerator's observations, and then dispatches the bounded agent pass this state constructs; it is selected on a `STALE` or `FIRST_RUN` verdict, and again from FIX when the repair touched a table input.

Unlike its neighbours this state is **not** a thin router. Two of its three steps are, and
the third — the agent dispatch — is runtime work no script performs, so its shape is
specified here and nowhere else.

## Step 1 — Pass 1a, the Knowledge Base

```bash
bash .cursor/aid/scripts/graph/harvest-declared.sh
```

Route on its exit code: `0` continue, `1` or `2` abort the run printing the script's own
message. Its scan set, its node kinds, its manifest and its counters are its own; nothing
about them is restated here.

## Step 2 — Pass 1b, the enumerator's observations

```bash
bash .cursor/aid/scripts/graph/derive-edges.sh
```

Route the same way.

## Step 3 — Pass 2, the bounded agent pass — dispatched by THIS state

Pass 2's inputs are fixed before it starts: the manifest Pass 1a wrote at
`.aid/.temp/graph/pass2-inputs.tsv`, plus the node inventory and the candidate list. The
set is finite, known up front, and its size is reportable before the pass runs.

**There are exactly two dispatch shapes, and this state constructs both.**

| Dispatch | Count | Context it receives | Tools it receives |
|---|---|---|---|
| **discovery** | one per document in the manifest | that **one** document's text, **inlined in the prompt**, plus the node inventory | **an empty tool set** — no file read, no directory listing, no shell, no network fetch |
| **typing** | exactly one | `candidates.tsv` and the node inventory, likewise **inlined** — no document text at all | **an empty tool set**, on the same terms |

**The empty tool set is a contract term, not an assumption behind one.** The bound Pass 2
rests on is "each Knowledge Base document is read at most once", and that bound is *false*
without this column: a dispatch holding a file-read or a fetch tool could read a second
document whatever its prompt said, and the read ledger would never see it. Given the
restriction, read-at-most-once is a property of the **dispatch shape** — a dispatch cannot
read a second document because it is neither given one nor able to obtain one, and outward
crawling, source-tree walking and fetching are closed off the same way. Without it, the
sentences above would be mere instructions, and **a prompt-only bound is not a bound.**

**Both halves of that are load-bearing, so honour both:**

1. **Inline every input.** Read each document with `Read` in *this* state and paste its
   text into the dispatch's prompt. Never hand a dispatch a path and expect it to open it.
2. **Grant no tools.** Construct each dispatch with an empty tool set. If the host cannot
   express an empty tool set for a dispatch, Pass 2 **cannot be dispatched** — take the
   degradation in Step 5 rather than dispatching with tools, because a bound that has been
   quietly relaxed is worse than a bound that is visibly absent.

The prompt content, the four bounds and what each dispatch may return are in
`references/agent-pass.md`, which is the contract a caller must honour and the other end of
this same restriction.

**One dispatch per document, and batching is declined.** Batching several documents into
one dispatch would keep the tool set empty while weakening read-at-most-once from a
property of the shape into an instruction about the inlined text. It changes no other
contract, so if run time ever proves unacceptable the trade should be made deliberately by
the work owner rather than by drift.

## Step 4 — the read ledger

Append the dispatched document's path to `.aid/.temp/graph/pass2-reads.tsv`, **one line per
dispatch**, as each dispatch is made. Write each returned class-1 row to
`.aid/.temp/graph/rows-class1.tsv` and each returned disposition to
`.aid/.temp/graph/dispositions.tsv`.

The ledger is a check on the **dispatcher**, not on the agent: it proves each manifest
document was dispatched exactly once, and it cannot observe a read that happened outside
the dispatch. That is precisely why the tool restriction, and not the ledger, is the
load-bearing half. The authoritative check over the ledger belongs to the emitter, which
exits `1` naming every item on a shortfall — after the artifact is written, so the failure
is visible rather than hidden behind a missing file. A shortfall reported there is **this
state's** defect: it means a manifest row was never dispatched, or was dispatched twice.

## Step 5 — the one degradation, which is total and recorded

If Pass 2 cannot be dispatched **at all** — no host agent, no way to grant an empty tool
set, or a dispatch failure — then write a `cannot-type` disposition with the reason
`pass-2-unavailable` for **every** candidate, leave `pass2-reads.tsv` absent, and continue.
The artifact then ships with class-0 rows only. Say so in the run's output.

That is graceful degradation: a recorded, **total** outcome. It is not the same thing as
Pass 2 running and leaving a candidate undispositioned, which is a shortfall. Keeping the
two apart is the whole point — the first is honest, the second is a pass that "finished" by
giving up quietly.

## Step 6 — the node set is complete here, so the ceiling warning is emitted here

The node total is the count across all three producer streams — `nodes.tsv`,
`media-nodes.tsv` and `kb-nodes.tsv`. The threshold is read from its shipped carrier and
from nowhere else:

```bash
CEILING=$(sed -n 's/^node_ceiling:[[:space:]]*\([0-9][0-9]*\).*$/\1/p' \
          .cursor/aid/templates/graph/scale-ceiling.yml | head -1)
```

**The carrier's value may legitimately be absent, and an absent value is not zero.** The
ceiling is a *measured* quantity and the measurement has not landed, so the shipped file
holds the key with no value. Behave accordingly:

| `CEILING` | Print |
|---|---|
| empty (no value declared, or not a number) | `i  node total: <total>. No node-count ceiling is declared yet, so no comparison is made.` |
| a number, and `total` exceeds it | `⚠️  node total <total> exceeds the documented ceiling of <ceiling>; the graph may be hard to read at this size. The run still completes.` |
| a number, and `total` is at or below it | nothing |

Never invent a threshold, never substitute a default, and never treat an unset key as `0`
— which would warn on every project. **The exit status is unaffected in every case**: this
is a warning about legibility, never a refusal. Repeat the warning, if one was emitted, at
DONE.

Print: `[State: EXTRACT] complete.` — with the manifest size, the number of dispatches
made, and the node total.

**Advance:** **CHAIN** → [State: EMIT] (continue inline).
