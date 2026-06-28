# Delivery SPEC -- delivery-005: Build-Time Conformance

[!NOTE]
This is the DELIVERY-LEVEL SPEC.md template. It is the IMMUTABLE DEFINITION for this delivery.
Written once by aid-plan / aid-specify; not a state file. State lives in delivery-NNN/STATE.md.

> **Delivery:** delivery-005
> **Work:** work-001-aid-interview-improvements
> **Created:** 2026-06-27

---

## Objective

Close the greenfield lifecycle loop: once a forward-authored seed (delivery-004) exists and code is
later written, verify the code CONFORMS to the design and surface any divergence for deliberate,
human-gated reconciliation -- never silently replace the design with as-built. A NEW code->design
conformance check (the inverse of f007's read-only source->doc freshness), so the authored design
stays the source of truth until a human reconciles drift.

## Scope

feature-005-build-time-conformance: the extract-and-diff detection mechanism (an additive
`output_root` parameter on the aid-discover extraction subagents so the as-built KB extracts into a
`.aid/.temp/conformance/as-built/` shadow tree -- never touching `.aid/knowledge/` by construction --
a keep-only-in-scope filter, a concern-keyed structured diff at the seed's declared altitude, and a
divergence classifier); the aid-housekeep KB-DELTA conformance lane that carves `source:
forward-authored` docs OUT of the normal doc<-code update lane (the NFR-5-forbidden direction) into
the flag-not-overwrite lane; and the human-gated reconciliation flow (authority stays design->code).
Also includes the OPTIONAL discoverability **signpost** in `aid-execute`'s `state-delivery-gate.md`
(a one-line "forward-authored design present -- run /aid-housekeep to check conformance" pointer; no
mechanism) -- owner-added 2026-06-27 so the conformance check is discoverable right after a greenfield
delivery builds code.

**Out of scope:** the engine (delivery-003), the seed model (delivery-004 -- consumed here), the
skill split (delivery-006). No change to brownfield code-is-truth docs or to f007 itself.

## Gate Criteria

- [ ] A greenfield-origin doc whose content diverges from as-built code is FLAGGED for human reconciliation and is NOT auto-overwritten (AC-6).
- [ ] Detected divergence is human-gated; authority stays design->code until reconciled (AC-6 / NFR-5); forward-authored docs are routed out of the doc<-code update lane.
- [ ] The shadow extraction never writes `.aid/knowledge/` (the `output_root` parameter enforces this by construction; the KB-doc destination is parameterized while the `.aid/generated/` side-output is preserved for existing callers).
- [ ] The check is scoped via `source: forward-authored`; brownfield docs and f007 behavior are unchanged.
- [ ] All section-6 quality gates pass (incl. the master-only heavy gates).

## Tasks

{Filled by aid-detail. Includes the build-time tuning of the seed-altitude `code-ahead` filter (fixture-driven, per the feature DoD).}

| Task | Type | Title |
|------|------|-------|
| task-028 | IMPLEMENT | output_root dispatch parameter on the aid-discover extraction subagents |
| task-029 | IMPLEMENT | Forward-authored carve in the aid-housekeep KB-DELTA review routing |
| task-030 | IMPLEMENT | Extract-and-diff conformance sub-step + divergence classifier |
| task-031 | IMPLEMENT | Human-gated flag-not-overwrite reconciliation flow |
| task-035 | IMPLEMENT | Optional conformance signpost in aid-execute delivery-gate |
| task-032 | CONFIGURE | Full generator render + 5-profile/.claude propagation + DBI |
| task-033 | TEST | output_root parameter conformance verification -- shadow-write isolation + caller invariance |
| task-034 | TEST | Conformance-lane verification -- flag-not-overwrite + NFR-5 carve + altitude tuning + brownfield-intact |

## Dependencies

- **Depends on:** delivery-004 (the forward-authored seed model + marker it checks against)
- **Blocks:** delivery-006 (a sequencing edge -- both edit `aid-discover/references/state-generate.md`; d006 must run after d005)

## Notes

Touches the aid-housekeep KB-DELTA reference + the aid-discover extraction subagents (the additive
`output_root` parameter in `aid-discover/references/state-generate.md`) -- DIFFERENT surfaces from
the interview SKILL dir, so it does not collide with delivery-003/004. It DOES, however, share
`state-generate.md` with delivery-006 (whose name-sweep rewrites the `/aid-interview` tokens there),
so delivery-006 is sequenced AFTER this delivery to avoid a parallel-edit collision. Sequenced after
delivery-004 because it needs the seed model to exist.
