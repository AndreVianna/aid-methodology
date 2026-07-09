# Delivery SPEC -- delivery-003: Idempotent Reconcile

> **Delivery:** delivery-003
> **Work:** work-002-external_sources
> **Created:** 2026-07-08

---

## Objective

Make `aid-discover` safe to re-run over a project's life: reconcile the connectors registry
against the freshly declared set — add new descriptors, update changed ones in place, and
remove absent ones while purging their local secrets — without clobbering surviving entries or
their secrets, with no index churn (the deterministic builder), and interrupt-safe
(purge-before-delete so an interrupted removal re-converges on the next run). REMOVE = delete the descriptor + purge the local secret (**aid-managed connectors only**); there
is **no unwire step** (Q10 supersedes Q8 — AID never wrote a host config to unwire).

## Scope

In scope — features:
- **feature-006-idempotent-reconcile** — the reconcile diff (add/update/remove keyed on the
  descriptor filename stem); remove-and-purge via feature-003's `connector-secret purge` op;
  INDEX regeneration via feature-005's deterministic builder; the auth-downgrade orphan disposal
  is owned by feature-003 (not reconcile) and is out of this delivery's write path. There is **no
  unwire** (Q10 supersedes Q8 — AID wrote no host config).

**Out of scope:** initial registration / elicitation (delivery-001); the secret twin and INDEX
builder themselves (owned by 003/005 in delivery-001) — this delivery only orchestrates them. Any
host-MCP-config wiring/unwiring (removed entirely by Q10 — delivery-002 withdrawn).

## Gate Criteria

- [ ] AC-6 — Re-running `aid-discover` after add/change/remove reconciles the registry without losing surviving entries or their stored secrets; a removed tool's associated local secret is purged from the store.
- [ ] Idempotent — a second run on unchanged input is a clean no-op (byte-identical `INDEX.md` via the deterministic builder; no duplicate/empty artifacts).
- [ ] Interrupt-safe — purge-before-delete: an interrupt between purge and descriptor delete leaves the stem re-derivable so REMOVE re-runs; re-purge is a clean no-op.
- [ ] REMOVE purges the local secret (aid-managed connectors only) and deletes the descriptor, purge-before-delete; there is no unwire step (Q10 supersedes Q8).
- [ ] All section-6 quality gates pass.

## Tasks

Navigational overview (authored by `aid-detail`). Full definitions live in `tasks/task-NNN/SPEC.md`; execution order is in `PLAN.md` `## Execution Graph`.

| Task | Type | Title |
|------|------|-------|
| task-018 | IMPLEMENT | Reconcile diff orchestration (R0-R5) in the connector sub-phase |
| task-019 | TEST | Reconcile scenario tests |

## Dependencies

- **Depends on:** delivery-001 (the former delivery-002 dependency is dropped — delivery-002 withdrawn, Q10)
- **Blocks:** -- (none)

## Notes

Reconcile is pure orchestration — it owns no store, twin, or builder. It composes
feature-002's declared set + ELICIT re-entry, feature-003's `purge` op (aid-managed connectors
only), and feature-005's deterministic INDEX builder. There is no wiring/unwiring to compose
(Q10 — feature-004 is a documentation/contract feature with no code; delivery-002 withdrawn).
