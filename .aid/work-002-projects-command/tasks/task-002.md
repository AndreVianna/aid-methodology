# task-002: Update existing tests broken by the key/comment flip

**Type:** TEST

**Source:** feature-001-projects-command → delivery-001

**Depends on:** task-001

**Scope:**
- Update the existing assertions broken by task-001 (the `projects:` key, the new 3-line header, AND the swept user-facing "repo"→"project" strings). Per SPEC §E inventory (a floor, not a ceiling):
  - `tests/canonical/test-registry.sh` — REG-U01d (`:202`, header), REG-U01f (`:205`), REG-U07c (`:249`).
  - `tests/canonical/test-aid-provisioning.sh` — PRV-P02b (`:129`), PRV-P02c (`:130-131`).
  - `tests/canonical/test-aid-cli-parity.sh` — **full PAR057 set: O07 (`:984`), O09 (`:989`), O12 (`:996`), O14 (`:1001`), O16 (`:1010`, byte-for-byte bash↔PS `registry.yml` compare), S02 (`:1442-1443`), S03 (`:1444`)**.
  - Plus any other assertion pinning a swept "repo" message string — find by grep.
  - `tests/windows/Test-AidInstaller.ps1` — has **no** registry key/header assertion (nothing to update for the flip); update a message-string assertion only if grep finds one.
- Do NOT add new behavior tests here (that is task-006). This task only realigns existing assertions.
- Re-anchor assertion IDs by name (line numbers shift). HOME-pinned where the suite fires registry/migration code.

**Acceptance Criteria:**
- [ ] The full PAR057 set (O07/O09/O12/O14/O16/S02/S03) + REG-U01d/U01f/U07c + PRV-P02b/P02c expect `projects:` / the new 3-line header / swept strings; the O16 byte-compare passes (bash and PS now emit identical `projects:` output).
- [ ] Every assertion on the CLI's *emitted/produced* registry content expects `projects:` + the new header + swept strings. **RETAIN untouched** (back-compat INPUT fixtures + API field — do NOT edit): the `test-registry.sh` legacy-input heredocs (REG-V0x, ~`:497/505/518/539/605/671/803`), the `test-dashboard-parity.sh`/`test-dashboard-parity-h.sh` legacy fixtures, and the dashboard JSON `repos` field reads. Completeness is confirmed by **inspecting** that each remaining `machine repo registry`/`repos:` hit under `tests/` is one of those retained categories — NOT by a `grep → 0` gate (which is wrong by design here).
- [ ] `test-registry.sh`, `test-aid-provisioning.sh`, `test-aid-cli-parity.sh` pass locally with HOME pinned to a throwaway.
- [ ] All §6 quality gates pass.
