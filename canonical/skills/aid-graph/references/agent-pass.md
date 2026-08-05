# The bounded agent pass (Pass 2)

This is the contract a caller must honour when it dispatches Pass 2. `references/state-extract.md`
is the caller; this document is the other end of the same restriction, and both ends state it
because the bound is false if either drops it.

Pass 1 is deterministic: it harvests what the Knowledge Base and the source **declare**, and
what the enumerator **observed**. Pass 2 is the agent half, and it exists for the
relationships that are only visible to a reader. It is bounded, and every bound below is a
property of the dispatch's *shape* rather than an instruction inside its prompt — because **a
prompt-only bound is not a bound.**

## The two dispatch shapes

| Dispatch | Count | Context it receives | Tools it receives | What it may return |
|---|---|---|---|---|
| **discovery** | one per document in the Pass-2 manifest | that **one** document's text, **inlined in the prompt**, plus the node inventory | **none — an empty tool set.** No file read, no directory listing, no shell, no network fetch | relationship rows whose two endpoints are both in the inventory |
| **typing** | exactly one | the candidate list and the node inventory, likewise **inlined** — **no document text at all** | **none — an empty tool set**, on the same terms | for each candidate: a typed relation, or a `cannot-type` disposition with a reason |

## The empty tool set is a contract term, not an assumption behind one

The bound is that each Knowledge Base document is read **at most once**. That bound is false
without the tool column: a dispatch holding a file-read or a fetch tool could read a second
document whatever its prompt said, and the read ledger the caller keeps would never see it.

Given the restriction, read-at-most-once is a property of the dispatch shape: a dispatch
cannot read a second document because it is neither given one nor able to obtain one. Outward
crawling, source-tree walking and fetching are closed off by the same fact. **Both halves are
required** — every input inlined, and no tool granted. A caller that inlines but grants a read
tool has not honoured this contract, and neither has one that grants no tools but hands over a
path instead of the text.

The read ledger the caller appends to is a check on the **dispatcher**, not on the agent: it
proves each manifest document was dispatched exactly once, and it cannot observe a read that
happened outside the dispatch. That is precisely why the tool restriction, and not the ledger,
is the load-bearing half.

## The four bounds

1. **A closed input set, each document read at most once.** The manifest is fixed before the
   pass starts and its size is reportable before any dispatch is made. One dispatch per
   manifest row, one row in the read ledger per dispatch.
2. **Edges may be created; nodes never.** Both endpoint ids of every returned row are tested
   against the union of the node streams, and anything else is rejected. Enumeration never
   admits a node on inferred evidence, and this bound stops the only later stage that could
   reintroduce one — so every node in the artifact carries declared or derived evidence, and
   no reported gap can originate in an opinion.
3. **Two kinds of work, both inside bound 1.** *Typing* the candidates Pass 1 surfaced but
   could not classify — a closed list. And *discovery*: recording relationships visible only
   by reading a document the pass is already permitted to read once. Discovery is in scope,
   and it is a list rather than an invitation: it is where the taxonomy, agreement and
   annotation relations live, and where the literal matcher's misses are recovered.
4. **A completion signal.** Every returned disposition is written down. After the pass
   returns, the emitter computes what was left undispositioned and what was left unread, and
   a non-empty either **exits `1` naming every item** — with the artifact still written. An
   untyped, undispositioned candidate is a failure, not a silent omission; otherwise the pass
   could "finish" by giving up quietly.

Every returned row carries `inferred` provenance. A row this pass produces is never
`declared` or `derived`, because it was neither declared on disk nor observed by the walk.

## What a returned row must satisfy, and what happens when it does not

The merge applies its rejections to every returned row: an endpoint that is not in the node
set, a key that collides with a frozen row, a provenance that is not `inferred`, and a
relation that is not a member of the merged vocabulary or whose declared endpoint kinds
exclude the row's kind pair. A rejected row is dropped with a reason on stderr and is never
fatal — but a rejection still gets a disposition written for it, because otherwise a rejection
would create the very shortfall bound 4 exists to catch.

## Where a `cannot-type` disposition appears, and where it deliberately does not

| Surface | Carries it? | Why |
|---|---|---|
| a relationship row | **no** | a row needs a valid relation pair. A row typed with a null relation is unrepresentable, and inventing a `cannot-type` vocabulary member would put a non-relation into a closed vocabulary |
| the artifact's `## Coverage notes` | **no** | that section sits inside the byte-identity guarantee, and a Pass-2-derived count is non-deterministic by construction. A count there would break the guarantee on every project |
| the disposition stream, the run's stdout, and the exit code | **yes** | outside the byte-identity boundary, machine-readable, and visible on every run |
| a Knowledge Base gap row | **no** | a gap row's subject is a source artifact with no covering Knowledge Base node. An untyped edge is not that |

## The one degradation, which is total

If Pass 2 cannot be dispatched **at all** — no host agent, or no way to grant an empty tool
set — then every candidate gets a `cannot-type` disposition with the reason
`pass-2-unavailable`, the completion check passes by construction, and the artifact ships with
the deterministic rows only. Say so in the run's output.

That is graceful degradation: a recorded, **total** outcome. It is not the same thing as Pass 2
running and returning while leaving a candidate undispositioned, which is the shortfall bound 4
names. Distinguishing the two is the whole point, and the same distinction the visual gate makes
when its runtime is absent: a recorded skip, never a silent pass.
