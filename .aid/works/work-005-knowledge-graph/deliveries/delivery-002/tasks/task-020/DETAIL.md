# task-020: `edge-relation-map.yml` and its three fail-closed map-load gates

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

**Depends on:** task-015

**Scope:**

- Create `canonical/aid/templates/graph/edge-relation-map.yml` — feature-005 D3's binding from a
  **harvest kind** (this feature's own concept, which the vocabulary cannot and should not name) to
  a vocabulary relation. A `map:` key over eleven entries, each exactly four `|`-separated fields:
  `<harvest-kind>|<emitting-pass>|<endpoint-kinds>|<relation-label>`. Fields 1–3 are fixed by
  feature-005; field 4 names a relation from delivery-001's vocabulary (task-002) by its `relation`
  label.
- The eleven kinds, with their fixed pass and endpoint pairs:
  `frontmatter-see-also|declared|kb:->kb:`, `frontmatter-sources-path|declared|kb:->int:`,
  `frontmatter-sources-url|declared|kb:->ext:`, `inline-doc-link|declared|kb:->kb:`,
  `inline-durable-anchor|declared|kb:->int:`, `evidence-citation|declared|kb:->int:,kb:->ext:`,
  `path-reference|derived|int:->int:,int:->kb:`, `invocation|derived|int:->int:`,
  `dependency|derived|int:->int:,int:->kb:`, `include|derived|int:->int:`,
  `convention|derived|int:->int:`.
- **Field 3 separates multiple pairs by comma with no space, and that is a correctness requirement.**
  A plain YAML scalar containing `: ` (colon-space) parses as a mapping, so
  `int:->int: int:->kb:` would be read as a key/value pair. Comma separation keeps every entry an
  unambiguous plain scalar and lets the loader stay a line-oriented awk pass. This file therefore
  does **not** share the vocabulary's flow-sequence encoding, and the legality gates compare the two
  **after parsing, never textually**.
- Implement the D3 loader with its fail-closed gates, all of which run at **map-load time, before a
  single row exists** — which is also why they cannot introduce per-row variability and so cannot
  threaten FR-32:
  - **Arity** — an entry that is not exactly four `|`-separated fields exits **2**, naming the
    resolved absolute path and the entry.
  - **Mapped and known** — every left-hand kind must carry a non-empty relation label, and that label
    must be a vocabulary member (via `rel_load_vocabulary`, task-015); otherwise exit 2 naming the
    path and the unmapped kind.
  - **Pass legality** — the entry's `<emitting-pass>` must appear in the mapped relation's `passes`
    list. A map routing a `derived` harvest to a relation the vocabulary marks `declared`-only is a
    configuration defect: exit 2 naming both sets.
  - **Endpoint legality** — every pair in the entry's `<endpoint-kinds>` must appear in the mapped
    relation's `endpoint_kinds`: exit 2 naming both sets.
- `t2s` is never *chosen*: the loader exposes the mapped relation's `inverse` as the only source of
  the reverse label, so a pair is internally consistent by construction.
- **Carrier note — an under-specification to confirm at review.** Feature-005's Layers & Components
  table names the template file but names **no carrier file for the loader**, while both
  `harvest-declared.sh` (task-021) and `derive-edges.sh` (task-022) must load the same map with the
  same gates. Implement it as a sourceable library at
  `canonical/aid/scripts/graph/edge-relation-map.sh`, sourced by both, so the two consumers cannot
  drift. **That path is fixed by owner decision (2026-07-28)** — it is not "confirmed at the delivery
  gate" and not this task's executor's choice, because tasks 021 and 022 both source it and a late
  placement change would break them both. Do not duplicate the loader into the two scripts.
- **Out of scope:** consuming the map to type rows — `harvest-declared.sh` (task-021) and
  `derive-edges.sh` (task-022); the vocabulary file's contents (task-002); the map-gate suite
  (task-037).

**Acceptance Criteria:**

- [ ] `canonical/aid/templates/graph/edge-relation-map.yml` exists with a `map:` key over exactly the
      eleven D3 entries, each four `|`-separated fields.
- [ ] Fields 1–3 match D3 exactly: six pass-1a `declared` kinds and five pass-1b `derived` kinds;
      `dependency` and `path-reference` each list both `int:->int:` and `int:->kb:`;
      `evidence-citation` lists both `kb:->int:` and `kb:->ext:`; `invocation`, `include` and
      `convention` list `int:->int:` only.
- [ ] Field 3's multiple pairs are comma-separated with **no space**, and no plain scalar value
      anywhere in the file contains a `: ` sequence — the parse hazard D3 records.
- [ ] Every field-4 relation label is a member of
      `canonical/aid/templates/graph/relation-vocabulary.yml` (task-002), and none is empty.
- [ ] The loader parses the file as a line-oriented awk pass, acquires no YAML binary, and is
      sourceable with no import-time side effect.
- [ ] The **arity** gate exits 2 on an entry that is not exactly four `|`-separated fields, naming
      the resolved absolute path and the offending entry.
- [ ] The **unmapped-kind** gate exits 2 on an empty relation label or a label that is not a
      vocabulary member, naming the path and the kind.
- [ ] The **pass-legality** gate exits 2 when an entry's `<emitting-pass>` is absent from the mapped
      relation's `passes` list, naming both sets.
- [ ] The **endpoint-legality** gate exits 2 when any pair in an entry's `<endpoint-kinds>` is absent
      from the mapped relation's `endpoint_kinds`, naming both sets.
- [ ] All gates run once, at load, before any row is produced — verifiable by reading the call order
      — so a misconfiguration surfaces as a usage error rather than as a table of mistyped rows, and
      no gate runs per row.
- [ ] The legality gates compare **parsed** values: the map's comma encoding and the vocabulary's
      flow-sequence encoding are reconciled after parsing, never by string comparison.
- [ ] The loader exposes the mapped relation's `inverse` as the only source of `t2s`; there is no
      code path by which a caller chooses the reverse label.
- [ ] The loader lives in exactly one file, sourced by both consumers; it is not duplicated into
      `harvest-declared.sh` and `derive-edges.sh`. Its placement is confirmed at the delivery gate,
      since feature-005's Layers table names no carrier for it.
- [ ] The file contains no repository traversal, so `tests/canonical/test-graph-single-scanner.sh`
      (task-033) passes over it.
- [ ] All existing canonical suites still pass. IMPLEMENT's "unit tests for all new public methods"
      default is **overridden** — the vehicle is `tests/canonical/test-*.sh`, which the one-type rule
      forces into a separate TEST task; the named suite lands in **task-037**, which asserts each of
      the three map-load gates exits 2.
- [ ] Only `canonical/` is edited; nothing under `profiles/` or `.claude/` is hand-edited (the FULL
      render is task-044).
- [ ] The code baseline holds (`.aid/knowledge/coding-standards.md`) and the delivery gate's
      `grade.sh` run over `.aid/.temp/review-pending/` reaches this repository's resolved
      `review.minimum_grade` of **A+** (`.aid/knowledge/quality-gates.md`) — zero findings with
      Status `Pending` or `Recurred`. REQUIREMENTS.md §6 is not a code baseline; it holds only the six
      accessibility NFRs.
