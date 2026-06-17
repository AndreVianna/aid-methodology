# task-004: bash `aid projects` command (list/add/remove/help) + dispatch + usage

**Type:** IMPLEMENT

**Source:** feature-001-projects-command → delivery-001

**Depends on:** task-003

**Scope:** Add the `projects` command to `bin/aid` (per SPEC §Feature Flow + §Layers A):
- **Dispatch block** for `SUBCMD == projects`, inserted after the `dashboard` case (`~2408`) and before the final unknown-command reject (`~2433`); parse sub-action (`list` default / `add` / `remove` / `help`), optional `[path]`, and `--local`/`--shared`/`--verbose`.
- **`_cmd_projects`**:
  - `list` (default): `_registry_read_raw_union` → per entry render marker · path · `_aid_project_state` · tools (from manifest) · tier; mark the canonical-cwd match with an ASCII `*` (NFR3 — no non-ASCII glyph); footnote when cwd is an AID project not in the registry.
  - `add [path=cwd]`: canonicalize (`cd && pwd`); require `<path>/.aid` (else clear error, exit 2); `registry_register` with `_aid_resolve_tier` result; report the tier actually written.
  - `remove [path=cwd]`: canonicalize; `registry_unregister` (no `.aid/` requirement — repairs stale); idempotent no-op message when absent.
  - `help` / `-h`: usage.
- **`_aid_usage`** (`~91-158`): add `projects` to the default block (`~140-156`) and a per-command case (`~94-139`); update the file header comment (`~12-18`).
- ASCII-only; re-anchor by symbol name.

**Acceptance Criteria:**
- [ ] `aid projects` / `aid projects list` renders the raw union with state, tools, tier columns and an ASCII `*` cwd marker; an unregistered AID cwd is footnoted.
- [ ] `aid projects add` registers an existing `.aid/` project (tools untouched), rejects a non-`.aid/` path with exit 2, is idempotent, and prints the tier written.
- [ ] `aid projects remove` unregisters (tools/files untouched), works on stale/`missing`/`no-aid` entries, is idempotent.
- [ ] `aid projects -h` / `aid projects help` and the top-level `aid --help` list/describe `projects`.
- [ ] No non-ASCII bytes; `bin/aid` parses/runs.
- [ ] All §6 quality gates pass.
