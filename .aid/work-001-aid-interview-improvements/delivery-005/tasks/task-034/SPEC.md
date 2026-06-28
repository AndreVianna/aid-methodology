# task-034: Conformance-lane verification -- flag-not-overwrite + NFR-5 carve + altitude tuning + brownfield-intact

**Type:** TEST

**Source:** work-001-aid-interview-improvements -> delivery-005

**Depends on:** task-032

**Scope:**
- Verify delivery-005's conformance lane against its gate criteria and feature-005 DoD V1-V6. Skills are
  prose-executed and not unit-tested by design, so this task runs the AID AI + human-review DoD via dogfood
  transcripts + the reviewer checklist over purpose-built fixtures (a greenfield forward-authored seed + as-
  built code), plus the EXISTING brownfield canonical tests + the §6 heavy gates. It authors no new skill
  content.
- **(A) Divergence flagged, not auto-overwritten (AC-6 / FR-4 / DoD V1):** on a fixture greenfield seed +
  as-built code that CONTRADICTS a declared invariant, run /aid-housekeep and confirm the divergence is
  flagged (Required Q&A + present-the-choice) AND the `.aid/knowledge/*.md` forward-authored doc is
  BYTE-UNCHANGED after the run (no auto edit).
- **(B) Human-gated, design->code until reconciled (AC-6 / NFR-5 / C-4 / DoD V2):** confirm the flag pauses
  for the per-item choice; with NO choice made the design doc stays authoritative and unchanged; only an
  explicit "evolve the design" choice edits it (via `/aid-discover` targeted re-entry).
- **(C) The NFR-5 carve holds (NFR-5 / AC-6 / DoD V4):** confirm running /aid-housekeep on a greenfield seed
  does NOT overwrite the seed via KB-DELTA's Tier-2 update-the-doc path -- the carve routes it to
  flag-not-overwrite. Regression-verify against the pre-carve behavior.
- **(D) Marker scoping + brownfield intact (C-1 / NFR-2 / AC-10 / DoD V3, V6):** with a mixed-source fixture,
  confirm a `hand-authored` doc of the same filename NEVER enters the conformance lane (stays in the
  source->doc / update-the-doc lane); f007, KB-DELTA brownfield (`hand-authored` source->doc), and the
  aid-discover extraction path pass their EXISTING tests; the carve + lane are purely additive.
- **(E) Degradation + altitude-filter tuning (FR-4 / DoD V5):** with no code yet, confirm the lane no-ops.
  With code, confirm a `code-ahead` top-ranked term and a `placeholder-resolved` TBD version are flagged
  while a sub-altitude implementation-only identifier is NOT flagged -- and TUNE the seed-altitude threshold
  in task-030's classifier prose on this fixture until the false-positive control holds (the build-time
  fixture-tuning item; loop back to task-030 + re-render if the prose must change).
- **(F) §6 master-only heavy gates:** run `tests/run-all.sh` (HOME-pinned) and the `site` Astro build
  locally; both green.
- Record results to this task's STATE.md / the delivery gate; file any [HIGH]/[CRITICAL] findings per the
  ledger schema. Out of scope: fixing lane content defects (loop back to the owning task 029-031); the
  output_root parameter guarantees (task-033).

**Acceptance Criteria:**
- [ ] A fixture seed + invariant-contradicting code yields a flagged divergence (Required Q&A + present-the-choice) and the forward-authored `.aid/knowledge/*.md` doc is byte-unchanged after the run. *(AC-6/FR-4, DoD V1; gate criterion 1)*
- [ ] The flag is human-gated: with no choice made the design doc stays authoritative and unchanged; only an explicit "evolve the design" choice edits it via `/aid-discover` targeted re-entry. *(AC-6/NFR-5/C-4, DoD V2; gate criterion 2)*
- [ ] The NFR-5 carve holds: /aid-housekeep on a greenfield seed does NOT overwrite it via Tier-2 update-the-doc; the forward-authored doc is routed to flag-not-overwrite (regression-verified vs pre-carve). *(NFR-5/AC-6, DoD V4; gate criteria 1, 2)*
- [ ] Marker scoping + brownfield intact: a same-named `hand-authored` doc never enters the conformance lane; f007 + KB-DELTA brownfield + aid-discover extraction existing suites pass; the lane is purely additive. *(C-1/NFR-2/AC-10, DoD V3/V6; gate criterion 4)*
- [ ] Degradation + altitude filter: the lane no-ops with no code; with code a `code-ahead` top-ranked term + a `placeholder-resolved` TBD version are flagged while a sub-altitude identifier is NOT -- the seed-altitude threshold is fixture-tuned until the false-positive control holds. *(FR-4, DoD V5)*
- [ ] Master-only heavy gates pass locally: `tests/run-all.sh` (HOME-pinned) and the `site` Astro build. *(gate criterion 5)*
- [ ] Tests are deterministic with clean setup/teardown; all delivery-005 gate criteria and feature-005 ACs (AC-6) + DoD V1-V6 are covered (the output_root-specific guarantees are covered by task-033). *(TEST defaults)*
