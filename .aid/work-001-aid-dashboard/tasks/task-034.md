# task-034: Shared schema_version 1→3 + front-end EXPECTED + grow PT-1 fixture (007+008 combined cut)

**Type:** IMPLEMENT

**Source:** feature-007-kb-dashboard + feature-008-skill-task-drilldown → delivery-005

**Depends on:** task-031, task-033

**Scope:**
- Apply the SINGLE combined `schema_version` bump `1 → 3` agreed for delivery-005 (PLAN R2 / feature-007 DD-2 1→2 for `KbModel` + feature-008 DD-2 2→3 for the `details` map, shipped as one `schema_version: 3` cut): set the constant in BOTH servers (`server.py`, `server.mjs`) and the front-end's `EXPECTED` in lockstep so the stale-assets banner fails loud on mismatch (feature-003 DM-1 / Feature Flow 3b).
- Grow the PT-1 fixture `.aid/` (task-018) to cover the combined cut: a populated `.aid/knowledge/` with a README `## Completeness` table, a `STATE.md ## Knowledge Summary Status` block, an INDEX (incl. a stale-INDEX case) for `KbModel`; AND a work with a `## Quick Check Findings` block, a `## Delivery Gates` block, and a `delivery-NNN-issues.md` for `TaskDetail` — plus a STATE.md containing `U+2028`/`U+2029` exercised through both `KbModel` and `details` (feature-003 DM-3 escaping).
- This is the coordination cut: front-end `EXPECTED`, both server constants, and the PT-1 fixture move together (one fixture pass, one coordination point — not two churns).

**Acceptance Criteria:**
- [ ] Both servers emit `schema_version: 3` and the front-end `EXPECTED` is `3`; a server/page version mismatch trips the stale-assets banner (fail-loud, not mis-render).
- [ ] The PT-1 fixture is grown to exercise both the rich `KbModel` (README table + summary block + INDEX incl. a stale case) and the lazy `details`/`TaskDetail` (findings + delivery-gates + issues file), with a `U+2028`/`U+2029` STATE.md flowing through both.
- [ ] The 1→3 bump is a single combined cut (no intermediate `2`-only shipped state) per the delivery-005 R2 coordination.
- [ ] The front-end `EXPECTED`, both server constants, and the fixture are changed in lockstep (no drift).
- [ ] All §6 quality gates pass (REQUIREMENTS.md baseline).
- [ ] IMPLEMENT default: the parity re-validation (task-036) consumes this fixture; existing tests pass; build passes.
