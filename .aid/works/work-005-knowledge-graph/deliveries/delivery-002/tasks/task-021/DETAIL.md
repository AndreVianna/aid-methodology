# task-021: `harvest-declared.sh` `kb:` node set and declared-edge carriers

> **Execution protocol (binding on whoever executes this task -- no
> exceptions):** the moment this task's `State` changes, write it --
> `In Progress` before starting work, `In Review` before dispatching the
> reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally
> whether the main/orchestrator agent executes this task directly or
> dispatches it to a sub-agent; neither may skip, batch, or defer these
> writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- it is never
> self-written by the task being executed.) Full mandate:
> `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** IMPLEMENT

**Source:** work-005-knowledge-graph -> delivery-002

**Depends on:** task-014, task-020

**Scope:**

- Create `canonical/aid/scripts/graph/harvest-declared.sh` — feature-005's **pass 1a**, Feature Flow
  steps 1–4.
- **Build the `kb:` node set (D2)** at `.aid/.temp/graph/kb-nodes.tsv`: `kb_id | name | doc |
  anchor`, one row per KB document and one per ATX heading within it, `kb_id` per feature-003 D2a
  and `name` per feature-003 D5. This is the one node set no walk of the project source could
  produce, which is why it is owned here rather than by feature-004.
- The document scan set is the same *set* `build-kb-index.sh` indexes — the membership predicate
  `find .aid/knowledge -maxdepth 1 -type f -name '*.md' ! -name '.*'` — but the **order** is this
  script's own `LC_ALL=C` sort. `build-kb-index.sh`'s bare `| sort` is deliberately not inherited as
  an ordering precedent (feature-003 D2a; feature-005 FR-32 mechanism 3).
- **Exclude `relationships.md` and `INDEX.md` as *sources* of edges while keeping both as valid
  *targets*.** `relationships.md` self-exclusion is mandatory, not tidiness: harvesting edges from
  the artifact being written would make the output depend on the previous run's output and make
  FR-32 unprovable. `INDEX.md` exclusion prevents manufacturing a `kb:INDEX.md -> kb:<doc>` edge for
  every document plus a duplicate of every `see_also:` edge already harvested from the source doc. A
  hand-authored doc citing `INDEX.md` still produces a real edge.
- Read each source doc's frontmatter in **one batched awk pass per doc** — the pattern
  `lint-frontmatter.sh` (`load_frontmatter`) and `kb-freshness-check.sh` (`fm_scalar` / `fm_list`)
  establish — with arrays populated and no per-field fork.
- Emit one row per **D4 declared carrier**: `frontmatter-see-also`, `frontmatter-sources-path`,
  `frontmatter-sources-url`, `inline-doc-link`, `inline-durable-anchor`, `evidence-citation`. Stamp
  `provenance = declared`, `class = 0`; type each through the edge-relation map by **sourcing**
  `canonical/aid/scripts/graph/edge-relation-map.sh` (task-020) rather than reimplementing its loader
  or its three fail-closed gates — task-022 sources the same library, and the whole point of the
  shared carrier is that the two consumers cannot drift; set
  `observation` to the matched carrier anchor (e.g.
  `authoring-conventions.md sources: .claude/aid/scripts/kb/lint-frontmatter.sh`).
- `inline-durable-anchor` matches with the exact character class and extension set
  `kb-citation-lint.sh` already uses. `frontmatter-sources-url` matches the URL shape
  `kb-freshness-check.sh`'s `is_url` uses, and emits `ext:<key>` **only if** the URL resolves to a
  registered key — which on this repository is zero keys today, exactly as Q4 found.
- **Explicitly not edges:** the frontmatter `contracts:` list (structural cardinality assertions, not
  references to a node), and `tags:`, `audience:`, `owner:`, `changelog:`.
- **Resolution never guesses.** A `sources:` glob is expanded against `nodes.tsv` and each match
  becomes an edge; a glob matching nothing becomes a candidate. A basename citation resolving to
  exactly one surviving node becomes an edge; more than one, or zero, appends to `candidates.tsv`
  with `drop_reason` `ambiguous-basename` or `unresolved-reference`.
- The KB read is a **single-directory, non-recursive depth-1 read**, not a repository walk, so it
  does not breach the single-scanner seam — `tests/canonical/test-graph-single-scanner.sh` (task-033)
  is scoped to traversals rooted at the repo root.
- **Out of scope:** typing feature-004's observations (task-022); the merge, ordering, render and
  self-validation (tasks 023, 024); the declared-carrier suite (task-036); the scanner streams
  themselves (tasks 018, 019).
- Conventions: `set -euo pipefail`; the `while … case … shift 2` argument loop, unknown flag ->
  stderr + exit 2; a one-line `[harvest] …` stderr summary; exit `0` / `1` / `2` per feature-005's
  scheme.

**Acceptance Criteria:**

- [ ] `canonical/aid/scripts/graph/harvest-declared.sh` exists with `#!/usr/bin/env bash`,
      `set -euo pipefail`, a Purpose / Usage / Exit-codes header, `-h|--help`, and a `[harvest] …`
      one-line stderr summary.
