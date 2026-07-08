# task-016: Wire-on-declare hook in the connector sub-phase

**Type:** IMPLEMENT

**Source:** work-002-external_sources -> delivery-002

**Depends on:** task-015, task-008

**Scope:**
- Complete ELICIT's descriptor-write step 4 (deferred in task-008): after an `mcp` descriptor is authored, invoke task-015's `wire <stem>` op for installed hosts. Edit `canonical/skills/aid-discover/references/state-elicit.md`; renders to all 5 profiles.
- `api | ssh | url | cli` descriptors need no wiring step.

**Acceptance Criteria:**
- [ ] Declaring an `mcp` tool in ELICIT triggers `wire <stem>` for installed hosts; a non-`mcp` connector triggers no wiring
- [ ] The hook honors wire-only-installed and reference-not-value by delegating to task-015 (it adds no wiring logic of its own)
- [ ] The change renders identically into all 5 profiles; existing aid-discover suites + dogfood checks pass; build/render passes
- [ ] All §6 quality gates pass
