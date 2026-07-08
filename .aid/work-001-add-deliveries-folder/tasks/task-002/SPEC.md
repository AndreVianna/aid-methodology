# task-002: Update dashboard reader twins for both delivery-folder layouts

**Type:** REFACTOR

**Source:** work-001-add-deliveries-folder → delivery-001

**Depends on:** — (none)

**Scope:**
- Python `dashboard/reader/*` (reader.py hierarchy enumeration/locator ~L800–1090;
  parsers/models/derivation as needed) and Node `dashboard/server/reader.mjs` (enumeration
  ~L2510–3096) detect **both** enumeration shapes:
  - **Lite-flat:** tasks directly under `work-NNN/tasks/task-NNN/` (no delivery folder); the
    single delivery gate/Q&A read from the **work-root `STATE.md`**.
  - **Full-nested:** `work-NNN/deliveries/delivery-NNN/tasks/task-NNN/`.
- Both twins change **in lockstep** and stay **byte-parity** (identical detection rule, warnings,
  and serialized output).
- Leave the `delivery-NNN-issues.md` read path **unchanged** (work-root sibling file).
- Do **not** support the old flat `delivery-NNN/`-at-work-root layout (clean cutover).
- Grep-clean the dashboard side.

**Acceptance Criteria:**
- [ ] Both reader twins detect the lite-flat layout (`work-NNN/tasks/…`, gate/Q&A from work-root STATE.md) and the full-nested layout (`work-NNN/deliveries/delivery-NNN/…`), and stay byte-parity. *(SPEC AC 6)*
- [ ] The `delivery-NNN-issues.md` read path is unchanged (still resolved as a work-root sibling file). *(SPEC AC 2, 6)*
- [ ] Old flat `delivery-NNN/`-at-work-root layout is not supported (clean cutover). *(SPEC AC 8)*
- [ ] Grep-clean (dashboard side): no lingering old flat `work-NNN/delivery-NNN/` references. *(SPEC AC 10)*
- [ ] All project quality gates pass.
