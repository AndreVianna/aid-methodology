# task-006: bash — new behavior tests for `aid projects`

**Type:** TEST

**Source:** feature-001-projects-command → delivery-001

**Depends on:** task-004, task-005

**Scope:** Add new units to `tests/canonical/test-registry.sh` covering the bash command (per SPEC §E + AC1–AC7):
- `list` over a raw union renders all four states (`vX.Y.Z`, `untracked`, `no-aid`, `missing`) — including entries whose `.aid/` is absent/missing (NOT pruned).
- the ASCII `*` "you are here" marker appears on the canonical-cwd match (and on a symlinked/relative cwd that canonicalizes to a registered path); an unregistered-but-AID cwd is footnoted.
- `add` registers an existing `.aid/` project (tools untouched), rejects a non-`.aid/` path (exit 2), is idempotent.
- `remove` unregisters (tools/files untouched), repairs a stale/`missing`/`no-aid` entry, is idempotent.
- tier resolution: per-user collapse (all user), global+outside-home → shared, global+under-home → user, `--local`/`--shared` override, `--shared`-under-per-user notice, shared-write degrade.
- a legacy `repos:`-keyed registry is still read correctly (key-agnostic reader).
- **FR7/AC6 reconcile behavior (task-005):** `aid add <tool>` and cwd auto-registration on a global, outside-`$HOME` target register **without any interactive prompt** (neither "Register this…" nor "Add this…"); `aid dashboard` auto-register and the migrate side-effect **never prompt/elevate** (degrade silently to user tier when a shared write needs elevation); tier is consistent across add/dashboard/migrate.
- **Isolation:** `export HOME=<throwaway>` for every test that fires registry/migration code, plus an escape canary asserting the developer's real registry/repos are untouched.

**Acceptance Criteria:**
- [ ] New units cover AC1–AC7 behaviors above; each asserts observable CLI output/exit code.
- [ ] A unit asserts the FR7/AC6 reconcile: `aid add`/cwd auto-register on a global outside-`$HOME` target shows NO prompt; dashboard/migrate never-elevate; tier consistent across sites.
- [ ] All registry/migration-firing tests pin `HOME` to a throwaway and include an escape canary.
- [ ] `tests/canonical/test-registry.sh` passes locally (HOME-pinned).
- [ ] All §6 quality gates pass.
