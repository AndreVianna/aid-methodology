# task-040: Repoint the dashboard reader twins to deliveries/{BLUEPRINT,DETAIL} (Py + Node lockstep)

**Type:** IMPLEMENT

**Source:** work-001-lite-aid-skills -> delivery-001

**Depends on:** task-036

**Scope:**
- Edit `dashboard/reader/reader.py` and `dashboard/server/reader.mjs` in **lockstep** so the full (hierarchical) layout is detected and read under the new `deliveries/` parent:
  - Hierarchy detector (`_detect_hierarchy` / `_detectHierarchy`): key on `deliveries/delivery-NNN/tasks/task-NNN/STATE.md` (add the `deliveries/` parent to the "Pillar 6" probe).
  - Directory enumeration (`_RE_DELIVERY_DIR` / `_RE_TASK_DIR` in reader.py; the inline dir walk in reader.mjs): enumerate `deliveries/delivery-NNN/` (the `delivery-NNN` name pattern is unchanged; only the parent dir is added).
  - Hierarchical read (`_read_work_hierarchical` / `_readWorkHierarchical`): read the delivery title / task listing from `deliveries/delivery-NNN/BLUEPRINT.md` and the task short-name / type from `deliveries/delivery-NNN/tasks/task-NNN/DETAIL.md`.
  - Extractors: task short-name / type (`_parse_task_spec_short_name` / `_parseTaskSpecShortName` + the task-type extractor) read from `DETAIL.md`; the delivery-title extractor reads from `BLUEPRINT.md`; the mjs `taskSpecPath = join(taskDir, "SPEC.md")` -> `join(taskDir, "DETAIL.md")`; the drilldown (`read_repo_detail` / its mjs equivalent) delivery/task paths move under `deliveries/…` and the delivery-def read -> `BLUEPRINT.md`.
- Leave the work-root `SPEC.md` identity-field fallback UNCHANGED (`reader.py` `spec_path = work_dir / "SPEC.md"`, PF-8; `reader.mjs` `const specPath = join(workDir, "SPEC.md")`) — that is the **feature/lite work-root** spec.
- A-10 clean switch: neither twin retains a `delivery-NNN/SPEC.md` (old-nested) code path.

**Acceptance Criteria:**
- [ ] Both twins detect the full layout via `deliveries/delivery-NNN/tasks/task-NNN/STATE.md`, enumerate `deliveries/delivery-NNN/`, read the delivery title from `BLUEPRINT.md`, and read the task short-name/type from `DETAIL.md` (AC-16 / FR-16).
- [ ] The mjs task-file join is `join(taskDir, "DETAIL.md")`; the drilldown reads delivery defs from `BLUEPRINT.md` under `deliveries/…`.
- [ ] Reader parity holds: a hierarchical fixture on the new paths is read identically by `reader.py` and `reader.mjs` (parity test green).
- [ ] The work-root `SPEC.md` identity fallback is unchanged (feature/lite work-root spec).
- [ ] Neither twin retains a `delivery-NNN/SPEC.md` old-nested code path (grep; A-10).
- [ ] All existing tests still pass (`tests/run-all.sh` green), including the reader unit + parity tests.
- [ ] All §6 quality gates pass.
