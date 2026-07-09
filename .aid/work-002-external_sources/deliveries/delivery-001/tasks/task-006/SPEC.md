# task-006: connector-secret twin with no-echo write and path-confined purge

**Type:** IMPLEMENT

**Source:** work-002-external_sources -> delivery-001

**Depends on:** -- (none)

**Scope:**
- New feature-003-owned twin `connector-secret.{sh,ps1}` under `canonical/aid/scripts/connectors/` exposing `write` and `purge` ops — the single home for all `.aid/connectors/.secrets/` I/O.
- `write`: no-echo capture (`read -rs` / `Read-Host -AsSecureString` with in-process BSTR marshal via `SecureStringToBSTR`/`PtrToStringBSTR`, zeroed with `ZeroFreeBSTR` after write — `ConvertFrom-SecureString -AsPlainText` is BANNED under WinPS 5.1); exact-bytes owner-only write (`( umask 077; printf '%s' > "$file" )` / `[System.IO.File]::WriteAllText` no-BOM, no trailing newline); prints only the `file:` reference to stdout.
- `purge`: idempotent delete of `.aid/connectors/.secrets/<stem>` (missing = clean no-op success), silent on the value.
- Both ops: path-confinement (stem is a filename only; reject any `/`, `\`, or `..` with non-zero exit BEFORE any read/write/delete) + fail-closed ignore precondition (assert `.aid/connectors/.gitignore` ignores `.secrets/` before the first byte is written).
- Documented exit codes in the header (reuse the shared scheme; add codes for the ignore-precondition and path-confinement rejection).

**Acceptance Criteria:**
- [ ] `write` stores the exact secret bytes only under `.aid/connectors/.secrets/<stem>`, prints only the `file:` reference, and never echoes/persists the value (no `set -x`; never passed as a process arg; in-memory var cleared immediately after write)
- [ ] `purge` deletes the value file if present and is a clean no-op if absent (idempotent), silent on contents
- [ ] Both ops reject a stem containing a path separator or `..` with a non-zero exit + stderr diagnostic, before any I/O
- [ ] `write` refuses (non-zero) when the committed `.aid/connectors/.gitignore` does not ignore `.secrets/` (fail-closed)
- [ ] Shipped PowerShell is WinPS-5.1-compatible + ASCII-only; cross-platform (Win/mac/Linux) with no new heavy runtime dependency (AC-8)
- [ ] Unit tests cover write + purge + confinement + fail-closed; all existing tests still pass; build passes
- [ ] All §6 quality gates pass
