# task-005: PowerShell install core + `install.ps1` bootstrap

**Type:** IMPLEMENT

**Source:** feature-001-shared-install-core-and-bootstrap → delivery-001

**Depends on:** task-001

**Scope:**
- Author `lib/AidInstallCore.psm1` (module exporting the same operation set) and `install.ps1` (PowerShell 5.1+ bootstrap) per feature-001 §Component-layout, behaviorally identical to the Bash side.
- Implement the PowerShell parameter surface: `-Tool`, `-Version`, `-FromBundle`, `-Force`, `-Update`, `-Uninstall`, `-TargetDirectory`, `-Help`; accept canonical tool ids and PascalCase aliases (normalize to canonical id).
- Implement detection, fetch (`Invoke-WebRequest`/`Invoke-RestMethod` + `tar.exe` with `Expand-Archive` fallback into a temp dir, removed in `try/finally`), `SHA256SUMS` verify, copy semantics, FR11 protect-on-diff, manifest read/write (`ConvertFrom-Json`/byte-identical JSON output), and uninstall — all mirroring task-003.
- Enforce cross-platform parity: identical user-visible message strings, identical exit codes, byte-identical manifest JSON (same key order, 2-space indent, `\n` newlines), identical installed-file sha256; SHA256 hashing everywhere (no MD5); no WSL requirement; `Join-Path` for all path joins.

**Acceptance Criteria:**
- [ ] `install.ps1` runs in native PowerShell 5.1+ (and `pwsh` on Linux) with no WSL; fresh install per tool lands the same trees + root agent file as the Bash path.
- [ ] Message strings (`Copied:`/`Up to date:`/`Updated:`/`Skipped (differs; use --force):`, the FR11 warning, the ambiguity error), exit codes (0–6), and manifest JSON are byte-identical to the Bash core for the same inputs.
- [ ] **Protect-on-diff default:** a pre-existing root agent file is not overwritten without `-Force` — warning + `*.aid-new` + exit 5 (SPEC-flagged default); the manifest is written to `<target>/.aid/.aid-manifest.json` (SPEC-flagged default).
- [ ] The bootstrap consumes the **default tar.gz** artifact (using `tar.exe`, with `Expand-Archive` only as the documented fallback — no `.zip` artifact is required of feature-002 in this task).
- [ ] All §6 quality gates pass.