- [ ] `.aid/.temp/graph/kb-nodes.tsv` carries `kb_id | name | doc | anchor` with one row per KB
      document and one per ATX heading, tab-separated, `LC_ALL=C`-sorted, LF-only.
- [ ] The document scan set is D2a's membership predicate exactly, and the output's order comes from
      this script's own `LC_ALL=C` sort — no ordering is inherited from `build-kb-index.sh`'s bare
      `sort`.
- [ ] `relationships.md` and `INDEX.md` produce **zero** outbound edges, and both remain resolvable
      as edge targets — a fixture doc citing `INDEX.md` still yields a row.
- [ ] Exactly one row is emitted per D4 carrier occurrence, each stamped `declared` / `class = 0`,
      each typed through the edge-relation map, each carrying the matched carrier anchor as its
      `observation` — and every anchor is a durable anchor (a path plus a grep-recoverable literal),
      never a `file.ext:LINE` citation.
- [ ] Frontmatter is read one batched awk pass per document; no per-field fork appears in the script.
- [ ] `contracts:`, `tags:`, `audience:`, `owner:` and `changelog:` produce no edge.
- [ ] Every `int:` endpoint the pass emits appears in `nodes.tsv` and every `kb:` endpoint in
      `kb-nodes.tsv` — pass 1 may only emit rows over the closed node set.
- [ ] An unresolvable or ambiguous reference appends a `candidates.tsv` row with
      `unresolved-reference` / `ambiguous-basename` and emits no row.
- [ ] `frontmatter-sources-url` emits an `ext:` endpoint only for a URL that resolves to a registered
      key; against this repository's zero-entry `external-sources.md` it emits none, and the pass
      does not fail because of that.
- [ ] No relation label appears in the script — every label arrives through the edge-relation map
      plus `rel_load_vocabulary`.
- [ ] The script contains no repository traversal; its KB read is depth-1 and non-recursive, so
      `tests/canonical/test-graph-single-scanner.sh` (task-033) passes over it.
- [ ] Exit codes are `0` / `1` / `2` with feature-005's stated meanings; no new code is invented.
- [ ] All existing canonical suites still pass. IMPLEMENT's "unit tests for all new public methods"
      default is **overridden** — the vehicle is `tests/canonical/test-*.sh`, which the one-type rule
      forces into a separate TEST task; the named suite lands in **task-036**
      (`test-harvest-declared.sh`), carrying one fixture per D4 carrier plus the
      `relationships.md` / `INDEX.md` source-exclusion assertions.
- [ ] Only `canonical/` is edited; nothing under `profiles/` or `.claude/` is hand-edited (the FULL
      render is task-044).
- [ ] The code baseline holds (`.aid/knowledge/coding-standards.md`) and the delivery gate's
      `grade.sh` run over `.aid/.temp/review-pending/` reaches this repository's resolved
      `review.minimum_grade` of **A+** (`.aid/knowledge/quality-gates.md`) — zero findings with
      Status `Pending` or `Recurred`. REQUIREMENTS.md §6 is not a code baseline; it holds only the six
      accessibility NFRs.
