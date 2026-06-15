# task-005: Per-repo format stamp + fail-safe migration gate (bash)

**Type:** IMPLEMENT

**Source:** feature-003-per-repo-format-stamp → delivery-001

**Depends on:** task-001

**Scope:**
- `bin/aid` only. Apply feature-003 "Affected components" rows C1, C2, C3, C4, C5, C6. Disjoint region from task-003 (constant `~:47`, synthesizers `:1276-1670`, gate wiring `:1918`/`:1978`); stage only own hunks (`git add -p`), push via explicit `HEAD:branch` refspec (shared-checkout hazard).
  - C1: `readonly AID_SUPPORTED_FORMAT=1` immediately after the `AID_HOME`/home-resolution block (after `bin/aid:47`), defined exactly once.
  - C2: era-b synthesizer `_aid_migrate_synthesize_settings_era_b` (`:1629-1670`) — emit `format_version: <sup>` as the **first** printed line (before `project:`).
  - C3: era-a repair `_aid_migrate_repair_settings_era_a` (called at `:1318`) — add a `format_version` ensure-key step: single-line replace (`_replace_line`, `:1474`) if present; else a NEW top-of-file column-0 prepend at index 0 of `_lines` (existing `_append_block`/`_insert_after` cannot place a column-0 top key).
  - C4: NEW `_aid_repo_format <repo>` (~`:1276`) — grep first `^format_version:` line, **replicate inline** the era-a closure's strip logic (prefix strip, trim, inline `# comment` strip, quote-unwrap; do NOT reuse the `_get_scalar_value` closure), validate `^[0-9]+$`; echo the integer, `0` on absent/malformed/negative.
  - C5: NEW `_aid_format_gate <repo>` — 3-way classify vs `AID_SUPPORTED_FORMAT`: `repo>sup` refuse (stderr, non-zero, no `.aid/` write); `repo<sup`/absent warn+offer `aid update` (stdout, non-blocking, return 0); `repo==sup` silent return 0. Honor `AID_NO_MIGRATE=1` to suppress the warn+offer notice only (never the refuse path).
  - C6: wire `_aid_format_gate "$target"` into the repo-command entry points, **replacing** the `_aid_check_migrate_sentinel` calls at `:1918` (`_cmd_dashboard`) and `:1978` (status), plus bare `aid` and the `update` repo path; gate runs **before** operating; on refuse, exit non-zero before any `.aid/` access.
- Gate only runs when `.aid/` exists; absent `.aid/` falls through to the existing "set it up? (`aid add`)" path.

**Acceptance Criteria:**
- [ ] `AID_SUPPORTED_FORMAT=1` is defined exactly once near the top of `bin/aid`.
- [ ] `_aid_repo_format` returns the integer stamp, collapsing absent/empty/non-integer/negative/malformed to `0` (never to a value `> sup`); duplicate lines read first-match only.
- [ ] `_aid_format_gate` refuses (non-zero, no `.aid/` write) on `format_version > 1`, warns+offers and still operates on `< 1`/absent, is silent on `== 1`; `AID_NO_MIGRATE=1` suppresses the offer but never the refuse.
- [ ] The gate replaces the sentinel calls at the dashboard/status/bare-aid/update entry points and runs before operating; era-a repair and era-b synthesizer both write `format_version: 1`.
- [ ] Stamp write rides the existing `mktemp` + `mv -f` crash-safe idiom; all new strings/messages/comments are ASCII-only.
- [ ] All §6 quality gates pass.
