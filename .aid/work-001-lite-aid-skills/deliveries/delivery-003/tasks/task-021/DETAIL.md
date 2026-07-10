# task-021: Prototype family -- catalog rows + prototype.md scaffolding

**Type:** IMPLEMENT

**Source:** work-001-lite-aid-skills -> delivery-003

**Depends on:** task-008, task-009

**Scope:**
- Add 2 rows to `canonical/aid/templates/shortcut-catalog.yml` (no aliases): `aid-prototype` (bare) and `aid-prototype-ui` (artifact=ui); both `default_type: DESIGN`, group G3.
- Create `canonical/aid/templates/shortcut-scaffolding/prototype.md`: CAPTURE slots (prototype: direction/hypothesis, fidelity, success signal, scope boundary; prototype-ui: target screens/flow, key interactions + states, visual reference, nav context); SPEC activation (prototype: base Feature Flow only; prototype-ui: `### UI Specs` + Feature Flow + a11y note; Data Model "no schema changes"); task templates (prototype: `001` DESIGN + optional `002` IMPLEMENT throwaway spike; prototype-ui: `001` DESIGN wireframe/flow + optional `002` DESIGN clickable flow).
- Generate the 2 skill dirs via `build-shortcut-skills.py`.

**Acceptance Criteria:**
- [ ] 2 rows/dirs added (`aid-prototype`, `aid-prototype-ui`); both DESIGN (AC-1 G3 subset).
- [ ] `prototype.md` defines slots + SPEC activation + DESIGN task templates per feature-005; the ownership boundary hands the real build off to `aid-create`/`aid-change`.
- [ ] Renders to all 5 profiles; `render-drift` green; dogfood byte-identical; existing tests pass.
- [ ] All §6 quality gates pass.
