# task-011: cwd-driven A/B/C dispatch matrix + update-self registry migration swap (bash)

**Type:** IMPLEMENT

**Source:** feature-004-two-tier-registry-and-dispatch → delivery-002

**Depends on:** task-010

**Scope:**
- `bin/aid` only — feature-004 mechanism 3 (cwd dispatch, no scan) + the `update self` migration swap. Per the "Affected components" + Dispatch matrix:
  - **B-table (`aid add`)** at the add registration site (`:2315`) — replace the unconditional `registry_register "$_AID_TARGET"` with the B-table: in-`~` → user (silent); per-user outside-`~` writable → user (silent); unwritable folder → **error + abort before any `.aid/` is created** (decisions #3); global outside-`~` writable → "add as shared?" prompt (the one real decision, #4) → shared (elevate, best-effort) on yes / user on no.
  - **C-table classifier** at the repo-command fall-through (after self/add handling, post `:2008`) — classify cwd (`has_aid`, `in_home`, `global`, `registered`, `stale`); register-on-encounter (user silent; global outside-`~` → ask shared-vs-user; best-effort); stale ⇒ warn + offer `aid update` (never auto-migrate); missing `.aid/` ⇒ print `no AID project here -- set it up? (aid add)` + optional non-git note, operate as a no-op / exit 0 (no hard refuse, #5).
  - **`update self` migration swap** at the `:2004` call site (was `_aid_scan_and_migrate`, stubbed to no-op in task-001) — **replace** with iteration over `_registry_read_union` (no scan); keep the existing All/Yes/No/Cancel consent walk (`:1828-1871`), call `_aid_migrate_repo` on Yes/All; **no** `.migrated` marker write; unregistered repos are NOT migrated here (caught lazily by the feature-003 stamp). Channel-aware self-update mechanics (PR #78) untouched.
- Self-commands (`update self`/`remove self`) bypass the cwd classifier entirely.

**Acceptance Criteria:**
- [ ] `aid add` follows the B-table: silent user-tier register in-`~`, shared-vs-user ask only on `global && !in_home && writable`, error+abort on an unwritable folder before any `.aid/` is created.
- [ ] The C-table classifier registers-on-encounter (best-effort), offers (never auto-migrates) on stale, and treats a missing `.aid/` as a non-error offer (exit 0) with a non-git note when applicable; no machine scan is performed (AC2).
- [ ] `update self` migrates exactly the `_registry_read_union` repos with the existing All/Yes/No/Cancel walk and writes no `.migrated` marker; unregistered repos are left to the lazy stamp; the channel-aware self-update step is unchanged.
- [ ] All new/edited `bin/aid` lines are ASCII-only.
- [ ] All §6 quality gates pass.
