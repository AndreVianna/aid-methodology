# task-002: P7 read-only carve-out for .aid/connectors/ in principles.md

**Type:** DOCUMENT

**Source:** work-002-external_sources -> delivery-001

**Depends on:** -- (none)

**Scope:**
- Edit `canonical/aid/templates/kb-authoring/principles.md` P7 to add a second, narrowly-scoped exemption: the P7-exempt connector sub-phase (feature-002's `ELICIT` state) may write ONLY within `.aid/connectors/` (the registry `INDEX.md` + descriptors + `.secrets/` + the connectors-local `.gitignore`). (Q10: no host-MCP-config write target — AID catalogs connections but wires nothing.)
- Prose edit only — there is no script write-scope guard to relax (`canonical/aid/scripts/kb/discover-preflight.sh` checks only STATE.md presence + Plan Mode — KI-009).
- Regenerate the 5 profiles so the rendered `principles.md` copies carry the exemption.

**Acceptance Criteria:**
- [ ] P7 body carries the new declared allowlist (the two scoped write targets), alongside the existing one-time-migration exception
- [ ] The edit makes no claim of a new pre-flight script guard (KI-009 premise preserved — carve-out is prose)
- [ ] The `principles.md` change renders identically into all 5 profiles (canonical->profiles render run)
- [ ] Accuracy verified against the current `discover-preflight.sh` and the feature-001/feature-002 SPEC wording
- [ ] All §6 quality gates pass
