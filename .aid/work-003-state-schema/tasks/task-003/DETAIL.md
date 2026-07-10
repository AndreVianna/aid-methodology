# task-003: Ship the new reader to the installed CLI (vendor + resync + pipx)

**Type:** CONFIGURE

**Source:** work-003-state-schema -> delivery-001

**Depends on:** task-002

**Scope:**
- Re-vendor the updated dual-format reader (from task-002) into the two package trees:
  `packages/pypi/aid_installer/_vendor/dashboard/` (via `packages/pypi/scripts/vendor.py`)
  and the npm package (via `packages/npm/scripts/vendor.js`).
- Resync the dogfood `.claude/` if the reader is mirrored there; confirm dogfood
  byte-identity holds.
- Rebuild + `pipx install --force` the CLI, and verify the installed `aid` dashboard reads
  a new-format STATE file correctly (frontmatter path exercised end-to-end through the
  installed binary, before any on-disk STATE file is migrated).
- This task exists so the shipped reader is live **before** writers emit (task-004) or files
  migrate (task-005) — the ship-before-migrate sequencing constraint.

**Acceptance Criteria:**
- [ ] Reader re-vendored into `packages/pypi` + `packages/npm`; the vendored copies match the `dashboard/` source (traces to BLUEPRINT gate criteria #8).
- [ ] Dogfood byte-identity holds after resync (traces to BLUEPRINT gate criteria #8).
- [ ] `pipx install --force` completed and the installed dashboard reads a new-format STATE file correctly (frontmatter honored) (traces to BLUEPRINT gate criteria #2, #8).
- [ ] All applicable quality gates pass (per `.aid/settings.yml`).
