# task-013: Windows parity acceptance for migration (PowerShell, Windows runner)

**Type:** TEST

**Source:** work-005-profile-generator-simplify -> delivery-002

**Depends on:** task-012

**Scope:**
- Mirror the task-012 migration fixtures + assertions in the PowerShell twin `tests/windows/Test-AidInstaller.ps1`:
  - the same old-layout fixtures — codex `.agents/` + `.codex/agents/` split, `.cursor/rules/aid-*.mdc`, `.agent/rules/aid-*.md`, plus **user content** in each tree;
  - run the PS `aid update` (via `bin/aid.ps1` / `AidInstallCore.psm1`) against each fixture;
  - assert the retired AID trees are gone, the new `.codex/{agents,skills,aid}` is present, every user file is **byte-identical**, and `tools.*.version` are **uniform**.
- This is a **separate task** because `tests/windows/Test-AidInstaller.ps1` runs **ONLY on the Windows CI runner** — it is not part of `tests/run-all.sh`, so a green Linux run cannot validate it. The PS twin must be verified on the Windows runner.
- Use `T<NN>`-style assertion IDs (matching the existing convention in `Test-AidInstaller.ps1`).
- Deterministic (use `--from-bundle` against a staged bundle; no network); ASCII-only PowerShell (Windows ANSI-codepage parse safety).
- **`$HOME` / `$env:USERPROFILE` pin + escape canary (MANDATORY):** the migration scan defaults its root to the user home, so every fixture run MUST force `$HOME` / `$env:USERPROFILE` to a throwaway dir (via the existing `Run-AidPs1Home` affordance, `Test-AidInstaller.ps1:279-283`) and assert via an **escape canary** that the real user home was never touched — same discipline as task-012.
- **Out of scope:** the bash fixtures/assertions (task-012); the engine/CLI implementation (task-009/010/011).

**Acceptance Criteria:**
- [ ] The PowerShell twin migration is verified on the **Windows CI runner** using the same old-layout fixtures as task-012.
- [ ] Post-`aid update` assertions hold in PS: retired AID trees gone, new `.codex/{agents,skills,aid}` present, every user file byte-identical, `tools.*.version` uniform.
- [ ] Assertions use `T<NN>`-style IDs consistent with `Test-AidInstaller.ps1`.
- [ ] The test script is ASCII-only PowerShell.
- [ ] TEST defaults: tests are deterministic; clean setup/teardown; all acceptance criteria from feature-003 (AC5, AC8) covered on the Windows twin.
- [ ] Every fixture run pins `$HOME` / `$env:USERPROFILE` to a throwaway dir; an escape canary asserts the real user home (`USERPROFILE`) was never touched (the migration-scan-defaults-to-home hazard — mandatory, mirrors task-012).
- [ ] All §6 quality gates pass.
