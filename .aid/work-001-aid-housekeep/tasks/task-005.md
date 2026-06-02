# task-005: `scope-delta.sh` — path→doc scoping map + owner resolution

**Type:** IMPLEMENT

**Source:** feature-002-kb-delta-refresh → delivery-001

**Depends on:** task-001

**Scope:**
- Implement `canonical/scripts/housekeep/scope-delta.sh` (feature-002 SPEC § "Path→Doc Scoping
  Map", § "Resolution algorithm", § Components / Scripts). Pure bash; no `yq`/`python`.
- Embed the **path-prefix→docs table** verbatim from feature-002 SPEC § Path→Doc Scoping Map
  (all 13 rows, including `.aid/knowledge/**` → **skip** and *anything unmapped* → **flag for
  user**), resolved by longest-prefix match. This map is **distinct from** `aid-discover`'s
  filename→owner map in `doc-set-resolve.md` and must not be conflated (Q1 naming).
- Resolution algorithm: read changed paths on stdin → longest-prefix match → union into the
  affected-doc set → resolve each affected doc to its owning discovery agent via
  `aid-discover`'s **existing** `owner-of <filename>` accessor (`references/doc-set-resolve.md`,
  sourced over `read-setting.sh --path discovery.doc_set`). Handle the two no-dispatch cases
  per feature-002 SPEC § Resolution algorithm step 4: **owner = `orchestrator`** and **owner
  resolves to empty** (doc not in active doc-set) — both surfaced as "no owning sub-agent —
  flagged for orchestrator/manual refresh" and routed to orchestrator regeneration, keeping the
  algorithm total over any doc-set. Emit deduped **affected docs** and **owning agents** lists
  on stdout; print `UNMAPPED` to stderr.

**Acceptance Criteria:**
- [ ] Each path-prefix row resolves to the expected doc set under longest-prefix match.
- [ ] `.aid/knowledge/**` paths → skip; an unmapped path → flagged on stderr (not silently
  dropped) — NFR3 transparency.
- [ ] doc→owner resolution matches `owner-of` for the default seed; `orchestrator`-owned and
  empty-owner docs are routed to orchestrator regeneration (no sub-agent dispatch), keeping
  resolution total.
- [ ] An empty affected-doc set after mapping (all changed paths were KB self-edits) is
  surfaced as a no-delta/skip signal for the body.
- [ ] A canonical unit suite `tests/canonical/test-housekeep-scope-delta.sh` (auto-discovered by
  the `tests/canonical/test-*.sh` glob, sourcing `tests/lib/assert.sh`) drives fixtured
  changed-path lists, mirroring `tests/canonical/test-doc-set-mapping.sh` /
  `test-discovery-doc-ownership.sh` (feature-002 SPEC § Testing `test-housekeep-scope-delta.sh`).
- [ ] All §6 quality gates pass (NFR3/NFR5); build/render passes; all existing tests pass.
