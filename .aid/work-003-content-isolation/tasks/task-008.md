# task-008: Root-agent in-place region update + migration, no .aid-new (PowerShell) — parity

**Type:** IMPLEMENT

**Source:** work-003-content-isolation → delivery-001

**Depends on:** task-007

**Scope:**
- Mirror the bash root-agent rewrite (task-007) in `Copy-RootAgentFile` within `lib/AidInstallCore.psm1`: in-place `<!-- AID:BEGIN -->`..`<!-- AID:END -->` region update, eliminate the `.aid-new` fallback entirely, and implement both migration branches with semantics equivalent to bash.
- Algorithm + migration identical to task-007 (dst absent → full source; markers → region replace; marker-less → sha-match clean rewrite or excise-and-rewrap in place; never a backup file).
- Heading match for the excise is by normalized STEM, identical to task-007: match `## Review output format (global)` via the heading stem, tolerating a trailing parenthetical suffix (e.g. ` (global)`) — NOT an exact `## Review output format` string match. Keep the PS rule byte-for-byte equivalent to bash so migration is deterministic across both.
- Keep `bin/aid.ps1` ASCII-only.

**Acceptance Criteria:**
- [ ] The PS region-update and both migration branches produce the same result as bash (task-007) for: markers-present, marker-less-sha-match, marker-less-sha-mismatch, and dst-absent cases. The marker-less-sha-mismatch excise matches `## Review output format (global)` via stem/prefix matching (NOT exact `## Review output format`), equivalent to bash.
- [ ] No `.aid-new` (or any sidecar/backup) is ever written by the PS path, including the prior non-`-Force` divergence path.
- [ ] User content outside the markers is preserved byte-for-byte; `## Project`/`## Project Overview` preserved in the excise-and-rewrap branch.
- [ ] `bin/aid.ps1` and `lib/AidInstallCore.psm1` remain ASCII-only.
- [ ] All §6 quality gates pass.
