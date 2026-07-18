# Delivery BLUEPRINT -- delivery-003: List Management

[!NOTE]
This is the DELIVERY-LEVEL BLUEPRINT.md template. It is the IMMUTABLE DEFINITION for this delivery.
Written once by aid-plan / aid-specify; not a state file. State lives in delivery-NNN/STATE.md.

> **Delivery:** delivery-003
> **Work:** work-017-cli-improvements
> **Created:** 2026-07-18

---

## Objective

Add project-level registry list-CRUD to the project page (`home.html`): view, add, and remove
both connectors (`.aid/connectors/`) and external sources
(`.aid/knowledge/external-sources.md`). Both are structurally the same feature -- a read list
plus write-gated Add/Remove controls dispatched through feature-001's child-process mechanism to
an atomic single-entry writer (`write-connector.sh`, which also regenerates the connector
`INDEX.md`; `write-external-source.sh`, which edits the frontmatter `sources:` list and mirrors
the `## Sources` body). The connector Add path substitutes a native form for the skill's
interactive elicitation so the LLM-free server never invokes an agent (SEC-4 held). Both
registries follow the discover-authoritative + dashboard-atomic ownership model resolved in
STATE.md Q6 & Q7 (both Answered): discovery/Scout remains authoritative for the rich content, the
dashboard performs atomic single-entry add/remove -- so no `/aid-discover` change is required and
nothing in this delivery is EXECUTE-gated. Grouped because the two features share the same
list-CRUD UI shape, the same co-vendor-via-`dashboard/MANIFEST` writer pattern, and the same
ownership model.

## Scope

In scope:
- **feature-007-connectors-list** -- new `parse_connectors` reader twin + `ConnectorRef` on `RepoInfo`; `connector.set` / `connector.remove` `OP_TABLE` rows; new `write-connector.sh` + co-vendored `connector-secret.sh` / `build-connectors-index.sh`; `home.html` Connectors section (view + native Add form + Remove); secret VALUE capture stays out-of-band.
- **feature-010-external-sources-list** -- additive `repo.external_sources` DM-1 key reusing the existing parity-tested `parse_doc_frontmatter` `sources:` parser (no new parser); `external-source.add` / `external-source.remove` `OP_TABLE` rows; new `write-external-source.sh` (atomic single-entry, contiguous-block normalization, `## Sources` body mirror); `home.html` External Sources section.

**Out of scope:** the header edit (delivery-001); index.html registry/tooling (delivery-002); pipeline delete (delivery-004); execution control (delivery-005). Neither writer synthesizes rich semantic content (connector prose / the external-sources `| Path | Type | Accessible | Key Content |` table) -- that stays a discovery/Q&A concern per the Q6/Q7 ownership model.

## Gate Criteria

- [ ] AC1 (connectors) -- adding/removing a connector runs from the dashboard via `write-connector.sh` (reproducing the connector skill's non-interactive effect + `INDEX.md` regen) and persists to disk.
- [ ] AC1 (external sources) -- adding/removing an entry runs from the dashboard via `write-external-source.sh` and persists to `.aid/knowledge/external-sources.md` (frontmatter `sources:` authoritative; `## Sources` body kept truthful).
- [ ] AC2 (both) -- after any add/remove, the list re-renders from a post-write `/r/<id>/api/model` read off disk with no drift; every dashboard-managed entry is reader-visible (contiguous-block normalization for external sources).
- [ ] Ownership -- dashboard writes are single-entry and atomic and follow the discover-authoritative + dashboard-atomic model (STATE.md Q6 & Q7); no `/aid-discover` change is required and no step is EXECUTE-gated.
- [ ] SEC-4 -- the server never invokes an agent/LLM skill; both Add paths dispatch a deterministic shell writer via an argv array.
- [ ] AC4 / AC8 (inherited) -- reader twins stay byte-consistent (new `connectors` + `external_sources` keys, fixtures regenerated in lockstep); controls honour `write_enabled` (read-only under `--remote` without `--allow-writes`, list still viewable).
- [ ] All section-6 quality gates pass

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-018 | IMPLEMENT | write-connector.sh atomic single-entry writer + connector co-vendor |
| task-019 | IMPLEMENT | ConnectorRef reader/model + connector.set/remove ops |
| task-020 | IMPLEMENT | write-external-source.sh atomic single-entry writer |
| task-021 | IMPLEMENT | External-sources reader/model + external-source.add/remove ops |
| task-022 | IMPLEMENT | Shared list-CRUD UI (Connectors + External Sources) |
| task-023 | TEST | List-management op round-trips + parser parity |

## Dependencies

- **Depends on:** delivery-001 (write foundation: `OP_TABLE`, write gate, child dispatch, co-vendor mechanism, re-render contract)
- **Blocks:** -- (none)

## Notes

Both writers are co-vendored via a single `dashboard/MANIFEST` edit each (guarded by
`test-dashboard-manifest.sh`). The external-sources writer's entry alphabet is deliberately
identical to `lint-frontmatter.sh sources_entry_shape()` so dashboard writes keep the KB linter
green. `write-connector.sh` is a deliberate bash-only exception to the connectors area's
Bash+PowerShell-twins convention (server-dispatched, never on the PowerShell CLI path) -- a KB
follow-up note, not a defect.
