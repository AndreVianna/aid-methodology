# task-008: Add a top-level `--version` flag to the aid CLI

**Type:** IMPLEMENT

**Source:** work-003-state-schema -> delivery-001

**Depends on:** -- (none)

**Scope:**
- The CLI has an `aid version` subcommand (prints the CLI version via a VERSION-file read —
  `bin/aid:2710-2718`, `bin/aid.ps1:2115-2119`) but no top-level `--version` flag:
  `aid --version` errors `unknown command: --version`. Add a **top-level, bare** `--version`
  (and `-V`) that prints the same version output and exits 0.
- **Avoid the pre-existing collision.** `--version <v>` already exists as a **value-taking** flag
  on the `add` / `remove` / `update` subcommands (`bin/aid:2944`, `bin/aid.ps1:2859`) to PIN a
  release. The new flag is distinct: a BARE, top-level flag (takes no value), handled BEFORE
  subcommand dispatch. It must not change, shadow, or break the subcommand `--version <v>` pin.
- Print via the **same VERSION-file read path** `aid version` uses — NOT `resolve_version()`
  (that is the release-pin resolver, a different concern). Single-source the version string.
- Apply to BOTH launcher twins (`bin/aid` bash + `bin/aid.ps1` PowerShell), identical behavior.
  Update `aid -h` to list the top-level `--version` flag, **distinguishing it from** the
  subcommand `--version <v>` pin flag so the help is unambiguous.

**Acceptance Criteria:**
- [ ] Top-level `aid --version` (and `-V`) prints the CLI version (v2.1.0) via the VERSION-file path and exits 0 — verified on both `bin/aid` and `bin/aid.ps1` (traces to BLUEPRINT gate criteria #12).
- [ ] The existing `add`/`remove`/`update` `--version <v>` value-flag (release pin) is unchanged — verified by a regression check on both twins (traces to BLUEPRINT gate criteria #12).
- [ ] The version string is single-sourced (VERSION-file read), not duplicated and not via `resolve_version()`.
- [ ] `aid -h` documents the top-level `--version` flag distinctly from the subcommand `--version <v>` pin flag (no ambiguity).
- [ ] All applicable quality gates pass (per `.aid/settings.yml`).
