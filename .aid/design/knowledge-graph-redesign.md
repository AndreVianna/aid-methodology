# Design seed — Knowledge Graph redesign (agent-consumable)

**Status:** not started · **Seeded:** 2026-08-08 · **Predecessor:** work-005 (knowledge graph, PR #178, merged)

> Everything needed to scope and run this work is in this file. It is a seed: when the work
> ships, delete it — the design will then live in the realised code and KB.

---

## 1. Why this work exists

work-005 shipped a knowledge relationship graph that is **correct and unusable by its intended
consumer**.

`.aid/knowledge/relationships.md` is **1,068,408 bytes ≈ 267,000 tokens**. Its stated purpose is
to give agents context about the repository. No agent can read it. At the time of seeding, **no
consuming skill references it** — the only skills that mention the file are `aid-graph`'s own
build states, which *write* it.

Every gate passed: schema conformance, byte-identity, render fidelity, ~149 CI suites, mutation
matrices proving assertions can fail. **No gate asked whether the consumer could consume the
output.** That is an acceptance-criteria failure, not an execution failure, and §7 exists to
stop it recurring.

The visual graph (`graph.html`) was the human-facing half and works. It is **not** the objective
here. This work is about the machine-facing half.

---

## 2. What to KEEP — do not regress these

| Property | Where it lives | Why it matters |
|---|---|---|
| **Extraction is fully deterministic, zero LLM** | `harvest-declared.sh` — "every node id is a pure function of document bytes" | Reproducible, free, auditable. Matches the best comparable tooling's headline claim. |
| **Exactly one repository walk** | `scan-source.sh`; asserted by `tests/canonical/test-graph-single-scanner.sh` | Cost control and a single source of truth for traversal |
| **Byte-stable output** | merge → normalise → de-dup by a total rule → sort under `LC_ALL=C` | Enables byte-identity testing and trivial conflict resolution |
| **Bidirectional relation names** (`s2t` + `t2s`) | `relationship-schema.yml` | An edge reads as a sentence in either direction. Better than the single-`relation`-plus-arrow model most tools use. |
| **Re-runnable evidence, not line numbers** | the `Observation` column, e.g. `inbound reference (search: "README.md" in .aid/settings.yml)` | An instruction the agent can execute to verify. Does not rot when files move — unlike `file:line` citations. |
| **Provenance per edge** | `declared` / `derived` / `inferred` | Already a confidence ranking; §5 uses it as one |

---

## 3. Measured evidence

### 3.1 Scale — this is a small-data problem

| | |
|---|---|
| Edge rows | 3,551 |
| Distinct node ids | 1,006 |
| Node kinds | source-artifact 497 · **section 340** · fact 84 · concept 32 · document 21 · image 2 |
| All pipeline intermediates | ~25,000 rows |

The whole graph loads in milliseconds. **There is no sharding, streaming, or database-scale
problem.** The engine's only job is to be a boundary: machine reads 3,551, agent receives ~40
lines.

The **340 `section` nodes** are the most under-used asset — an answer can point at a heading
rather than a whole document. Largest token saving available.

### 3.2 Build time — 2 hours, and it is an implementation defect

Reconstructed from artifact mtimes of a real run:

| Window | Duration | Produced |
|---|---|---|
| →13:42 | — | `scan-source.sh` output (nodes, observations, candidates) |
| 13:42→14:38 | **56 min** | `candidates-pass1a.tsv` — **524 lines** |
| 14:38→14:50 | 12 min | pass1a rows, pass1b, dispositions |
| 14:50→15:11 | 21 min | class0 rows, concept-merge candidates, coverage notes |
| 15:11→15:38 | **27 min** | `relationships.md` |

*Caveat: the 56-minute window cannot be attributed from mtimes alone — it may include agent turns
inside `/aid-graph`'s states. Measure it before assuming. The 27-minute window is script time.*

Measured on the authoring host (Windows/MSYS, 300 iterations):

| Call style | Cost each |
|---|---|
| `key=$(fn …)` — forks a subshell | **51 ms** |
| `fn "$a" "$b"` — direct call | **0.5 ms** |

**A 100× penalty.** See §4.

### 3.3 Data quality — schema conformance is not data quality

- **18 edges carry an empty `Provenance`** though the schema marks it required.
- **`inferred` is declared in the vocabulary and used zero times.** A third of the provenance
  vocabulary is aspirational.
- Rows citing **deleted files** survive a rebuild — nothing validates that a cited path exists.

### 3.4 The artifact is machine-hostile

`relationships.md` mixes edge rows with narrative and metrics tables. A naive parse of its
`|`-prefixed lines yields "node kinds" such as `yes`, `no`, and
`citationmarkersskippedforwantofananchorstring:1771`. **Any parser over this file is fragile by
construction.**

---

## 4. Part A — the fork-storm fix (independently shippable)

**This part can be pulled forward and shipped on its own, before the rest.** It changes no
interfaces and has a hard correctness oracle.

### The defect

`canonical/aid/scripts/graph/build-relationships.sh`:

- `:298` — `key=$(rel_row_key "$sid" …)` — **one subshell fork per row** (3,551 rows)
- `:314` — `if [ "$(br_prov_rank "$prov")" -gt "$(br_prov_rank "$cur_prov")" ]` — **two more per
  duplicate key**

At 51 ms per fork this projects to minutes for `:298` alone, matching the observed 27-minute
stage.

### The fix already exists in the same file

Lines **287–288** record that `rel_normalise_row` deliberately avoids `$( )` — it sets a global
and the caller reads it — because command substitution stripped trailing newlines. **The correct
pattern was found for one function and never applied to its neighbours.** Convert `rel_row_key`
and `br_prov_rank` to the same convention.

> **Standing rule:** when a performance convention is discovered, sweep the codebase for the
> signature. Fixing only the instance in front of you leaves the rest.

### How to benchmark it (no full pipeline run needed)

`build-relationships.sh` takes `--temp-dir` and `--out`, so it runs fully sandboxed:

```bash
# stage real inputs from a previous run
cp .aid/.temp/graph/*.tsv  "$BENCH/temp/"
bash canonical/aid/scripts/graph/build-relationships.sh \
     --temp-dir "$BENCH/temp" --out "$BENCH/relationships.md"
```

Time it before and after.

### The correctness oracle — non-negotiable

**The output must be byte-identical, only faster.** Capture `relationships.md` before the change,
diff after. A performance fix that alters output is a behaviour change wearing a performance
label.

### Also sweep

Other per-row `$( )` in the graph scripts — the 56-minute `pass1a` window is unexplained and may
be the same cause in `harvest-declared.sh`. Measure it before assuming.

---

## 5. Part B — the data model

Today there is **one** record type: a denormalised edge with node fields repeated per row. That
is why nodes cannot carry anything.

### 5.1 Nodes get properties

```json
{ "id": "kb:technology-stack.md", "kind": "document", "name": "Technology Stack",
  "origin": ".aid/knowledge/technology-stack.md",
  "hash": "sha256:…",
  "text": { "objective": "…", "summary": "…", "tags": ["stack","deps"], "owner": "architect" } }
```

**The `text` block is the highest-value single change.** The graph currently holds *no summaries* —
only names. Yet every KB document already declares `objective`, `summary`, `tags`, `owner` in its
frontmatter. That is exactly the text an agent needs to decide *"is this the document I want?"*,
and it is thrown away today.

Cap it: summaries for the 21 documents, headings only for the 340 sections.

### 5.2 Edges get identity, origin, structured evidence

```json
{ "id": "e:4a91…", "src": "int:.aid/settings.yml", "tgt": "int:README.md",
  "s2t": "depends-on", "t2s": "dependency-of",
  "provenance": "derived", "confidence": 2,
  "evidence": { "type": "grep", "file": ".aid/settings.yml", "query": "README.md" },
  "origin": ".aid/settings.yml" }
```

**`origin` is the linchpin.** Nothing today records which file produced an edge, so precise
invalidation is impossible — which is why full rebuild is the only update path and why stale rows
survive.

### 5.3 Physical form

| File | Role | Property |
|---|---|---|
| `nodes.jsonl`, `edges.jsonl` | **truth** | one record per line, sorted by id, deterministic, no timestamps |
| `relationships.md` | **a short report** — counts, gaps, top-connected, what changed | human-facing; **no longer the parse target** |
| `table.html` | exhaustive human view | already exists, unchanged |

Keeping timestamps *out* of the JSONL is deliberate: it preserves byte-identity testing, makes
merge conflicts resolvable by regenerating rather than hand-merging, and lets mutable state live
in a separate control file.

**No database.** At ~1 MB a full scan is milliseconds. SQLite was considered and rejected for v1:
it buys nothing at this scale and costs a build step plus a staleness surface. Revisit only if
full-text search or deep traversal measurably hurts.

---

## 6. Part C — the query surface (the actual objective)

An agent must be able to ask a question and get a **scoped, ranked, token-capped** answer.

### 6.1 The dominant query is a one-hop join, not a traversal

Node kinds split on a clean seam: `int:`/`ext:` are *the world*; `kb:` is *what we claim to know
about it*. Most agent questions cross that seam:

> *"I'm about to edit `int:<path>`. Which KB documents claim something about it, how confident
> are they, and what did they claim?"*

That is **one hop** — a filtered lookup on an edge list, no graph algorithms. Estimated ~80% of
the value. Path-finding and multi-hop are the remaining 20%. **Build the one-hop join first.**

### 6.2 Required elements

| Element | Requirement |
|---|---|
| **Token budget** | `--budget N`, default ~2,000. Truncate explicitly with *"use --budget N for more"* — never silently. |
| **Vocabulary fence** | Build a token vocabulary from node names/summaries. The agent may select **only** tokens present in it. No invented tokens, no near-synonyms from memory. Print the expansion so it is auditable. **If nothing matches, say so and stop — do not fabricate a search.** |
| **Ranking** | exact id > name > summary/tags > observation, tie-broken by **provenance** (`declared` > `derived` > `inferred`), then degree |
| **Answer shape** | a **ranked reading list with reasons** — *"read these 3 documents, in this order, because…"* — not a raw subgraph dump. This is a deliberate divergence from comparable tooling. |
| **Grounding rules** | answer only from what the graph contains; quote the `Observation` (which is re-runnable) when citing; if the graph lacks the information, say so — never invent edges |
| **Traversal modes** | BFS depth ≤3 for "what touches X"; DFS depth ≤6 for "how does X reach Y" |

---

## 7. Part D — updating the graph when the KB changes

**Decide this by measurement, not up front.**

Everything below exists only to avoid full rebuilds. If Part A brings a full build into the
minutes range, **delete this entire section from the plan**: `aid-update-kb`, `aid-discover` and
`aid-housekeep` simply call a full rebuild, there is no invalidation logic, and therefore no
invalidation bugs.

Only if a full rebuild remains expensive:

- Give the two existing passes a scope flag — `scan-source.sh --only <paths>` (the single-walk
  invariant and its test stay intact, because it remains the only walker) and
  `harvest-declared.sh --only <docs>`.
- **Delete-by-origin, then re-extract.** This is the only shape that converges on *deletions*; a
  resync that only copies never does.
- Keep an `origins` control file: path + hash + row count. It is both the incremental control and
  the staleness oracle.
- **Per-answer staleness** beats a global stale flag: every answer lists the origins it cited; if
  one changed on disk, flag *that claim*. A global "graph is stale" banner is something people
  learn to ignore.

Skill wiring, either way:

| Skill | Trigger |
|---|---|
| `aid-update-kb` | after its CONFIRM'd edit — it already knows exactly which documents it touched |
| `aid-discover` | batch, at end of phase |
| `aid-housekeep` | full verify — rehash, prune origins that no longer exist, report drift |

---

## 8. Binding acceptance criteria

These are the criteria whose absence produced the outcome in §1. **The work is not done without
them.**

1. **Token budget** — every agent-facing artifact declares a maximum, and a test asserts a real
   query's answer fits it.
2. **Consumption test** — an AC must be *an agent answering real questions from the artifact
   alone*, not "the file validates".
3. **Wall-clock budget** — the build declares a time budget, measured before and after.
   Performance that no criterion names will not be measured.
4. **Fork budget** for hot shell loops — a per-row `$( )` is a defect, not a style preference.
5. **Data-quality assertions**, not only schema assertions — no required enum may be blank; a
   declared vocabulary value never used is either wrong or should be removed.
6. **Machine-consumed artifacts hold data only** — narrative and metrics go in a separate report.
7. **Hallucination fence on retrieval** — see §6.2. Ships in v1 or the engine lies confidently.

---

## 9. Explicitly out of scope / do not do

- **No CDN-loaded anything.** The current viewer vendors its dependencies and works offline; the
  most popular comparable tool loads its renderer from unpkg and cannot render without network.
- **No LLM in extraction.** Determinism is the point and it is already achieved.
- **No community detection** (Leiden et al.). Valuable at 100k code nodes; near-useless at 1,006.
- **No incremental-update machinery before measuring** a post-fix full build (§7).
- **Do not redesign the visual graph.** It works and it is not this work's problem.

---

## 10. Open questions for the interview

1. Does `relationships.md` losing "source of truth" status change its `kb-category`, or should it
   leave `.aid/knowledge/` entirely once it is a report?
2. Is `aid-ask` the right consumer for the query surface, or does this need its own skill?
3. Should `int:` nodes carry any text at all, or only `kb:` ones?
4. What is the wall-clock budget for a full build — the number that decides §7?

---

## 11. Prior art

`Graphify-Labs/graphify` (Apache-2.0, ~104k★, YC S26) solves the adjacent problem — mapping
*code* via tree-sitter AST so an agent queries instead of grepping. Studied for §6; the token
budget, vocabulary fence, and grounding rules are adapted from its query reference.

Differences worth keeping in mind: it maps code, we map the *knowledge base and its coverage of
the repo* — different jobs, not competitors. It is ahead on query surface, ingestion breadth, and
incremental updates. We are ahead on offline operation, accessibility, bidirectional relations,
re-runnable evidence, and a human-reviewable source of truth.
